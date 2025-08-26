import 'package:any_logger/any_logger.dart';

import 'email_appender.dart';

/// A specialized builder for creating and configuring [EmailAppender] instances.
///
/// This builder provides a fluent API specifically tailored for email appenders,
/// with all relevant configuration options exposed.
///
/// ### Example Usage:
///
/// ```dart
/// // Simple email appender
/// final appender = await emailAppenderBuilder()
///     .withSmtp('smtp.gmail.com', 587)
///     .withCredentials('user@gmail.com', 'app-password')
///     .withFrom('logger@example.com')
///     .withTo(['admin@example.com'])
///     .withLevel(Level.ERROR)
///     .build();
///
/// // With multiple recipients and HTML formatting
/// final htmlAppender = await emailAppenderBuilder()
///     .withSmtp('mail.example.com', 465, ssl: true)
///     .withCredentials('logger@example.com', 'password')
///     .withFrom('app@example.com', 'My App Logger')
///     .withTo(['dev-team@example.com'])
///     .withCc(['manager@example.com'])
///     .withHtmlFormat(true)
///     .withSubjectPrefix('[PROD ERROR]')
///     .build();
/// ```

/// Convenience factory function for creating an EmailAppenderBuilder.
EmailAppenderBuilder emailAppenderBuilder() => EmailAppenderBuilder();

class EmailAppenderBuilder {
  final Map<String, dynamic> _config = {
    'type': EmailAppender.appenderName,
  };

  /// Creates a new EmailAppenderBuilder.
  EmailAppenderBuilder();

  // --- SMTP Configuration ---

  /// Sets the SMTP server configuration.
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
  EmailAppenderBuilder withCredentials(String username, String password) {
    _config['username'] = username;
    _config['password'] = password;
    return this;
  }

  // --- Email Configuration ---

  /// Sets the sender email address and optional name.
  EmailAppenderBuilder withFrom(String email, [String? name]) {
    _config['fromEmail'] = email;
    if (name != null) {
      _config['fromName'] = name;
    }
    return this;
  }

  /// Sets the recipient email addresses.
  EmailAppenderBuilder withTo(List<String> emails) {
    _config['toEmails'] = emails;
    return this;
  }

  /// Sets a single recipient email address.
  EmailAppenderBuilder withSingleTo(String email) {
    _config['toEmails'] = [email];
    return this;
  }

  /// Sets CC (carbon copy) recipients.
  EmailAppenderBuilder withCc(List<String> emails) {
    _config['ccEmails'] = emails;
    return this;
  }

  /// Sets BCC (blind carbon copy) recipients.
  EmailAppenderBuilder withBcc(List<String> emails) {
    _config['bccEmails'] = emails;
    return this;
  }

  /// Sets the reply-to email address.
  EmailAppenderBuilder withReplyTo(String email) {
    _config['replyTo'] = email;
    return this;
  }

  /// Sets the subject line prefix.
  EmailAppenderBuilder withSubjectPrefix(String prefix) {
    _config['subjectPrefix'] = prefix;
    return this;
  }

  // --- Common Appender Properties ---

  /// Sets the logging [Level] for this appender.
  EmailAppenderBuilder withLevel(Level level) {
    _config['level'] = level.name;
    return this;
  }

  /// Sets the log message format pattern.
  EmailAppenderBuilder withFormat(String format) {
    _config['format'] = format;
    return this;
  }

  /// Sets the date format pattern for timestamps.
  EmailAppenderBuilder withDateFormat(String dateFormat) {
    _config['dateFormat'] = dateFormat;
    return this;
  }

  /// Sets whether this appender starts enabled.
  EmailAppenderBuilder withEnabledState(bool enabled) {
    _config['enabled'] = enabled;
    return this;
  }

  // --- Batching Configuration ---

  /// Sets the batch size (number of logs before sending).
  EmailAppenderBuilder withBatchSize(int size) {
    _config['batchSize'] = size;
    return this;
  }

  /// Sets the batch interval in minutes.
  EmailAppenderBuilder withBatchIntervalMinutes(int minutes) {
    _config['batchIntervalMinutes'] = minutes;
    return this;
  }

  /// Sets the batch interval.
  EmailAppenderBuilder withBatchInterval(Duration interval) {
    _config['batchIntervalMinutes'] = interval.inMinutes;
    return this;
  }

  // --- Rate Limiting ---

  /// Sets the maximum number of emails per hour.
  EmailAppenderBuilder withRateLimit(int maxEmailsPerHour) {
    _config['maxEmailsPerHour'] = maxEmailsPerHour;
    return this;
  }

  // --- Formatting Options ---

  /// Sets whether to send emails as HTML.
  EmailAppenderBuilder withHtmlFormat(bool sendAsHtml) {
    _config['sendAsHtml'] = sendAsHtml;
    return this;
  }

