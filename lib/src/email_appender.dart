import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:any_logger/any_logger.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

/// Appender that sends log records via email using SMTP.
///
/// Key behavior:
/// - Does NOT create new files on rotation like FileAppender
/// - Sends emails based on rotation cycle timing
/// - Ignores batch size for sending (only used for buffer management)
/// - Continues writing to the same file after sending
class EmailAppender extends FileAppender {
  static const String appenderName = 'EMAIL';

  // Add restart behavior configuration
  bool deleteLogOnRestart = false; // Default: keep logs across restarts

  // SMTP Configuration
  late String smtpHost;
  late int smtpPort;
  String? username;
  String? password;
  bool ssl = false;
  bool allowInsecure = false;
  bool ignoreBadCertificate = false;

  // Email settings
  late String fromEmail;
  String? fromName;
  late List<String> toEmails;
  List<String> ccEmails = [];
  List<String> bccEmails = [];
  String? replyTo;
  String subjectPrefix = '[LOG]';
  bool includeHostnameOrDeviceId = true;
  bool includeAppInfo = true;
  String? attachmentFilePattern; // Custom pattern for attachment names
  bool useLocalTimeInSubject = true; // Use local time instead of UTC

  // Email formatting
  bool sendAsHtml = true;
  bool attachLogFile = true;
  int maxInlineLines = 1000;
  bool includeStackTrace = true;
  bool includeMetadata = true;
  String? emailTemplate;
  bool groupByLevel = false;

  // Legacy batch settings (kept for compatibility but not used for sending)
  Duration batchInterval = Duration(minutes: 5); // Ignored for sending
  bool sendImmediatelyOnError = true;
  int immediateErrorThreshold = 10;

  // Email size limits
  int maxEmailSizeBytes = 100 * 1024; // 8 * 1024 * 1024; // 8MB default

  // Buffer management
  final List<LogRecord> _errorBuffer = [];
  final List<LogRecord> _pendingBuffer = [];
  bool _isSwapping = false;

  // Rate limiting
  int maxEmailsPerHour = 20;
  final List<DateTime> _sentTimestamps = [];
  Duration rateLimitWindow = Duration(hours: 1);

  // Statistics
  int _successfulSends = 0;
  int _failedSends = 0;
  DateTime? _lastSendTime;
  DateTime? _lastRotationCheck;

  // SMTP Server
  SmtpServer? _smtpServer;

  // Test mode
  bool test = false;

  EmailAppender() : super() {
    path = 'email_logs/';
  }

  static Future<EmailAppender> fromConfig(
    Map<String, dynamic> config, {
    bool test = false,
    DateTime? date,
  }) async {
    final appender = EmailAppender()
      ..test = test
      ..created = date ?? DateTime.now();

    appender.initializeCommonProperties(config, test: test, date: date);

    // File settings
    appender.filePattern = config['filePattern'] ?? 'email_log';
    appender.fileExtension = config['fileExtension'] ?? 'log';
    appender.path = config['path'] ?? 'email_logs/';
    appender.attachmentFilePattern = config['attachmentFilePattern'] ??
        config['filePattern'] ??
        'log_attachment';
    appender.useLocalTimeInSubject = config['useLocalTimeInSubject'] ?? true;

    print('config ');
    print(config);

    // Handle rotation cycle configuration
    if (config.containsKey('rotationCycle')) {
      final rotationValue = config['rotationCycle'];
      if (rotationValue is String) {
        appender.rotationCycle = RotationCycle.fromString(rotationValue);
      } else if (rotationValue is RotationCycle) {
        appender.rotationCycle = rotationValue;
      } else {
        appender.rotationCycle =
            RotationCycle.fromString(rotationValue.toString());
      }
    } else {
      appender.rotationCycle = RotationCycle.HOURLY;
    }

    // Required SMTP fields
    if (!config.containsKey('smtpHost')) {
      throw ArgumentError('Missing smtpHost for EmailAppender');
    }
    appender.smtpHost = config['smtpHost'];

    if (!config.containsKey('smtpPort')) {
      throw ArgumentError('Missing smtpPort for EmailAppender');
    }
    appender.smtpPort = config['smtpPort'];

    // Required email fields
    if (!config.containsKey('fromEmail')) {
      throw ArgumentError('Missing fromEmail for EmailAppender');
    }
    appender.fromEmail = config['fromEmail'];

    if (!config.containsKey('toEmails')) {
      throw ArgumentError('Missing toEmails for EmailAppender');
    }

    // Handle toEmails configuration
    final toEmailsConfig = config['toEmails'];
    if (toEmailsConfig is String) {
      // Check if it's a JSON string
      appender.toEmails =
          toEmailsConfig.split(',').map((e) => e.trim()).toList();
    } else if (toEmailsConfig is List) {
      appender.toEmails = List<String>.from(toEmailsConfig);
    } else {
      throw ArgumentError('toEmails must be a String or List<String>');
    }

    // Optional SMTP settings
    appender.username = config['username'];
    appender.password =
        config['password'] ?? config['appPassword'] ?? config['app_password'];
    appender.ssl = config['ssl'] ?? false;
    appender.allowInsecure = config['allowInsecure'] ?? false;
    appender.ignoreBadCertificate = config['ignoreBadCertificate'] ?? false;

    // Optional email settings
    appender.fromName = config['fromName'];

    if (config.containsKey('ccEmails')) {
      final cc = config['ccEmails'];
      if (cc is String) {
        appender.ccEmails = cc.split(',').map((e) => e.trim()).toList();
      } else if (cc is List) {
        appender.ccEmails = List<String>.from(cc);
      }
    }

    if (config.containsKey('bccEmails')) {
      final bcc = config['bccEmails'];
      if (bcc is String) {
        appender.bccEmails = bcc.split(',').map((e) => e.trim()).toList();
      } else if (bcc is List) {
        appender.bccEmails = List<String>.from(bcc);
      }
    }

    appender.replyTo = config['replyTo'];
    appender.subjectPrefix = config['subjectPrefix'] ?? '[LOG]';
    appender.includeHostnameOrDeviceId = config['includeHostname'] ?? true;
    appender.includeAppInfo = config['includeAppInfo'] ?? true;

    // Email size settings
    if (config.containsKey('maxEmailSizeMB')) {
      appender.maxEmailSizeBytes =
          (config['maxEmailSizeMB'] as num).toInt() * 1024 * 1024;
    } else if (config.containsKey('maxEmailSizeBytes')) {
      appender.maxEmailSizeBytes = config['maxEmailSizeBytes'];
    }

    // Formatting options
    appender.sendAsHtml = config['sendAsHtml'] ?? true;
    appender.attachLogFile = config['attachLogFile'] ?? true;
    appender.maxInlineLines = config['maxInlineLines'] ?? 1000;
    appender.groupByLevel = config['groupByLevel'] ?? false;
    appender.includeStackTrace = config['includeStackTrace'] ?? true;
    appender.includeMetadata = config['includeMetadata'] ?? true;
    appender.emailTemplate = config['emailTemplate'];

    // Rate limiting
    appender.maxEmailsPerHour = config['maxEmailsPerHour'] ?? 20;

    // Restart behavior
    appender.deleteLogOnRestart = config['deleteLogOnRestart'] ?? false;

    // Priority settings
    if (config.containsKey('sendImmediatelyOnError')) {
      appender.sendImmediatelyOnError = config['sendImmediatelyOnError'];
    }
    if (config.containsKey('immediateErrorThreshold')) {
      appender.immediateErrorThreshold = config['immediateErrorThreshold'];
    }

    // Resolve base path for Flutter if needed
    if (FileAppender.getAppDocumentsDirectoryFnc != null) {
      final dir = await FileAppender.getAppDocumentsDirectoryFnc!();
      appender.resolvedBasePath = dir.path;

      if (appender.path.startsWith('/')) {
        appender.path = appender.path.substring(1);
      }

      Logger.getSelfLogger()?.logDebug(
          'EmailAppender using Flutter path: ${appender.resolvedBasePath}/${appender.path}');
    }

    // Ensure directory exists
    appender.ensurePathExists();

    if (appender.deleteLogOnRestart && appender.file.existsSync()) {
      try {
        final fileSize = appender.file.lengthSync();
        if (fileSize > 0) {
          Logger.getSelfLogger()?.logInfo(
              'Deleting existing log file on restart (${fileSize} bytes): ${appender.file.path}');
          appender.file.writeAsStringSync(''); // Clear the file
          Logger.getSelfLogger()?.logInfo('Log file cleared on restart');
        }
      } catch (e) {
        Logger.getSelfLogger()
            ?.logWarn('Failed to clear log file on restart: $e');
      }
    }

    // Initialize last rotation check
    appender._lastRotationCheck = DateTime.now();

    // Setup SMTP
    if (!test) {
      appender._setupSmtpServer();
    }

    Logger.getSelfLogger()
        ?.logInfo('EmailAppender initialized: ${appender.toString()}');

    return appender;
  }

