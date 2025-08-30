import 'dart:async';
import 'dart:io';

import 'package:any_logger/any_logger.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

/// Appender that sends log records via email using SMTP.
///
/// Features:
/// - SMTP server configuration with SSL/TLS support
/// - Automatic batching of log records
/// - Rate limiting to prevent email flooding
/// - HTML and plain text formatting
/// - Multiple recipients with CC/BCC support
/// - Customizable email templates
/// - Priority-based sending
/// - Attachment support for critical errors
class EmailAppender extends Appender {
  static const String appenderName = 'EMAIL';

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
  bool includeHostname = true;
  bool includeAppInfo = true;

  // Batching settings
  final List<LogRecord> _logBuffer = [];
  int batchSize = 50;
  Duration batchInterval = Duration(minutes: 5);
  Timer? _batchTimer;

  // Rate limiting
  int maxEmailsPerHour = 20;
  final List<DateTime> _sentTimestamps = [];
  Duration rateLimitWindow = Duration(hours: 1);

  // Email formatting
  bool sendAsHtml = true;
  bool includeStackTrace = true;
  bool includeMetadata = true;
  String? emailTemplate; // Custom template
  bool groupByLevel = true;

  // Priority settings
  bool sendImmediatelyOnError = true;
  int immediateErrorThreshold = 10; // Send immediately if X errors in buffer

  // Statistics
  int _successfulSends = 0;
  int _failedSends = 0;
  DateTime? _lastSendTime;

  // Test mode
  bool test = false;
  SmtpServer? _smtpServer;
  Timer? _rateLimitCleanupTimer;

  EmailAppender() : super();

  /// Factory constructor for configuration-based creation
  static Future<EmailAppender> fromConfig(Map<String, dynamic> config, {bool test = false, DateTime? date}) async {
    final appender = EmailAppender()
      ..test = test
      ..created = date ?? DateTime.now();

    appender.initializeCommonProperties(config, test: test, date: date);

    // Required SMTP fields
    if (!config.containsKey('smtpHost')) {
      throw ArgumentError('Missing smtpHost argument for EmailAppender');
    }
    appender.smtpHost = config['smtpHost'];

    if (!config.containsKey('smtpPort')) {
      throw ArgumentError('Missing smtpPort argument for EmailAppender');
    }
    appender.smtpPort = config['smtpPort'];

    // Required email fields
    if (!config.containsKey('fromEmail')) {
      throw ArgumentError('Missing fromEmail argument for EmailAppender');
    }
    appender.fromEmail = config['fromEmail'];

    if (!config.containsKey('toEmails')) {
      throw ArgumentError('Missing toEmails argument for EmailAppender');
    }

    // Handle toEmails as either String or List
    final toEmailsConfig = config['toEmails'];
    if (toEmailsConfig is String) {
      appender.toEmails = toEmailsConfig.split(',').map((e) => e.trim()).toList();
    } else if (toEmailsConfig is List) {
      appender.toEmails = List<String>.from(toEmailsConfig);
    } else {
      throw ArgumentError('toEmails must be a String or List<String>');
    }

    // Optional SMTP settings
    if (config.containsKey('username')) {
      appender.username = config['username'];
    }
    if (config.containsKey('password')) {
      appender.password = config['password'];
    }
    if (config.containsKey('ssl')) {
      appender.ssl = config['ssl'];
    }
    if (config.containsKey('allowInsecure')) {
      appender.allowInsecure = config['allowInsecure'];
    }
    if (config.containsKey('ignoreBadCertificate')) {
      appender.ignoreBadCertificate = config['ignoreBadCertificate'];
    }

    // Optional email settings
    if (config.containsKey('fromName')) {
      appender.fromName = config['fromName'];
    }
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
    if (config.containsKey('replyTo')) {
      appender.replyTo = config['replyTo'];
    }
    if (config.containsKey('subjectPrefix')) {
      appender.subjectPrefix = config['subjectPrefix'];
    }
    if (config.containsKey('includeHostname')) {
      appender.includeHostname = config['includeHostname'];
    }
    if (config.containsKey('includeAppInfo')) {
      appender.includeAppInfo = config['includeAppInfo'];
    }

    // Batch settings
    if (config.containsKey('batchSize')) {
      appender.batchSize = config['batchSize'];
    }
    if (config.containsKey('batchIntervalMinutes')) {
      appender.batchInterval = Duration(minutes: config['batchIntervalMinutes']);
    } else if (config.containsKey('batchIntervalSeconds')) {
      appender.batchInterval = Duration(seconds: config['batchIntervalSeconds']);
    }

    // Rate limiting
    if (config.containsKey('maxEmailsPerHour')) {
      appender.maxEmailsPerHour = config['maxEmailsPerHour'];
    }

    // Formatting options
    if (config.containsKey('sendAsHtml')) {
      appender.sendAsHtml = config['sendAsHtml'];
    }
    if (config.containsKey('includeStackTrace')) {
      appender.includeStackTrace = config['includeStackTrace'];
    }
    if (config.containsKey('includeMetadata')) {
      appender.includeMetadata = config['includeMetadata'];
    }
    if (config.containsKey('emailTemplate')) {
      appender.emailTemplate = config['emailTemplate'];
    }
    if (config.containsKey('groupByLevel')) {
      appender.groupByLevel = config['groupByLevel'];
    }

    // Priority settings
    if (config.containsKey('sendImmediatelyOnError')) {
      appender.sendImmediatelyOnError = config['sendImmediatelyOnError'];
    }
    if (config.containsKey('immediateErrorThreshold')) {
      appender.immediateErrorThreshold = config['immediateErrorThreshold'];
    }

    await appender.initialize();

    return appender;
  }