  /// Sets whether to include stack traces.
  EmailAppenderBuilder withStackTraces(bool include) {
    _config['includeStackTrace'] = include;
    return this;
  }

  /// Sets whether to include metadata (hostname, app info).
  EmailAppenderBuilder withMetadata(bool include) {
    _config['includeMetadata'] = include;
    return this;
  }

  /// Sets whether to include hostname in subject and body.
  EmailAppenderBuilder withHostname(bool include) {
    _config['includeHostname'] = include;
    return this;
  }

  /// Sets whether to include app version and device ID.
  EmailAppenderBuilder withAppInfo(bool include) {
    _config['includeAppInfo'] = include;
    return this;
  }

  /// Sets whether to group logs by level in the email body.
  EmailAppenderBuilder withGroupByLevel(bool group) {
    _config['groupByLevel'] = group;
    return this;
  }

  /// Sets a custom email template.
  EmailAppenderBuilder withTemplate(String template) {
    _config['emailTemplate'] = template;
    return this;
  }

  // --- Priority Settings ---

  /// Sets whether to send immediately on error.
  EmailAppenderBuilder withImmediateErrors(bool sendImmediately) {
    _config['sendImmediatelyOnError'] = sendImmediately;
    return this;
  }

  /// Sets the threshold for immediate error sending.
  EmailAppenderBuilder withErrorThreshold(int threshold) {
    _config['immediateErrorThreshold'] = threshold;
    return this;
  }

  // --- Preset Configurations ---

  /// Applies settings optimized for Gmail SMTP.
  EmailAppenderBuilder withGmailPreset(String username, String appPassword) {
    _config['smtpHost'] = 'smtp.gmail.com';
    _config['smtpPort'] = 587;
    _config['ssl'] = false;
    _config['username'] = username;
    _config['password'] = appPassword;
    _config['fromEmail'] = username;
    return this;
  }

  /// Applies settings optimized for Office 365 SMTP.
  EmailAppenderBuilder withOffice365Preset(String username, String password) {
    _config['smtpHost'] = 'smtp.office365.com';
    _config['smtpPort'] = 587;
    _config['ssl'] = false;
    _config['username'] = username;
    _config['password'] = password;
    _config['fromEmail'] = username;
    return this;
  }

  /// Applies settings optimized for SendGrid SMTP.
  EmailAppenderBuilder withSendGridPreset(String apiKey) {
    _config['smtpHost'] = 'smtp.sendgrid.net';
    _config['smtpPort'] = 587;
    _config['ssl'] = false;
    _config['username'] = 'apikey';
    _config['password'] = apiKey;
    return this;
  }

  /// Applies settings optimized for critical error alerts.
  EmailAppenderBuilder withCriticalAlertPreset() {
    _config['level'] = Level.ERROR.name;
    _config['batchSize'] = 5;
    _config['batchIntervalMinutes'] = 1;
    _config['sendImmediatelyOnError'] = true;
    _config['immediateErrorThreshold'] = 1;
    _config['includeStackTrace'] = true;
    _config['includeMetadata'] = true;
    _config['subjectPrefix'] = '[CRITICAL ALERT]';
    _config['sendAsHtml'] = true;
    return this;
  }

  /// Applies settings optimized for daily digest emails.
  EmailAppenderBuilder withDailyDigestPreset() {
    _config['level'] = Level.INFO.name;
    _config['batchSize'] = 1000;
    _config['batchIntervalMinutes'] = 1440; // 24 hours
    _config['sendImmediatelyOnError'] = false;
    _config['groupByLevel'] = true;
    _config['includeStackTrace'] = false;
    _config['sendAsHtml'] = true;
    return this;
  }

  /// Applies settings optimized for development notifications.
  EmailAppenderBuilder withDevelopmentPreset() {
    _config['level'] = Level.DEBUG.name;
    _config['batchSize'] = 20;
    _config['batchIntervalMinutes'] = 5;
    _config['includeStackTrace'] = true;
    _config['includeMetadata'] = true;
    _config['groupByLevel'] = true;
    _config['sendAsHtml'] = true;
    return this;
  }

  // --- Build Methods ---

  /// Builds the email appender asynchronously.
  ///
  /// Returns a fully configured [EmailAppender] instance.
  Future<EmailAppender> build({bool test = false, DateTime? date}) async {
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

  /// Creates a copy of this builder with the same configuration.
  EmailAppenderBuilder copy() {
    final newBuilder = EmailAppenderBuilder();
    newBuilder._config.addAll(_config);
    return newBuilder;
  }

  /// Gets the current configuration as a Map.
  Map<String, dynamic> getConfig() {
    return Map.unmodifiable(_config);
  }

  @override
  String toString() {
    return 'EmailAppenderBuilder(config: $_config)';
  }
}
