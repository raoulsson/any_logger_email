import 'package:any_logger/any_logger.dart';

import 'email_appender.dart';

/// Builder for creating and configuring EmailAppender instances
///
/// Example usage:
/// ```dart
/// final emailAppender = await emailAppenderBuilder()
///     .withSmtp('smtp.gmail.com', 587)
///     .withCredentials('user@gmail.com', 'app-password')
///     .withFrom('logger@example.com')
///     .withTo(['admin@example.com'])
///     .withRotation(RotationCycle.HOURLY)  // Sends email every hour
///     .withLevel(Level.ERROR)
///     .build();
/// ```
EmailAppenderBuilder emailAppenderBuilder() => EmailAppenderBuilder();

class EmailAppenderBuilder {
  final Map<String, dynamic> _config = {
    'type': EmailAppender.appenderName,
  };

  EmailAppenderBuilder();

  // --- File Settings ---

  /// Sets the file pattern (base name for log files)
  EmailAppenderBuilder withFilePattern(String pattern) {
    _config['filePattern'] = pattern;
    return this;
  }

  /// Sets the path where log files will be stored
  EmailAppenderBuilder withPath(String path) {
    _config['path'] = path;
    return this;
  }

  /// Sets the rotation cycle for email sending
  /// This determines how often emails are sent with accumulated logs
  EmailAppenderBuilder withRotation(RotationCycle cycle) {
    _config['rotationCycle'] = cycle.value;
    return this;
  }

  /// Send emails every 10 minutes
  EmailAppenderBuilder withTenMinuteRotation() {
    _config['rotationCycle'] = RotationCycle.TEN_MINUTES.value;
    return this;
  }

  /// Send emails every 30 minutes
  EmailAppenderBuilder withThirtyMinuteRotation() {
    _config['rotationCycle'] = RotationCycle.THIRTY_MINUTES.value;
    return this;
  }

  /// Send emails every hour
  EmailAppenderBuilder withHourlyRotation() {
    _config['rotationCycle'] = RotationCycle.HOURLY.value;
    return this;
  }

  /// Send emails every 2 hours
  EmailAppenderBuilder withTwoHourRotation() {
    _config['rotationCycle'] = RotationCycle.TWO_HOURS.value;
    return this;
  }

  /// Send emails every 4 hours
  EmailAppenderBuilder withFourHourRotation() {
    _config['rotationCycle'] = RotationCycle.FOUR_HOURS.value;
    return this;
  }

  /// Send emails every 12 hours
  EmailAppenderBuilder withTwelveHourRotation() {
    _config['rotationCycle'] = RotationCycle.TWELVE_HOURS.value;
    return this;
  }

  /// Send emails once per day
  EmailAppenderBuilder withDailyRotation() {
    _config['rotationCycle'] = RotationCycle.DAILY.value;
    return this;
  }

  // --- SMTP Configuration ---

  /// Sets the SMTP server configuration
  EmailAppenderBuilder withSmtp(String host, int port,
      {bool ssl = false,
      bool allowInsecure = false,
      bool ignoreBadCertificate = false}) {
    _config['smtpHost'] = host;
    _config['smtpPort'] = port;
    _config['ssl'] = ssl;
    _config['allowInsecure'] = allowInsecure;
    _config['ignoreBadCertificate'] = ignoreBadCertificate;
    return this;
  }

  /// Sets SMTP credentials for authentication.
  EmailAppenderBuilder withCredentials(
      String username, String passwordOrApiKey) {
    _config['username'] = username;
    _config['password'] = passwordOrApiKey;
    return this;
  }

  /// Sets authentication using an app-specific password
  EmailAppenderBuilder withAppPassword(
      String email, String appSpecificPassword) {
    _config['username'] = email;
    _config['password'] = appSpecificPassword;
    return this;
  }

  /// Sets authentication using an API key
  EmailAppenderBuilder withApiKeyAuth(String username, String apiKey) {
    _config['username'] = username;
    _config['password'] = apiKey;
    return this;
  }

  // --- Email Configuration ---

  /// Sets the sender email address and optional name
  EmailAppenderBuilder withFrom(String email, [String? name]) {
    _config['fromEmail'] = email;
    if (name != null) {
      _config['fromName'] = name;
    }
    return this;
  }

  /// Sets the recipient email addresses
  EmailAppenderBuilder withTo(List<String> emails) {
    _config['toEmails'] = emails;
    return this;
  }