  factory EmailAppender.fromConfigSync(Map<String, dynamic> config) {
    throw UnsupportedError(
        'EmailAppender requires async initialization. Use fromConfig() or builder().build()');
  }

  void _setupSmtpServer() {
    if (username != null && password != null) {
      _smtpServer = SmtpServer(
        smtpHost,
        port: smtpPort,
        username: username,
        password: password,
        ssl: ssl,
        allowInsecure: allowInsecure,
        ignoreBadCertificate: ignoreBadCertificate,
      );
    } else {
      _smtpServer = SmtpServer(
        smtpHost,
        port: smtpPort,
        ssl: ssl,
        allowInsecure: allowInsecure,
        ignoreBadCertificate: ignoreBadCertificate,
      );
    }
  }

  @override
  void append(LogRecord logRecord) {
    if (!enabled) return;

    // If we're swapping, buffer the log for the NEXT email
    if (_isSwapping) {
      _pendingBuffer.add(logRecord);
      return; // Don't write to file during swap
    }

    // Write to file normally
    super.append(logRecord);

    // Track errors for immediate sending
    if (logRecord.level.index >= Level.ERROR.index) {
      _errorBuffer.add(logRecord);
    }

    // Check for immediate send on critical errors
    if (sendImmediatelyOnError &&
        _errorBuffer.length >= immediateErrorThreshold) {
      Logger.getSelfLogger()?.logInfo(
          'Immediate error threshold reached (${_errorBuffer.length} errors). Sending email.');
      _triggerAsyncSend();
      return;
    }

    // Check if rotation period has passed
    if (_shouldSendEmail()) {
      Logger.getSelfLogger()?.logInfo(
          'Rotation boundary reached (${rotationCycle.name}). Triggering email send.');
      _triggerAsyncSend();
    }
  }

  // New helper method to trigger async send
  void _triggerAsyncSend() {
    // Use scheduleMicrotask to ensure it runs soon but doesn't block
    scheduleMicrotask(() async {
      try {
        await _performSwapAndSend();
        _lastRotationCheck = DateTime.now();
        _errorBuffer.clear();
      } catch (e) {
        Logger.getSelfLogger()?.logError('Failed to send email: $e');
      }
    });
  }

  /// Performs atomic swap and send operation
  Future<void> _performSwapAndSend() async {
    if (_isSwapping) {
      Logger.getSelfLogger()
          ?.logDebug('Already swapping, skipping duplicate send');
      return;
    }

    _isSwapping = true;

    try {
      // Step 1: Check if current file has content
      if (!file.existsSync() || file.lengthSync() == 0) {
        Logger.getSelfLogger()
            ?.logDebug('Log file empty or doesn\'t exist, skipping send');
        return;
      }

      // Step 2: Create swap filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final swapFilePath = '${getFullFilename()}.swap.$timestamp';

      // Step 3: ATOMIC SWAP - rename current file to swap file
      // This is instant and captures everything written up to this moment
      await file.rename(swapFilePath);

      Logger.getSelfLogger()?.logDebug('Swapped log file to: $swapFilePath');

      // Step 4: Immediately create new empty file for future logs
      ensurePathExists(); // This recreates the file at the original path

      // Step 5: Process any buffered logs into the NEW file
      for (var record in _pendingBuffer) {
        super.append(record); // Goes to the new file
      }
      _pendingBuffer.clear();

      // Step 6: Send email from the swapped file
      final swapFile = File(swapFilePath);
      try {
        await _sendSwapFile(swapFile);
        Logger.getSelfLogger()
            ?.logInfo('Successfully sent email from swap file: $swapFilePath');
      } catch (e) {
        Logger.getSelfLogger()
            ?.logError('Failed to send email from swap file: $e');
        // Keep swap file for manual recovery if send failed
        rethrow;
      }
    } catch (e) {
      Logger.getSelfLogger()?.logError('Error during swap and send: $e');
      _failedSends++;
    } finally {
      _isSwapping = false;
    }
  }