  /// Synchronous factory - throws since email requires async
  factory EmailAppender.fromConfigSync(Map<String, dynamic> config) {
    throw UnsupportedError('EmailAppender requires async initialization. Use fromConfig() or builder().build()');
  }

  /// Initialize the appender
  Future<void> initialize() async {
    if (test) {
      Logger.getSelfLogger()?.logInfo('EmailAppender in test mode - skipping SMTP and timer initialization');
      return;
    }

    // Setup SMTP server
    _setupSmtpServer();

    // Start batch timer
    _startBatchTimer();

    // Start rate limit cleanup timer
    _startRateLimitCleanupTimer();

    Logger.getSelfLogger()?.logInfo('EmailAppender initialized: $this');
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

  void _startBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(batchInterval, (_) {
      if (_logBuffer.isNotEmpty) {
        _sendEmail();
      }
    });
    Logger.getSelfLogger()?.logDebug('Batch timer started with interval: $batchInterval');
  }

  void _startRateLimitCleanupTimer() {
    _rateLimitCleanupTimer?.cancel();
    _rateLimitCleanupTimer = Timer.periodic(Duration(minutes: 5), (_) {
      _cleanupRateLimitTimestamps();
    });
  }

  void _cleanupRateLimitTimestamps() {
    final cutoff = DateTime.now().subtract(rateLimitWindow);
    _sentTimestamps.removeWhere((timestamp) => timestamp.isBefore(cutoff));
  }

  bool _isWithinRateLimit() {
    _cleanupRateLimitTimestamps();
    return _sentTimestamps.length < maxEmailsPerHour;
  }

  @override
  Appender createDeepCopy() {
    EmailAppender copy = EmailAppender();
    copyBasePropertiesTo(copy);

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
    copy.includeHostname = includeHostname;
    copy.includeAppInfo = includeAppInfo;
    copy.batchSize = batchSize;
    copy.batchInterval = batchInterval;
    copy.maxEmailsPerHour = maxEmailsPerHour;
    copy.rateLimitWindow = rateLimitWindow;
    copy.sendAsHtml = sendAsHtml;
    copy.includeStackTrace = includeStackTrace;
    copy.includeMetadata = includeMetadata;
    copy.emailTemplate = emailTemplate;
    copy.groupByLevel = groupByLevel;
    copy.sendImmediatelyOnError = sendImmediatelyOnError;
    copy.immediateErrorThreshold = immediateErrorThreshold;

    if (!copy.test) {
      copy._setupSmtpServer();
      copy._startBatchTimer();
      copy._startRateLimitCleanupTimer();
    }

    return copy;
  }