  /// Sets a single recipient email address
  EmailAppenderBuilder withSingleTo(String email) {
    _config['toEmails'] = [email];
    return this;
  }

  /// Sets CC recipients
  EmailAppenderBuilder withCc(List<String> emails) {
    _config['ccEmails'] = emails;
    return this;
  }

  /// Sets BCC recipients
  EmailAppenderBuilder withBcc(List<String> emails) {
    _config['bccEmails'] = emails;
    return this;
  }

  /// Sets the reply-to email address
  EmailAppenderBuilder withReplyTo(String email) {
    _config['replyTo'] = email;
    return this;
  }

  /// Sets the subject line prefix
  EmailAppenderBuilder withSubjectPrefix(String prefix) {
    _config['subjectPrefix'] = prefix;
    return this;
  }

  // --- Common Appender Properties ---

  /// Sets the logging level
  EmailAppenderBuilder withLevel(Level level) {
    _config['level'] = level.name;
    return this;
  }

  /// Sets the log message format pattern
  EmailAppenderBuilder withFormat(String format) {
    _config['format'] = format;
    return this;
  }

  /// Sets the date format pattern
  EmailAppenderBuilder withDateFormat(String dateFormat) {
    _config['dateFormat'] = dateFormat;
    return this;
  }

  /// Sets whether this appender starts enabled
  EmailAppenderBuilder withEnabledState(bool enabled) {
    _config['enabled'] = enabled;
    return this;
  }

  // --- Priority Settings ---

  /// Sets whether to send immediately on error
  EmailAppenderBuilder withImmediateErrors(bool sendImmediately) {
    _config['sendImmediatelyOnError'] = sendImmediately;
    return this;
  }

  /// Sets the threshold for immediate error sending
  EmailAppenderBuilder withErrorThreshold(int threshold) {
    _config['immediateErrorThreshold'] = threshold;
    return this;
  }

  /// Sets the file pattern for email attachments
  /// This is the name used for attached log files (e.g., "my_app" -> "my_app_2025-01-31.log")
  EmailAppenderBuilder withAttachmentPattern(String pattern) {
    _config['attachmentFilePattern'] = pattern;
    return this;
  }

  /// Sets whether to use local time in email subjects (default: true)
  EmailAppenderBuilder withLocalTimeInSubject(bool useLocal) {
    _config['useLocalTimeInSubject'] = useLocal;
    return this;
  }

  EmailAppenderBuilder withDeleteLogOnRestart(bool delete) {
    _config['deleteLogOnRestart'] = delete;
    return this;
  }

  /// Convenience method to keep logs across restarts (default)
  EmailAppenderBuilder withPersistentLogs() {
    _config['deleteLogOnRestart'] = false;
    return this;
  }

  // --- Email Options ---

  /// Sets whether to send emails as HTML
  EmailAppenderBuilder withHtmlFormat(bool sendAsHtml) {
    _config['sendAsHtml'] = sendAsHtml;
    return this;
  }

  /// Sets whether to attach log file vs inline content
  EmailAppenderBuilder withAttachment(bool attachFile) {
    _config['attachLogFile'] = attachFile;
    return this;
  }

  /// Sets max lines for inline display (before switching to attachment)
  EmailAppenderBuilder withMaxInlineLines(int lines) {
    _config['maxInlineLines'] = lines;
    return this;
  }

  /// Sets the rate limit for emails
  EmailAppenderBuilder withRateLimit(int maxEmailsPerHour) {
    _config['maxEmailsPerHour'] = maxEmailsPerHour;
    return this;
  }

  /// Sets whether to include metadata (hostname, app info)
  EmailAppenderBuilder withMetadata(bool include) {
    _config['includeMetadata'] = include;
    return this;
  }

  /// Sets whether to include hostname in subject and body
  EmailAppenderBuilder withHostname(bool include) {
    _config['includeHostname'] = include;
    return this;
  }

  /// Sets whether to include app version and device ID
  EmailAppenderBuilder withAppInfo(bool include) {
    _config['includeAppInfo'] = include;
    return this;
  }

  /// Sets whether to include stack traces
  EmailAppenderBuilder withStackTraces(bool include) {
    _config['includeStackTrace'] = include;
    return this;
  }

  /// Sets whether to group logs by level in the email body
  EmailAppenderBuilder withGroupByLevel(bool group) {
    _config['groupByLevel'] = group;
    return this;
  }

  /// Sets a custom email template
  EmailAppenderBuilder withTemplate(String template) {
    _config['emailTemplate'] = template;
    return this;
  }

