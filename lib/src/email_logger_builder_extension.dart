import 'package:any_logger/any_logger.dart';

/// Builder extension for EmailAppender
extension EmailLoggerBuilderExtension on LoggerBuilder {
  /// Adds an email appender to the logger configuration.
  LoggerBuilder email({
    required String smtpHost,
    required int smtpPort,
    required String fromEmail,
    required List<String> toEmails,
    String? fromName,
    String? username,
    String? password,
    bool ssl = false,
    bool allowInsecure = false,
    bool ignoreBadCertificate = false,
    List<String>? ccEmails,
    List<String>? bccEmails,
    String? replyTo,
    String subjectPrefix = '[LOG]',
    bool includeHostname = true,
    bool includeAppInfo = true,
    Level level = Level.ERROR,
    int batchSize = 50,
    int batchIntervalMinutes = 5,
    int maxEmailsPerHour = 20,
    bool sendAsHtml = true,
    bool includeStackTrace = true,
    bool includeMetadata = true,
    bool groupByLevel = true,
    bool sendImmediatelyOnError = true,
    int immediateErrorThreshold = 10,
    String format = Appender.defaultFormat,
    String dateFormat = Appender.defaultDateFormat,
  }) {
    final config = <String, dynamic>{
      'type': 'EMAIL',
      'smtpHost': smtpHost,
      'smtpPort': smtpPort,
      'fromEmail': fromEmail,
      'toEmails': toEmails,
      'ssl': ssl,
      'allowInsecure': allowInsecure,
      'ignoreBadCertificate': ignoreBadCertificate,
      'subjectPrefix': subjectPrefix,
      'includeHostname': includeHostname,
      'includeAppInfo': includeAppInfo,
      'level': level.name,
      'format': format,
      'dateFormat': dateFormat,
      'batchSize': batchSize,
      'batchIntervalMinutes': batchIntervalMinutes,
      'maxEmailsPerHour': maxEmailsPerHour,
      'sendAsHtml': sendAsHtml,
      'includeStackTrace': includeStackTrace,
      'includeMetadata': includeMetadata,
      'groupByLevel': groupByLevel,
      'sendImmediatelyOnError': sendImmediatelyOnError,
      'immediateErrorThreshold': immediateErrorThreshold,
    };

    if (fromName != null) config['fromName'] = fromName;
    if (username != null) config['username'] = username;
    if (password != null) config['password'] = password;
    if (ccEmails != null && ccEmails.isNotEmpty) config['ccEmails'] = ccEmails;
    if (bccEmails != null && bccEmails.isNotEmpty)
      config['bccEmails'] = bccEmails;
    if (replyTo != null) config['replyTo'] = replyTo;

    return addAppenderConfig(config);
  }

  /// Adds a Gmail email appender (convenience method).
  LoggerBuilder gmail({
    required String username,
    required String appPassword,
    required List<String> toEmails,
    String? fromName,
    Level level = Level.ERROR,
    String subjectPrefix = '[LOG]',
    int batchSize = 50,
    int batchIntervalMinutes = 5,
    bool sendAsHtml = true,
    bool includeStackTrace = true,
  }) {
    return email(
      smtpHost: 'smtp.gmail.com',
      smtpPort: 587,
      ssl: false,
      fromEmail: username,
      fromName: fromName,
      toEmails: toEmails,
      username: username,
      password: appPassword,
      level: level,
      subjectPrefix: subjectPrefix,
      batchSize: batchSize,
      batchIntervalMinutes: batchIntervalMinutes,
      sendAsHtml: sendAsHtml,
      includeStackTrace: includeStackTrace,
    );
  }

  /// Adds an Office 365 email appender (convenience method).
  LoggerBuilder office365({
    required String username,
    required String password,
    required List<String> toEmails,
    String? fromName,
    Level level = Level.ERROR,
    String subjectPrefix = '[LOG]',
    int batchSize = 50,
    int batchIntervalMinutes = 5,
    bool sendAsHtml = true,
    bool includeStackTrace = true,
  }) {
    return email(
      smtpHost: 'smtp.office365.com',
      smtpPort: 587,
      ssl: false,
      fromEmail: username,
      fromName: fromName,
      toEmails: toEmails,
      username: username,
      password: password,
      level: level,
      subjectPrefix: subjectPrefix,
      batchSize: batchSize,
      batchIntervalMinutes: batchIntervalMinutes,
      sendAsHtml: sendAsHtml,
      includeStackTrace: includeStackTrace,
    );
  }

  /// Adds a SendGrid email appender (convenience method).
  LoggerBuilder sendGrid({
    required String apiKey,
    required String fromEmail,
    required List<String> toEmails,
    String? fromName,
    Level level = Level.ERROR,
    String subjectPrefix = '[LOG]',
    int batchSize = 50,
    int batchIntervalMinutes = 5,
    bool sendAsHtml = true,
    bool includeStackTrace = true,
  }) {
    return email(
      smtpHost: 'smtp.sendgrid.net',
      smtpPort: 587,
      ssl: false,
      fromEmail: fromEmail,
      fromName: fromName,
      toEmails: toEmails,
      username: 'apikey',
      password: apiKey,
      level: level,
      subjectPrefix: subjectPrefix,
      batchSize: batchSize,
      batchIntervalMinutes: batchIntervalMinutes,
      sendAsHtml: sendAsHtml,
      includeStackTrace: includeStackTrace,
    );
  }
}