  @override
  void append(LogRecord logRecord) {
    if (!enabled) return;

    logRecord.loggerName ??= getType().toString();

    // Add to buffer
    _logBuffer.add(logRecord);

    // Check if we should send immediately for errors
    if (sendImmediatelyOnError && logRecord.level.index >= Level.ERROR.index) {
      final errorCount = _logBuffer.where((log) => log.level.index >= Level.ERROR.index).length;

      if (errorCount >= immediateErrorThreshold) {
        _sendEmail();
      }
    }
    // Or if buffer is full
    else if (_logBuffer.length >= batchSize) {
      _sendEmail();
    }
  }

  Future<void> _sendEmail() async {
    if (_logBuffer.isEmpty) return;

    // Check rate limit
    if (!_isWithinRateLimit()) {
      Logger.getSelfLogger()?.logWarn('Email rate limit reached. Skipping send of ${_logBuffer.length} logs');
      return;
    }

    // Copy and clear buffer
    final logs = List<LogRecord>.from(_logBuffer);
    _logBuffer.clear();

    if (test) {
      Logger.getSelfLogger()
          ?.logDebug('Test mode: Would send email with ${logs.length} logs to ${toEmails.join(", ")}');
      _successfulSends++;
      _lastSendTime = DateTime.now();
      return;
    }

    try {
      final message = _createEmailMessage(logs);

      await send(message, _smtpServer!);

      _successfulSends++;
      _sentTimestamps.add(DateTime.now());
      _lastSendTime = DateTime.now();

      Logger.getSelfLogger()?.logInfo('Sent email with ${logs.length} log records');
    } catch (e) {
      _failedSends++;
      Logger.getSelfLogger()?.logError('Failed to send email: $e');

      // Put logs back if there's room
      if (_logBuffer.length < batchSize * 2) {
        _logBuffer.insertAll(0, logs);
      }
    }
  }

  Message _createEmailMessage(List<LogRecord> logs) {
    final subject = _generateSubject(logs);
    final body = sendAsHtml ? _generateHtmlBody(logs) : _generateTextBody(logs);

    final message = Message()
      ..from = fromName != null ? Address(fromEmail, fromName) : Address(fromEmail)
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

    if (sendAsHtml) {
      message.html = body;
      message.text = _generateTextBody(logs); // Fallback
    } else {
      message.text = body;
    }

    return message;
  }

  String _generateSubject(List<LogRecord> logs) {
    final highestLevel = logs.map((log) => log.level).reduce((a, b) => a.index > b.index ? a : b);

    final hostname = includeHostname ? ' - ${_getHostname()}' : '';
    final levelStr = highestLevel.name;

    // Count by level
    final errorCount = logs.where((l) => l.level == Level.ERROR).length;
    final warnCount = logs.where((l) => l.level == Level.WARN).length;

    String counts = '';
    if (errorCount > 0) counts += ' ${errorCount} errors';
    if (warnCount > 0) {
      if (counts.isNotEmpty) counts += ',';
      counts += ' ${warnCount} warnings';
    }

    return '$subjectPrefix [$levelStr]$hostname - ${logs.length} logs$counts';
  }