  // --- SMTP Provider Presets ---

  /// Gmail configuration using app-specific password
  EmailAppenderBuilder withGmailAppPassword(String email, String appPassword) {
    _config['smtpHost'] = 'smtp.gmail.com';
    _config['smtpPort'] = 587;
    _config['ssl'] = false;
    _config['username'] = email;
    _config['password'] = appPassword;
    _config['fromEmail'] = email;
    return this;
  }

  /// Office 365/Outlook configuration using app-specific password
  EmailAppenderBuilder withOutlookAppPassword(
      String email, String appPassword) {
    _config['smtpHost'] = 'smtp.office365.com';
    _config['smtpPort'] = 587;
    _config['ssl'] = false;
    _config['username'] = email;
    _config['password'] = appPassword;
    _config['fromEmail'] = email;
    return this;
  }

  /// SendGrid configuration using API key
  EmailAppenderBuilder withSendGridApiKey(String apiKey, [String? fromEmail]) {
    _config['smtpHost'] = 'smtp.sendgrid.net';
    _config['smtpPort'] = 587;
    _config['ssl'] = false;
    _config['username'] = 'apikey';
    _config['password'] = apiKey;
    if (fromEmail != null) {
      _config['fromEmail'] = fromEmail;
    }
    return this;
  }

  /// Mailgun configuration using API key
  EmailAppenderBuilder withMailgunApiKey(String apiKey, String domain,
      [String? fromEmail]) {
    _config['smtpHost'] = 'smtp.mailgun.org';
    _config['smtpPort'] = 587;
    _config['ssl'] = false;
    _config['username'] = 'postmaster@$domain';
    _config['password'] = apiKey;
    if (fromEmail != null) {
      _config['fromEmail'] = fromEmail;
    }
    return this;
  }

  /// AWS SES configuration
  EmailAppenderBuilder withAwsSes({
    required String region,
    required String smtpUsername,
    required String smtpPassword,
    String? fromEmail,
  }) {
    _config['smtpHost'] = 'email-smtp.$region.amazonaws.com';
    _config['smtpPort'] = 587;
    _config['ssl'] = false;
    _config['username'] = smtpUsername;
    _config['password'] = smtpPassword;
    if (fromEmail != null) {
      _config['fromEmail'] = fromEmail;
    }
    return this;
  }

  /// Generic SMTP configuration for other providers
  EmailAppenderBuilder withCustomSmtp({
    required String host,
    required int port,
    required String username,
    required String password,
    bool ssl = false,
    bool allowInsecure = false,
    bool ignoreBadCertificate = false,
    String? fromEmail,
  }) {
    _config['smtpHost'] = host;
    _config['smtpPort'] = port;
    _config['username'] = username;
    _config['password'] = password;
    _config['ssl'] = ssl;
    _config['allowInsecure'] = allowInsecure;
    _config['ignoreBadCertificate'] = ignoreBadCertificate;
    if (fromEmail != null) {
      _config['fromEmail'] = fromEmail;
    }
    return this;
  }

  // --- Usage Presets ---

  /// Critical alerts preset - sends very frequently for critical errors
  /// Emails sent every 10 minutes with accumulated critical logs
  EmailAppenderBuilder withCriticalAlertPreset() {
    _config['level'] = Level.ERROR.name;
    _config['rotationCycle'] =
        RotationCycle.TEN_MINUTES.value; // Every 10 minutes
    _config['subjectPrefix'] = '[🚨 CRITICAL ALERT]';
    _config['sendAsHtml'] = true;
    _config['sendImmediatelyOnError'] = true;
    _config['immediateErrorThreshold'] = 1; // Send immediately on first error
    _config['attachLogFile'] = false;
    _config['maxInlineLines'] = 100;
    _config['includeStackTrace'] = true;
    _config['includeMetadata'] = true;
    _config['groupByLevel'] = false; // Chronological for debugging
    _config['maxEmailsPerHour'] = 100; // Higher limit for critical alerts
    return this;
  }

  /// Daily digest preset - sends once per day with all logs
  EmailAppenderBuilder withDailyDigestPreset() {
    _config['level'] = Level.INFO.name;
    _config['rotationCycle'] = RotationCycle.DAILY.value; // Once per day
    _config['subjectPrefix'] = '[DAILY LOG DIGEST]';
    _config['sendAsHtml'] = true;
    _config['sendImmediatelyOnError'] = false;
    _config['attachLogFile'] = true;
    _config['groupByLevel'] = true; // Group by level for summary view
    _config['includeStackTrace'] = false;
    _config['maxEmailsPerHour'] = 5; // Low limit for digests
    return this;
  }