  /// Sends email from swap file and handles multi-part if needed
  Future<void> _sendSwapFile(File swapFile) async {
    try {
      // Check file size
      final fileSize = await swapFile.length();

      if (fileSize <= maxEmailSizeBytes) {
        // Single email
        await _sendSingleEmail(swapFile, 1, 1);
      } else {
        // Multi-part email
        await _sendMultipleEmail(swapFile);
      }

      // Delete swap file after successful send
      try {
        await swapFile.delete();
        Logger.getSelfLogger()?.logDebug('Deleted swap file: ${swapFile.path}');
      } catch (e) {
        Logger.getSelfLogger()?.logWarn('Could not delete swap file: $e');
      }
    } catch (e) {
      Logger.getSelfLogger()?.logError('Failed to send from swap file: $e');
      // Keep swap file for manual recovery if send fails
    }
  }

  /// Sends a single email (possibly part of a multi-part series)
  Future<void> _sendSingleEmail(
      File logFile, int partNumber, int totalParts) async {
    if (test) {
      Logger.getSelfLogger()?.logDebug(
          'Test mode: Would send email part $partNumber/$totalParts to ${toEmails.join(", ")}');
      _successfulSends++;
      _lastSendTime = DateTime.now();
      return;
    }

    try {
      final message =
          await _createEmailMessage(logFile, partNumber, totalParts);

      await send(message, _smtpServer!);

      _successfulSends++;
      _sentTimestamps.add(DateTime.now());
      _lastSendTime = DateTime.now();

      Logger.getSelfLogger()?.logInfo(
          'Sent email part $partNumber/$totalParts from ${logFile.path}');
    } catch (e) {
      _failedSends++;
      Logger.getSelfLogger()
          ?.logError('Failed to send email part $partNumber/$totalParts: $e');
    }
  }

  /// Sends multiple emails for large log files
  Future<void> _sendMultipleEmail(File logFile) async {
    final fileContent = await logFile.readAsString();
    final allLines = fileContent.split('\n');
    final fileSize = await logFile.length();

    // Calculate number of parts based on byte size
    final totalParts = (fileSize / maxEmailSizeBytes).ceil();
    final linesPerPart = (allLines.length / totalParts).ceil();

    Logger.getSelfLogger()?.logInfo(
        'Splitting ${fileSize} bytes (${allLines.length} lines) into $totalParts parts '
        '(~${linesPerPart} lines each, targeting ${maxEmailSizeBytes} bytes per email)');

    for (int part = 0; part < totalParts; part++) {
      final startLine = part * linesPerPart;
      final endLine = min((part + 1) * linesPerPart, allLines.length);
      final partLines = allLines.sublist(startLine, endLine);

      // Filter out any empty or incomplete lines at the end
      final cleanLines = <String>[];
      for (var line in partLines) {
        // Only add complete lines (not truncated)
        if (line.isNotEmpty) {
          cleanLines.add(line);
        }
      }

      // Create temporary file for this part
      final partFile = File('${logFile.path}.part${part + 1}');
      await partFile.writeAsString(cleanLines.join('\n'));

      try {
        // Send email with this part's content
        await _sendSingleEmail(partFile, part + 1, totalParts);

        // Small delay between parts to avoid overwhelming SMTP server
        if (part < totalParts - 1) {
          await Future.delayed(Duration(seconds: 2));
        }
      } finally {
        // Clean up part file
        try {
          await partFile.delete();
        } catch (e) {
          Logger.getSelfLogger()?.logWarn('Could not delete part file: $e');
        }
      }
    }
  }

  /// Creates email message with part information
  Future<Message> _createEmailMessage(
      File logFile, int partNumber, int totalParts) async {
    // This file is now either:
    // - The full swap file (if single email)
    // - A part file (if multiple emails)

    final partInfo = totalParts > 1 ? ' (Part $partNumber of $totalParts)' : '';
    final subject = _generateSubject(logFile) + partInfo;

    final message = Message()
      ..from =
          fromName != null ? Address(fromEmail, fromName) : Address(fromEmail)
      ..recipients.addAll(toEmails.map((e) => Address(e)))
      ..subject = subject;

    if (ccEmails.isNotEmpty) {
      message.ccRecipients.addAll(ccEmails.map((e) => Address(e)));
    }

    if (bccEmails.isNotEmpty) {
      message.bccRecipients.addAll(bccEmails.map((e) => Address(e)));
    }

    if (replyTo != null) {
      message.headers['Reply-To'] = replyTo!;
    }

    // Read THIS PART's content
    final logContent = await logFile.readAsString();
    final allLines = logContent.split('\n');

    // Get non-empty lines for display and counting
    final nonEmptyLines = <String>[];
    for (final line in allLines) {
      if (line.trim().isNotEmpty) {
        nonEmptyLines.add(line);
      }
    }

    final totalLineCount = nonEmptyLines.length;
    final fileSize = await logFile.length();

    Logger.getSelfLogger()?.logDebug(
        'Processing ${totalParts > 1 ? "part $partNumber" : "full file"} for email: '
        'lines=$totalLineCount, size=$fileSize bytes, maxInlineLines=$maxInlineLines');

    // Get last maxInlineLines from THIS PART'S content
    final linesToShowInline = totalLineCount > maxInlineLines
        ? nonEmptyLines.sublist(
            totalLineCount - maxInlineLines) // Last N lines of this part
        : nonEmptyLines; // All lines if fewer than max

    // Analyze log levels from THIS PART
    final stats = _analyzeLogContent(nonEmptyLines);

    // Attach THIS PART's file
    if (attachLogFile) {
      final pattern = attachmentFilePattern ?? filePattern ?? 'logs';
      final now = DateTime.now();
      final roundedTime = _roundToRotationBoundary(now);
      final timestamp = _formatDateForFilename(roundedTime);
      String identifier = _getHostnameOrDeviceId();

      final attachmentName = totalParts > 1
          ? '${pattern}_${identifier}_${timestamp}_part${partNumber}_of_$totalParts.$fileExtension'
          : '${pattern}_${identifier}_$timestamp.$fileExtension';

      final attachment = FileAttachment(
        logFile, // This is either the full file or a part
        fileName: attachmentName,
      );

      message.attachments.add(attachment);

      Logger.getSelfLogger()?.logInfo(
          'Attached ${totalParts > 1 ? "part $partNumber/$totalParts" : "full file"}: '
          '$attachmentName with $totalLineCount lines, $fileSize bytes');
    }

    // Generate HTML/Text with THIS PART's content
    message.html = _generateHtmlBodyWithAttachment(
        linesToShowInline, // Last N lines from THIS PART
        totalLineCount, // Total lines in THIS PART
        fileSize, // Size of THIS PART
        stats, // Stats from THIS PART
        partNumber,
        totalParts);

    message.text = _generateTextBodyWithAttachment(
        linesToShowInline, // Last N lines from THIS PART
        totalLineCount, // Total lines in THIS PART
        fileSize, // Size of THIS PART
        stats, // Stats from THIS PART
        partNumber,
        totalParts);

    return message;
  }