  String _generateHtmlBody(List<LogRecord> logs) {
    if (emailTemplate != null) {
      return _applyTemplate(emailTemplate!, logs, true);
    }

    final buffer = StringBuffer();
    buffer.writeln('''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; }
    .header { background-color: #f0f0f0; padding: 10px; border-radius: 5px; }
    .metadata { color: #666; font-size: 0.9em; margin: 10px 0; }
    .logs { margin: 20px 0; }
    .log-entry { 
      margin: 10px 0; 
      padding: 10px; 
      border-left: 3px solid #ccc;
      background-color: #fafafa;
    }
    .log-error { border-left-color: #d9534f; background-color: #fff5f5; }
    .log-warn { border-left-color: #f0ad4e; background-color: #fffaf0; }
    .log-info { border-left-color: #5bc0de; background-color: #f0faff; }
    .log-debug { border-left-color: #999; }
    .timestamp { color: #666; font-size: 0.9em; }
    .level { font-weight: bold; margin-right: 10px; }
    .level-error { color: #d9534f; }
    .level-warn { color: #f0ad4e; }
    .level-info { color: #5bc0de; }
    .level-debug { color: #999; }
    .message { margin: 5px 0; }
    .stacktrace { 
      font-family: monospace; 
      font-size: 0.85em; 
      color: #666;
      background-color: #f5f5f5;
      padding: 5px;
      margin: 5px 0;
      overflow-x: auto;
    }
    .footer { 
      margin-top: 30px;
      padding-top: 10px;
      border-top: 1px solid #ccc;
      color: #666;
      font-size: 0.9em;
    }
  </style>
</head>
<body>
''');

    // Header
    buffer.writeln('<div class="header">');
    buffer.writeln('<h2>Log Report</h2>');
    buffer.writeln('</div>');

    // Metadata
    if (includeMetadata) {
      buffer.writeln('<div class="metadata">');
      if (includeHostname) {
        buffer.writeln('<p><strong>Host:</strong> ${_getHostname()}</p>');
      }
      if (includeAppInfo) {
        final appVersion = LoggerFactory.getAppVersion();
        if (appVersion != null && appVersion.isNotEmpty) {
          buffer.writeln('<p><strong>App Version:</strong> $appVersion</p>');
        }
        final deviceId = LoggerFactory.getDeviceId();
        if (deviceId != null && deviceId.isNotEmpty) {
          buffer.writeln('<p><strong>Device ID:</strong> $deviceId</p>');
        }
      }
      buffer.writeln('<p><strong>Generated:</strong> ${DateTime.now()}</p>');
      buffer.writeln('<p><strong>Total Logs:</strong> ${logs.length}</p>');
      buffer.writeln('</div>');
    }

    // Logs
    buffer.writeln('<div class="logs">');

    if (groupByLevel) {
      final groupedLogs = <Level, List<LogRecord>>{};
      for (var log in logs) {
        groupedLogs.putIfAbsent(log.level, () => []).add(log);
      }

      // Sort levels by severity
      final sortedLevels = groupedLogs.keys.toList()..sort((a, b) => b.index.compareTo(a.index));

      for (var level in sortedLevels) {
        buffer.writeln('<h3>${level.name} (${groupedLogs[level]!.length})</h3>');
        for (var log in groupedLogs[level]!) {
          _writeHtmlLogEntry(buffer, log);
        }
      }
    } else {
      for (var log in logs) {
        _writeHtmlLogEntry(buffer, log);
      }
    }

    buffer.writeln('</div>');

    // Footer
    buffer.writeln('<div class="footer">');
    buffer.writeln('<p>Sent by AnyLogger Email Appender</p>');
    buffer.writeln('</div>');

    buffer.writeln('</body></html>');

    return buffer.toString();
  }

  void _writeHtmlLogEntry(StringBuffer buffer, LogRecord log) {
    final levelClass = 'log-${log.level.name.toLowerCase()}';
    final levelColorClass = 'level-${log.level.name.toLowerCase()}';

    buffer.writeln('<div class="log-entry $levelClass">');
    buffer.writeln('<div>');
    buffer.writeln('<span class="level $levelColorClass">${log.level.name}</span>');
    buffer.writeln('<span class="timestamp">${log.time}</span>');
    if (log.loggerName != null) {
      buffer.writeln(' - <span class="logger">${log.loggerName}</span>');
    }
    buffer.writeln('</div>');

    buffer.writeln('<div class="message">${_escapeHtml(log.message.toString())}</div>');

    if (log.error != null) {
      buffer.writeln('<div class="error">');
      buffer.writeln('<strong>Error:</strong> ${_escapeHtml(log.error.toString())}');
      buffer.writeln('</div>');
    }

    if (includeStackTrace && log.stackTrace != null) {
      buffer.writeln('<div class="stacktrace">');
      buffer.writeln(_escapeHtml(log.stackTrace.toString()));
      buffer.writeln('</div>');
    }

    buffer.writeln('</div>');
  }