  /// Hourly monitoring preset - sends every hour
  EmailAppenderBuilder withHourlyMonitoringPreset() {
    _config['level'] = Level.WARN.name;
    _config['rotationCycle'] = RotationCycle.HOURLY.value; // Every hour
    _config['subjectPrefix'] = '[HOURLY MONITOR]';
    _config['sendAsHtml'] = true;
    _config['attachLogFile'] = false;
    _config['maxInlineLines'] = 500;
    _config['groupByLevel'] = false; // Chronological order
    _config['includeStackTrace'] = true;
    _config['maxEmailsPerHour'] = 25; // Allow hourly + some extras
    return this;
  }

  /// Development preset - sends frequently for debugging
  EmailAppenderBuilder withDevelopmentPreset() {
    _config['level'] = Level.DEBUG.name;
    _config['rotationCycle'] =
        RotationCycle.THIRTY_MINUTES.value; // Every 30 minutes
    _config['subjectPrefix'] = '[DEV LOG]';
    _config['includeStackTrace'] = true;
    _config['includeMetadata'] = true;
    _config['groupByLevel'] = true; // Group for easier review
    _config['sendAsHtml'] = true;
    _config['attachLogFile'] = false;
    _config['maxInlineLines'] = 200;
    return this;
  }

  /// Weekly report preset - sends once per week
  EmailAppenderBuilder withWeeklyReportPreset() {
    _config['level'] = Level.INFO.name;
    _config['rotationCycle'] = RotationCycle.WEEKLY.value; // Once per week
    _config['subjectPrefix'] = '[WEEKLY REPORT]';
    _config['sendAsHtml'] = true;
    _config['attachLogFile'] = true;
    _config['groupByLevel'] = true; // Group for summary
    _config['includeStackTrace'] = false;
    _config['includeMetadata'] = true;
    _config['maxEmailsPerHour'] = 2; // Very low limit
    return this;
  }

  /// Production preset - balanced for production use
  /// Sends every 2 hours for warnings and errors
  EmailAppenderBuilder withProductionPreset() {
    _config['level'] = Level.WARN.name;
    _config['rotationCycle'] = RotationCycle.TWO_HOURS.value; // Every 2 hours
    _config['subjectPrefix'] = '[PRODUCTION LOG]';
    _config['sendAsHtml'] = true;
    _config['sendImmediatelyOnError'] = true;
    _config['immediateErrorThreshold'] = 10; // Send after 10 errors
    _config['attachLogFile'] = false;
    _config['maxInlineLines'] = 300;
    _config['includeStackTrace'] = true;
    _config['includeMetadata'] = true;
    _config['groupByLevel'] = false; // Chronological
    _config['maxEmailsPerHour'] = 20; // Standard limit
    return this;
  }

  // --- Build ---

  /// Builds the EmailAppender
  Future<EmailAppender> build({bool test = false, DateTime? date}) async {
    // Set defaults if not specified
    if (!_config.containsKey('filePattern')) {
      _config['filePattern'] = 'email_log';
    }

    if (!_config.containsKey('path')) {
      _config['path'] = 'email_logs/';
    }

    // Default rotation if not set
    if (!_config.containsKey('rotationCycle')) {
      _config['rotationCycle'] = RotationCycle.HOURLY.value;
    }

    // Validate required fields
    if (!_config.containsKey('smtpHost')) {
      throw ArgumentError('SMTP host is required. Use withSmtp() to set it.');
    }
    if (!_config.containsKey('smtpPort')) {
      throw ArgumentError('SMTP port is required. Use withSmtp() to set it.');
    }
    if (!_config.containsKey('fromEmail')) {
      throw ArgumentError('From email is required. Use withFrom() to set it.');
    }
    if (!_config.containsKey('toEmails')) {
      throw ArgumentError('To emails are required. Use withTo() to set them.');
    }

    return await EmailAppender.fromConfig(_config, test: test, date: date);
  }

  /// Creates a copy of this builder
  EmailAppenderBuilder copy() {
    final newBuilder = EmailAppenderBuilder();
    newBuilder._config.addAll(_config);
    return newBuilder;
  }

  /// Gets the current configuration
  Map<String, dynamic> getConfig() {
    return Map.unmodifiable(_config);
  }

  @override
  String toString() {
    return 'EmailAppenderBuilder(config: $_config)';
  }
}