  String _generateHtmlBodyWithAttachment(
      List<String> linesToShow,
      int totalLineCount,
      int fileSize,
      Map<String, dynamic> stats,
      int partNumber,
      int totalParts) {
    final partInfo = totalParts > 1
        ? '<div class="part-indicator"><strong>📧 Part $partNumber of $totalParts</strong></div>'
        : '';

    final showingPartial = linesToShow.length < totalLineCount;

    final buffer = StringBuffer();
    buffer.writeln('''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { 
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      line-height: 1.6;
      color: #333;
      max-width: 900px;
      margin: 0 auto;
      padding: 20px;
    }
    .part-indicator {
      background: #fff3e0;
      color: #f57c00;
      padding: 12px;
      border-radius: 5px;
      margin-bottom: 15px;
      text-align: center;
      font-size: 16px;
      border: 2px solid #ffb74d;
    }
    .header { 
      background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
      color: white;
      padding: 25px;
      border-radius: 10px;
      margin-bottom: 20px;
      box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    }
    h2 { 
      margin-top: 0;
      font-size: 28px;
      border-bottom: 2px solid rgba(255, 255, 255, 0.3);
      padding-bottom: 10px;
    }
    .info-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
      gap: 15px;
      margin: 20px 0;
    }
    .info-item {
      background: rgba(255, 255, 255, 0.1);
      padding: 10px;
      border-radius: 5px;
    }
    .info-label {
      font-size: 12px;
      opacity: 0.9;
      text-transform: uppercase;
      letter-spacing: 1px;
    }
    .info-value {
      font-size: 18px;
      font-weight: bold;
      margin-top: 5px;
    }
    .stats { 
      background: white;
      color: #333;
      margin: 20px 0;
      padding: 20px;
      border-radius: 10px;
      box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    }
    .stats h3 {
      margin-top: 0;
      color: #1e3c72;
    }
    .stat-line { 
      display: flex;
      justify-content: space-between;
      padding: 8px 12px;
      margin: 5px 0;
      border-radius: 5px;
      background: #f8f9fa;
    }
    .level-fatal { background: #ffebee; color: #c62828; font-weight: bold; }
    .level-error { background: #ffebee; color: #d32f2f; }
    .level-warn { background: #fff3e0; color: #f57c00; }
    .level-info { background: #e3f2fd; color: #1976d2; }
    .level-debug { background: #f5f5f5; color: #616161; }
    .level-trace { background: #fafafa; color: #9e9e9e; }
    .logs { 
      margin: 20px 0; 
      background-color: #fafafa; 
      padding: 15px;
      border: 1px solid #ddd;
      font-family: 'Courier New', monospace;
      font-size: 0.9em;
      max-height: 600px;
      overflow-y: auto;
      border-radius: 5px;
    }
    .log-line { 
      margin: 2px 0; 
      padding: 2px 5px;
      white-space: pre-wrap;
      word-wrap: break-word;
    }
    .line-fatal { background: #ffebee; color: #8b0000; font-weight: bold; }
    .line-error { background: #ffebee; color: #d32f2f; }
    .line-warn { background: #fff3e0; color: #f57c00; }
    .line-info { background: #e3f2fd; color: #1976d2; }
    .line-debug { background: #f5f5f5; color: #616161; }
    .line-trace { background: #fafafa; color: #9e9e9e; }
    .attachment-note {
      background: #e8f5e9;
      color: #2e7d32;
      padding: 15px;
      border-radius: 5px;
      margin-top: 20px;
      border-left: 4px solid #4caf50;
    }
    .showing-partial {
      background: #fff3e0;
      color: #f57c00;
      padding: 10px;
      border-radius: 5px;
      margin: 15px 0;
      text-align: center;
      font-style: italic;
    }
  </style>
</head>
<body>
  $partInfo
  <div class="header">
    <h2>📊 Log Report${totalParts > 1 ? " - Part $partNumber/$totalParts" : ""}</h2>
    
    <div class="info-grid">
      <div class="info-item">
        <div class="info-label">${totalParts > 1 ? "Part Lines" : "Total Lines"}</div>
        <div class="info-value">$totalLineCount</div>
      </div>
      <div class="info-item">
        <div class="info-label">${totalParts > 1 ? "Part Size" : "File Size"}</div>
        <div class="info-value">${_formatFileSize(fileSize)}</div>
      </div>
      <div class="info-item">
        <div class="info-label">Period</div>
        <div class="info-value">${rotationCycle.name}</div>
      </div>
  ''');

    if (includeHostnameOrDeviceId) {
      final hostDisplay = _getHostnameOrDeviceId();
      final hostLabel =
          IdProviderResolver.isFlutterApp() ? 'Device ID' : 'Host';

      buffer.writeln('''
      <div class="info-item">
        <div class="info-label">$hostLabel</div>
        <div class="info-value">$hostDisplay</div>
      </div>
    ''');
    }

    if (includeAppInfo) {
      final appVersion = LoggerFactory.getAppVersion();
      if (appVersion != null) {
        buffer.writeln('''
        <div class="info-item">
          <div class="info-label">App Version</div>
          <div class="info-value">$appVersion</div>
        </div>
      ''');
      }
    }

    buffer.writeln('</div></div>'); // Close info-grid and header

    // Log level statistics from THIS PART
    buffer.writeln('<div class="stats">');
    buffer.writeln(
        '<h3>Log Level Distribution ${totalParts > 1 ? "(This Part)" : ""}</h3>');

    ['FATAL', 'ERROR', 'WARN', 'INFO', 'DEBUG', 'TRACE'].forEach((level) {
      final count = stats[level] ?? 0;
      if (count > 0) {
        final cssClass = 'stat-line level-${level.toLowerCase()}';
        buffer.writeln('''
        <div class="$cssClass">
          <span>$level&nbsp;</span>
          <span>$count</span>
        </div>
      ''');
      }
    });

    buffer.writeln('</div>');

    // Note if showing partial
    if (showingPartial) {
      buffer.writeln('''
    <div class="showing-partial">
      📝 Showing last ${linesToShow.length} of $totalLineCount lines from ${totalParts > 1 ? "this part" : "the log"}. 
      Complete ${totalParts > 1 ? "part" : "log"} attached.
    </div>
    ''');
    }

    // Log entries (last N lines from THIS PART)
    buffer.writeln('<div class="logs">');
    buffer.writeln(
        '<h3>Recent Log Entries${showingPartial ? " (Last ${linesToShow.length} lines)" : ""}'
        '${totalParts > 1 ? " from Part $partNumber" : ""}</h3>');

    for (var line in linesToShow) {
      if (line.trim().isEmpty) continue;

      var cssClass = 'log-line';
      if (line.contains('[FATAL]') || line.contains(' FATAL ')) {
        cssClass += ' line-fatal';
      } else if (line.contains('[ERROR]') || line.contains(' ERROR ')) {
        cssClass += ' line-error';
      } else if (line.contains('[WARN]') || line.contains(' WARN ')) {
        cssClass += ' line-warn';
      } else if (line.contains('[INFO]') || line.contains(' INFO ')) {
        cssClass += ' line-info';
      } else if (line.contains('[DEBUG]') || line.contains(' DEBUG ')) {
        cssClass += ' line-debug';
      } else if (line.contains('[TRACE]') || line.contains(' TRACE ')) {
        cssClass += ' line-trace';
      }

      buffer.writeln('<div class="$cssClass">${_escapeHtml(line)}</div>');
    }

    buffer.writeln('</div>');

    if (attachLogFile) {
      buffer.writeln('''
    <div class="attachment-note">
      <strong>📎 ${totalParts > 1 ? "Part $partNumber/$totalParts" : "Complete Log File"} Attached</strong><br>
      ${totalParts > 1 ? "This part contains" : "Full log with"} $totalLineCount entries (${_formatFileSize(fileSize)}).
      ${totalParts > 1 ? "<br>This is part $partNumber of $totalParts total parts." : ""}
    </div>
    ''');
    }

    buffer.writeln('</body></html>');

    return buffer.toString();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

// Text version with attachment note
  String _generateTextBodyWithAttachment(
      List<String> linesToShow,
      int totalLineCount,
      int fileSize,
      Map<String, dynamic> stats,
      int partNumber,
      int totalParts) {
    final buffer = StringBuffer();
    final showingPartial = linesToShow.length < totalLineCount;

    buffer.writeln('=' * 60);
    buffer.writeln('LOG REPORT');
    if (totalParts > 1) {
      buffer.writeln('Part $partNumber of $totalParts');
    }
    buffer.writeln('Period: ${rotationCycle.name}');
    buffer.writeln('Total Lines: $totalLineCount');
    buffer.writeln('File Size: ${_formatFileSize(fileSize)}');

    if (showingPartial) {
      buffer.writeln('Showing: Last ${linesToShow.length} lines inline');
    }

    buffer.writeln('=' * 60);

    buffer.writeln('\nLog Level Distribution (All $totalLineCount lines):');
    buffer.writeln('-' * 30);

    ['FATAL', 'ERROR', 'WARN', 'INFO', 'DEBUG', 'TRACE'].forEach((level) {
      final count = stats[level] ?? 0;
      if (count > 0) {
        buffer.writeln('$level: $count');
      }
    });

    buffer.writeln('\n' + '=' * 60);
    buffer.writeln(
        'RECENT LOG ENTRIES${showingPartial ? " (LAST ${linesToShow.length} LINES)" : ""}:');
    buffer.writeln('=' * 60);

    for (var line in linesToShow) {
      if (line.trim().isNotEmpty) {
        buffer.writeln(line);
      }
    }

    buffer.writeln('\n' + '=' * 60);
    if (attachLogFile) {
      buffer.writeln(
          '📎 Complete log file attached: $totalLineCount entries, ${_formatFileSize(fileSize)}');
    }
    buffer.writeln('=' * 60);

    return buffer.toString();
  }

  /// Format date for filename (always local time)
  String _formatDateForFilename(DateTime date) {
    // Format as YYYY-MM-DD_HH-mm-ss in local time
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');

    return '${year}-${month}-${day}_${hour}-${minute}-${second}';
  }

  /// Check if enough time has passed to send an email based on rotation cycle
  bool _shouldSendEmail() {
    final now = DateTime.now();

    // Initialize on first check
    if (_lastRotationCheck == null) {
      _lastRotationCheck = now;
      Logger.getSelfLogger()
          ?.logDebug('EmailAppender: First check at ${now.toIso8601String()}');
      return false;
    }

    // For testing with TEN_MINUTES set to 60 seconds, check every minute
    if (test && rotationCycle == RotationCycle.TEN_MINUTES) {
      // Send every minute on the minute for testing
      final shouldSend = _lastRotationCheck!.minute != now.minute;
      if (shouldSend) {
        Logger.getSelfLogger()?.logInfo(
            'Test mode: Minute boundary crossed at ${now.minute}:${now.second}');
      }
      return shouldSend;
    }

    // Calculate if we've crossed a time boundary based on rotation cycle
    bool shouldSend = false;

    switch (rotationCycle) {
      case RotationCycle.TEN_MINUTES:
        final lastBoundary = (_lastRotationCheck!.minute ~/ 10) * 10;
        final currentBoundary = (now.minute ~/ 10) * 10;

        // Remove the minute check - just check if boundary changed
        shouldSend = (lastBoundary != currentBoundary) ||
            _lastRotationCheck!.hour != now.hour ||
            _lastRotationCheck!.day != now.day;

        if (shouldSend) {
          Logger.getSelfLogger()?.logInfo(
              'Ten-minute boundary crossed: ${_lastRotationCheck!.minute} -> ${now.minute} (boundary: $currentBoundary)');
        }
        break;

      case RotationCycle.THIRTY_MINUTES:
        // Check if we've crossed a 30-minute boundary (00, 30)
        final lastHalf = _lastRotationCheck!.minute ~/ 30;
        final currentHalf = now.minute ~/ 30;
        shouldSend = lastHalf != currentHalf ||
            _lastRotationCheck!.hour != now.hour ||
            _lastRotationCheck!.day != now.day;
        break;

      case RotationCycle.HOURLY:
        // Check if we've crossed an hour boundary
        shouldSend = _lastRotationCheck!.hour != now.hour ||
            _lastRotationCheck!.day != now.day;
        break;

      case RotationCycle.DAILY:
        // Check if we've crossed a day boundary
        shouldSend = _lastRotationCheck!.day != now.day;
        break;

      case RotationCycle.NEVER:
        shouldSend = false;
        break;

      default:
        // For other cycles, use duration-based check as fallback
        final elapsed = now.difference(_lastRotationCheck!);
        if (rotationCycle.duration != null) {
          shouldSend = elapsed >= rotationCycle.duration!;
        }
        break;
    }

    return shouldSend;
  }

  /// Override to NOT include rotation suffix in filename
  /// EmailAppender uses the same file continuously
  @override
  String getFullFilename() {
    String fullPath;

    // If we have a resolved base path, we're in Flutter mode
    if (resolvedBasePath != null) {
      // Flutter mode - everything goes under app documents
      String cleanPath = path;
      // Remove leading slash
      if (cleanPath.startsWith('/')) {
        cleanPath = cleanPath.substring(1);
      }
      // Replace Windows drive letters (C:/ becomes C_/)
      if (cleanPath.length > 1 && cleanPath[1] == ':') {
        cleanPath = cleanPath.replaceFirst(':', '_');
      }

      fullPath = '$resolvedBasePath/$cleanPath';
    } else {
      // Standard filesystem mode - use path as given (absolute or relative)
      fullPath = path;
    }

    // Ensure path ends with separator
    if (fullPath.isNotEmpty &&
        !fullPath.endsWith('/') &&
        !fullPath.endsWith('\\')) {
      fullPath += '/';
    }

    // EmailAppender: NO rotation suffix - always use the same file
    return '$fullPath$filePattern.$fileExtension';
  }

  /// Override the parent's checkForFileChange to prevent file rotation
  @override
  void checkForFileChange() {
    // Do nothing - we don't want to rotate files
    // EmailAppender keeps writing to the same file
  }

  Map<String, int> _analyzeLogContent(List<String> lines) {
    final stats = {
      'FATAL': 0,
      'ERROR': 0,
      'WARN': 0,
      'INFO': 0,
      'DEBUG': 0,
      'TRACE': 0,
      'UNKNOWN': 0, // Add counter for lines without clear level
    };

    for (var line in lines) {
      if (line.trim().isEmpty) continue;

      bool foundLevel = false;

      // Check for level patterns in various formats
      for (var level in ['FATAL', 'ERROR', 'WARN', 'INFO', 'DEBUG', 'TRACE']) {
        // Check for [LEVEL], [ LEVEL ], or just LEVEL with word boundaries
        if (line.contains('[$level]') ||
            line.contains(' $level ') ||
            line.contains(' $level:') ||
            line.contains('|$level|') ||
            RegExp('\\b$level\\b').hasMatch(line)) {
          stats[level] = stats[level]! + 1;
          foundLevel = true;
          break;
        }
      }

      // If no level found, count as UNKNOWN or try to infer
      if (!foundLevel) {
        // Try to infer from content patterns
        if (line.contains('ERROR') ||
            line.contains('Exception') ||
            line.contains('Failed')) {
          stats['ERROR'] = stats['ERROR']! + 1;
        } else if (line.contains('WARN') || line.contains('Warning')) {
          stats['WARN'] = stats['WARN']! + 1;
        } else if (line.contains('DEBUG')) {
          stats['DEBUG'] = stats['DEBUG']! + 1;
        } else {
          // Default to INFO for normal log lines
          stats['INFO'] = stats['INFO']! + 1;
        }
      }
    }

    // Log what we found for debugging
    final totalCounted = stats.values.reduce((a, b) => a + b);
    if (totalCounted == 0) {
      Logger.getSelfLogger()
          ?.logWarn('No log levels detected in ${lines.length} lines. '
              'Check that your log format includes level markers.');
    } else {
      Logger.getSelfLogger()?.logDebug('Analyzed ${lines.length} lines: '
          '${stats.entries.where((e) => e.value > 0).map((e) => "${e.key}:${e.value}").join(", ")}');
    }

    return stats;
  }

  String _generateSubject(File logFile) {
    final hostnameOrDeviceId =
        includeHostnameOrDeviceId ? ' - ${_getHostnameOrDeviceId()}' : '';
    final period = ' [${rotationCycle.name}]';

    // Use local time for subject
    final now = DateTime.now();
    final roundedTime = _roundToRotationBoundary(now);
    final timestamp = useLocalTimeInSubject
        ? _formatLocalDateTime(roundedTime)
        : roundedTime.toIso8601String();

    if (IdProviderResolver.isFlutterApp()) {
      return '$subjectPrefix Device ID: $hostnameOrDeviceId$period - $timestamp';
    }

    return '$subjectPrefix Host: $hostnameOrDeviceId$period - $timestamp';
  }

  /// Format local date time for subject (Manila time)
  String _formatLocalDateTime(DateTime date) {
    // Format as YYYY-MM-DD HH:mm:ss in local time
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');

    return '$year-$month-$day $hour:$minute:$second';
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  String _getHostnameOrDeviceId() {
    if (IdProviderResolver.isFlutterApp()) {
      // On Flutter, use device ID
      return LoggerFactory.getDeviceId() ?? '<device_id>';
    } else {
      try {
        return Platform.localHostname;
      } catch (e) {
        return 'unknown';
      }
    }
  }

  @override
  Future<void> flush() async {
    // no log sending on flush
  }

  @override
  Future<void> dispose() async {
    await super.dispose();
  }

  @override
  Appender createDeepCopy() {
    EmailAppender copy = EmailAppender();

    // Copy base properties
    copyBasePropertiesTo(copy);

    // Copy FileAppender properties
    copy.filePattern = filePattern;
    copy.fileExtension = fileExtension;
    copy.path = path;
    copy.rotationCycle = rotationCycle;
    copy.resolvedBasePath = resolvedBasePath;

    // Copy email properties
    copy.test = test;
    copy.smtpHost = smtpHost;
    copy.smtpPort = smtpPort;
    copy.username = username;
    copy.password = password;
    copy.ssl = ssl;
    copy.allowInsecure = allowInsecure;
    copy.ignoreBadCertificate = ignoreBadCertificate;
    copy.fromEmail = fromEmail;
    copy.fromName = fromName;
    copy.toEmails = List.from(toEmails);
    copy.ccEmails = List.from(ccEmails);
    copy.bccEmails = List.from(bccEmails);
    copy.replyTo = replyTo;
    copy.subjectPrefix = subjectPrefix;
    copy.includeHostnameOrDeviceId = includeHostnameOrDeviceId;
    copy.includeAppInfo = includeAppInfo;

    // Copy formatting properties
    copy.sendAsHtml = sendAsHtml;
    copy.attachLogFile = attachLogFile;
    copy.maxInlineLines = maxInlineLines;
    copy.includeStackTrace = includeStackTrace;
    copy.includeMetadata = includeMetadata;
    copy.emailTemplate = emailTemplate;
    copy.groupByLevel = groupByLevel;

    // Copy attachment and timezone properties
    copy.attachmentFilePattern = attachmentFilePattern;
    copy.useLocalTimeInSubject = useLocalTimeInSubject;

    // Copy size limits
    copy.maxEmailSizeBytes = maxEmailSizeBytes;

    // Copy rate limiting
    copy.maxEmailsPerHour = maxEmailsPerHour;
    copy.rateLimitWindow = rateLimitWindow;

    // Copy priority settings
    copy.sendImmediatelyOnError = sendImmediatelyOnError;
    copy.immediateErrorThreshold = immediateErrorThreshold;
    copy.deleteLogOnRestart = deleteLogOnRestart;

    // Copy state
    copy._lastRotationCheck = DateTime.now(); // Reset to now for copy

    if (!copy.test) {
      copy._setupSmtpServer();
    }

    copy.ensurePathExists();

    return copy;
  }

  @override
  String getType() {
    return appenderName;
  }

  @override
  String getShortConfigDesc() {
    return 'smtp: $smtpHost:$smtpPort, from: $fromEmail, '
        'to: ${toEmails.join(", ")}, rotation: ${rotationCycle.name}, '
        'path: ${resolvedBasePath ?? ""}$path';
  }

  @override
  String toString() {
    return 'EmailAppender(smtp: $smtpHost:$smtpPort, from: $fromEmail, '
        'to: ${toEmails.join(", ")}, rotation: ${rotationCycle.name}, '
        'path: $path, stats: {sent: $_successfulSends, failed: $_failedSends})';
  }

  /// Get statistics about sent emails
  Map<String, dynamic> getStatistics() {
    return {
      'successfulSends': _successfulSends,
      'failedSends': _failedSends,
      'lastSendTime': _lastSendTime?.toIso8601String(),
      'errorBufferSize': _errorBuffer.length,
      'currentLogFile': getFullFilename(),
      'rateLimitRemaining': maxEmailsPerHour - _sentTimestamps.length,
      'lastRotationCheck': _lastRotationCheck?.toIso8601String(),
    };
  }

  @override
  Map<String, dynamic> getConfig() {
    final config = super.getConfig(); // Gets base Appender config

    // File configuration
    config.addAll({
      'filePattern': filePattern,
      'fileExtension': fileExtension,
      'path': path,
      'resolvedBasePath': resolvedBasePath,
      'fullFilePath': getFullFilename(),
      'fileExists': file.existsSync(),
      'fileAbsolutePath': file.absolute.path,
      'fileSize': file.existsSync() ? file.lengthSync() : 0,
    });

    // SMTP configuration (exclude password)
    config.addAll({
      'smtpHost': smtpHost,
      'smtpPort': smtpPort,
      'ssl': ssl,
      'allowInsecure': allowInsecure,
      'ignoreBadCertificate': ignoreBadCertificate,
      'username': username != null ? _obfuscateEmail(username!) : null,
      'hasPassword': password != null && password!.isNotEmpty,
      // Never include actual password
    });

    // Email addresses
    config.addAll({
      'fromEmail': fromEmail,
      'fromName': fromName,
      'toEmails': toEmails,
      'ccEmails': ccEmails,
      'bccEmails': bccEmails,
      'replyTo': replyTo,
    });

    // Email settings
    config.addAll({
      'subjectPrefix': subjectPrefix,
      'includeHostname': includeHostnameOrDeviceId,
      'includeAppInfo': includeAppInfo,
      'attachmentFilePattern': attachmentFilePattern,
      'useLocalTimeInSubject': useLocalTimeInSubject,
    });

    // Email formatting
    config.addAll({
      'sendAsHtml': sendAsHtml,
      'attachLogFile': attachLogFile,
      'maxInlineLines': maxInlineLines,
      'includeStackTrace': includeStackTrace,
      'includeMetadata': includeMetadata,
      'emailTemplate': emailTemplate,
      'groupByLevel': groupByLevel,
    });

    // Rotation configuration
    config.addAll({
      'rotationCycle': rotationCycle.name,
      'rotationCycleValue': rotationCycle.value,
      'rotationDuration': rotationCycle.duration?.toString(),
      'deleteLogOnRestart': deleteLogOnRestart,
    });

    // Size limits
    config.addAll({
      'maxEmailSizeBytes': maxEmailSizeBytes,
      'maxEmailSizeMB': (maxEmailSizeBytes / (1024 * 1024)).toStringAsFixed(2),
    });

    // Priority settings
    config.addAll({
      'sendImmediatelyOnError': sendImmediatelyOnError,
      'immediateErrorThreshold': immediateErrorThreshold,
    });

    // Rate limiting
    config.addAll({
      'maxEmailsPerHour': maxEmailsPerHour,
      'rateLimitWindow': rateLimitWindow.toString(),
      'rateLimitRemaining': maxEmailsPerHour - _sentTimestamps.length,
    });

    // Test mode
    config.addAll({
      'testMode': test,
    });

    return config;
  }

  DateTime? getNextSendTime() {
    final now = DateTime.now();

    if (test && rotationCycle == RotationCycle.TEN_MINUTES) {
      // In test mode, next minute
      return DateTime(
          now.year, now.month, now.day, now.hour, now.minute + 1, 0);
    }

    switch (rotationCycle) {
      case RotationCycle.TEN_MINUTES:
        // Next 10-minute boundary
        final currentBoundary = (now.minute ~/ 10) * 10;
        final nextBoundary = currentBoundary + 10;
        if (nextBoundary >= 60) {
          return DateTime(now.year, now.month, now.day, now.hour + 1, 0, 0);
        }
        return DateTime(
            now.year, now.month, now.day, now.hour, nextBoundary, 0);

      case RotationCycle.THIRTY_MINUTES:
        // Next 30-minute boundary
        if (now.minute < 30) {
          return DateTime(now.year, now.month, now.day, now.hour, 30, 0);
        }
        return DateTime(now.year, now.month, now.day, now.hour + 1, 0, 0);

      case RotationCycle.HOURLY:
        // Next hour
        return DateTime(now.year, now.month, now.day, now.hour + 1, 0, 0);

      case RotationCycle.DAILY:
        // Next midnight
        return DateTime(now.year, now.month, now.day + 1, 0, 0, 0);

      default:
        return null;
    }
  }

  Future<void> sendNow() async {
    Logger.getSelfLogger()?.logInfo('Manual email send triggered');
    await _performSwapAndSend();
    _lastRotationCheck = DateTime.now();
    _errorBuffer.clear();
  }

  /// Helper method to obfuscate email for security
  String _obfuscateEmail(String email) {
    if (email.isEmpty) return '';

    final atIndex = email.indexOf('@');
    if (atIndex <= 0) return '***';

    final localPart = email.substring(0, atIndex);
    final domain = email.substring(atIndex);

    if (localPart.length <= 3) {
      return '***$domain';
    }

    // Show first 2 chars and last char of local part
    return '${localPart.substring(0, 2)}***${localPart.substring(localPart.length - 1)}$domain';
  }

  DateTime _roundToRotationBoundary(DateTime date) {
    switch (rotationCycle) {
      case RotationCycle.TEN_MINUTES:
        final minute = (date.minute ~/ 10) * 10;
        return DateTime(
            date.year, date.month, date.day, date.hour, minute, 0, 0);

      case RotationCycle.THIRTY_MINUTES:
        final minute = (date.minute ~/ 30) * 30;
        return DateTime(
            date.year, date.month, date.day, date.hour, minute, 0, 0);

      case RotationCycle.HOURLY:
        return DateTime(date.year, date.month, date.day, date.hour, 0, 0, 0);

      case RotationCycle.TWO_HOURS:
        final hour = (date.hour ~/ 2) * 2;
        return DateTime(date.year, date.month, date.day, hour, 0, 0, 0);

      case RotationCycle.FOUR_HOURS:
        final hour = (date.hour ~/ 4) * 4;
        return DateTime(date.year, date.month, date.day, hour, 0, 0, 0);

      case RotationCycle.SIX_HOURS:
        final hour = (date.hour ~/ 6) * 6;
        return DateTime(date.year, date.month, date.day, hour, 0, 0, 0);

      case RotationCycle.TWELVE_HOURS:
        final hour = (date.hour ~/ 12) * 12;
        return DateTime(date.year, date.month, date.day, hour, 0, 0, 0);

      case RotationCycle.DAILY:
        return DateTime(date.year, date.month, date.day, 0, 0, 0, 0);

      case RotationCycle.WEEKLY:
        // Round to Monday midnight
        final weekday = date.weekday;
        final daysToSubtract = weekday - 1; // Monday is 1
        final monday = date.subtract(Duration(days: daysToSubtract));
        return DateTime(monday.year, monday.month, monday.day, 0, 0, 0, 0);

      case RotationCycle.MONTHLY:
        return DateTime(date.year, date.month, 1, 0, 0, 0, 0);

      default:
        return date; // No rounding for NEVER or unknown
    }
  }

  /// Additional debug method to get config as formatted string
  String getConfigAsString() {
    final config = getConfig();
    final buffer = StringBuffer();

    buffer.writeln('=== EmailAppender Configuration ===');

    // Group by category
    buffer.writeln('\n📁 File Settings:');
    buffer.writeln('  Path: ${config['path']}');
    buffer.writeln('  File Pattern: ${config['filePattern']}');
    buffer.writeln('  Full Path: ${config['fullFilePath']}');
    buffer.writeln('  File Exists: ${config['fileExists']}');
    buffer.writeln('  File Size: ${config['fileSize']} bytes');
    buffer.writeln('  Delete on Restart: ${config['deleteLogOnRestart']}');

    buffer.writeln('\n📧 SMTP Configuration:');
    buffer.writeln('  Host: ${config['smtpHost']}:${config['smtpPort']}');
    buffer.writeln('  SSL: ${config['ssl']}');
    buffer.writeln('  Username: ${config['username'] ?? 'none'}');
    buffer.writeln('  Password Set: ${config['hasPassword']}');

    buffer.writeln('\n✉️ Email Settings:');
    buffer.writeln(
        '  From: ${config['fromEmail']} ${config['fromName'] != null ? '(${config['fromName']})' : ''}');
    buffer.writeln('  To: ${(config['toEmails'] as List).join(', ')}');
    if ((config['ccEmails'] as List).isNotEmpty) {
      buffer.writeln('  CC: ${(config['ccEmails'] as List).join(', ')}');
    }
    if ((config['bccEmails'] as List).isNotEmpty) {
      buffer.writeln('  BCC: ${(config['bccEmails'] as List).join(', ')}');
    }
    buffer.writeln('  Subject Prefix: ${config['subjectPrefix']}');
    buffer.writeln(
        '  Attachment Pattern: ${config['attachmentFilePattern'] ?? 'default'}');

    buffer.writeln('\n🔄 Rotation Settings:');
    buffer.writeln(
        '  Cycle: ${config['rotationCycle']} (${config['rotationCycleValue']})');
    buffer.writeln('  Last Check: ${config['lastRotationCheck'] ?? 'never'}');
    buffer.writeln('  Next Rotation: ${config['nextRotationTime'] ?? 'N/A'}');
    if (config['minutesUntilRotation'] != null) {
      buffer.writeln('  Minutes Until: ${config['minutesUntilRotation']}');
    }

    buffer.writeln('\n📊 Size Limits:');
    buffer.writeln('  Max Email Size: ${config['maxEmailSizeMB']} MB');
    buffer.writeln('  Max Inline Lines: ${config['maxInlineLines']}');

    buffer.writeln('\n⚡ Priority Settings:');
    buffer.writeln('  Send on Error: ${config['sendImmediatelyOnError']}');
    buffer.writeln('  Error Threshold: ${config['immediateErrorThreshold']}');
    buffer.writeln('  Error Buffer Size: ${config['errorBufferSize']}');

    buffer.writeln('\n⏰ Rate Limiting:');
    buffer.writeln('  Max Per Hour: ${config['maxEmailsPerHour']}');
    buffer.writeln('  Remaining: ${config['rateLimitRemaining']}');

    buffer.writeln('\n📈 Statistics:');
    buffer.writeln('  Successful Sends: ${config['successfulSends']}');
    buffer.writeln('  Failed Sends: ${config['failedSends']}');
    buffer.writeln('  Last Send: ${config['lastSendTime'] ?? 'never'}');

    buffer.writeln('\n🎨 Format Settings:');
    buffer.writeln('  Send as HTML: ${config['sendAsHtml']}');
    buffer.writeln('  Attach Log File: ${config['attachLogFile']}');
    buffer.writeln('  Include Stack Trace: ${config['includeStackTrace']}');
    buffer.writeln('  Group by Level: ${config['groupByLevel']}');

    buffer.writeln('\n⚙️ Base Settings:');
    buffer.writeln('  Enabled: ${config['enabled']}');
    buffer.writeln('  Level: ${config['level']}');
    buffer.writeln('  Test Mode: ${config['testMode']}');

    buffer.writeln('\n===================================');

    return buffer.toString();
  }
}