  String _generateTextBody(List<LogRecord> logs) {
    if (emailTemplate != null) {
      return _applyTemplate(emailTemplate!, logs, false);
    }

    final buffer = StringBuffer();

    buffer.writeln('=' * 60);
    buffer.writeln('LOG REPORT');
    buffer.writeln('=' * 60);
    buffer.writeln();

    if (includeMetadata) {
      if (includeHostname) {
        buffer.writeln('Host: ${_getHostname()}');
      }
      if (includeAppInfo) {
        final appVersion = LoggerFactory.getAppVersion();
        if (appVersion != null && appVersion.isNotEmpty) {
          buffer.writeln('App Version: $appVersion');
        }
      }
      buffer.writeln('Generated: ${DateTime.now()}');
      buffer.writeln('Total Logs: ${logs.length}');
      buffer.writeln();
      buffer.writeln('-' * 60);
      buffer.writeln();
    }

    if (groupByLevel) {
      final groupedLogs = <Level, List<LogRecord>>{};
      for (var log in logs) {
        groupedLogs.putIfAbsent(log.level, () => []).add(log);
      }

      final sortedLevels = groupedLogs.keys.toList()..sort((a, b) => b.index.compareTo(a.index));

      for (var level in sortedLevels) {
        buffer.writeln('${level.name} (${groupedLogs[level]!.length} entries)');
        buffer.writeln('-' * 40);
        for (var log in groupedLogs[level]!) {
          _writeTextLogEntry(buffer, log);
        }
        buffer.writeln();
      }
    } else {
      for (var log in logs) {
        _writeTextLogEntry(buffer, log);
      }
    }

    buffer.writeln();
    buffer.writeln('=' * 60);
    buffer.writeln('Sent by AnyLogger Email Appender');

    return buffer.toString();
  }

  void _writeTextLogEntry(StringBuffer buffer, LogRecord log) {
    buffer.writeln('[${log.time}] [${log.level.name}] ${log.loggerName ?? ''}: ${log.message}');

    if (log.error != null) {
      buffer.writeln('  Error: ${log.error}');
    }

    if (includeStackTrace && log.stackTrace != null) {
      buffer.writeln('  Stack trace:');
      buffer.writeln('  ${log.stackTrace.toString().replaceAll('\n', '\n  ')}');
    }
  }

  String _applyTemplate(String template, List<LogRecord> logs, bool isHtml) {
    // Simple template replacement
    return template
        .replaceAll('{{hostname}}', _getHostname())
        .replaceAll('{{timestamp}}', DateTime.now().toString())
        .replaceAll('{{logCount}}', logs.length.toString())
        .replaceAll('{{logs}}', isHtml ? _generateHtmlLogList(logs) : _generateTextLogList(logs));
  }

  String _generateHtmlLogList(List<LogRecord> logs) {
    final buffer = StringBuffer();
    for (var log in logs) {
      _writeHtmlLogEntry(buffer, log);
    }
    return buffer.toString();
  }

  String _generateTextLogList(List<LogRecord> logs) {
    final buffer = StringBuffer();
    for (var log in logs) {
      _writeTextLogEntry(buffer, log);
    }
    return buffer.toString();
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  String _getHostname() {
    try {
      return Platform.localHostname;
    } catch (e) {
      return 'unknown';
    }
  }

  @override
  Future<void> flush() async {
    if (_logBuffer.isNotEmpty) {
      await _sendEmail();
    }
  }

  @override
  Future<void> dispose() async {
    _batchTimer?.cancel();
    _rateLimitCleanupTimer?.cancel();
    await flush();
    Logger.getSelfLogger()?.logDebug('EmailAppender disposed');
  }

  @override
  String toString() {
    return 'EmailAppender(smtp: $smtpHost:$smtpPort, from: $fromEmail, '
        'to: ${toEmails.join(", ")}, batchSize: $batchSize, '
        'batchInterval: $batchInterval, enabled: $enabled, '
        'stats: {sent: $_successfulSends, failed: $_failedSends})';
  }

  @override
  String getType() {
    return appenderName;
  }

  /// Get statistics about sent emails
  Map<String, dynamic> getStatistics() {
    return {
      'successfulSends': _successfulSends,
      'failedSends': _failedSends,
      'lastSendTime': _lastSendTime?.toIso8601String(),
      'bufferSize': _logBuffer.length,
      'rateLimitRemaining': maxEmailsPerHour - _sentTimestamps.length,
    };
  }

  @override
  String getShortConfigDesc() {
    return 'smtp: $smtpHost:$smtpPort, from: $fromEmail, to: ${toEmails.join(", ")}';
  }
}
