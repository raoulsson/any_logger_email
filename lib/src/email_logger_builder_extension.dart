import 'package:any_logger/any_logger.dart';

import '../any_logger_email.dart';

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
    String? passwordOrApiKey,
    bool ssl = false,
    bool allowInsecure = false,
    bool ignoreBadCertificate = false,
    List<String>? ccEmails,
    List<String>? bccEmails,
    String? replyTo,
    String subjectPrefix = '[LOG]',
    bool includeHostname = true,
    bool includeAppInfo = true,
    Level level = Level.WARN,
    RotationCycle rotationCycle = RotationCycle.HOURLY, // Add rotation parameter
    String? attachmentFilePattern,
    bool useLocalTimeInSubject = true,
    int maxEmailsPerHour = 20,
    bool sendAsHtml = true,
    bool includeStackTrace = true,
    bool includeMetadata = true,
    bool groupByLevel = false,
    bool sendImmediatelyOnError = true,
    int immediateErrorThreshold = 10,
    String format = Appender.defaultFormat,
    String dateFormat = Appender.defaultDateFormat,
  }) {
    final config = <String, dynamic>{
      'type': EmailAppender.appenderName,
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
      'rotationCycle': rotationCycle.value, // Pass the rotation cycle
      'maxEmailsPerHour': maxEmailsPerHour,
      'sendAsHtml': sendAsHtml,
      'includeStackTrace': includeStackTrace,
      'includeMetadata': includeMetadata,
      'groupByLevel': groupByLevel,
      'sendImmediatelyOnError': sendImmediatelyOnError,
      'immediateErrorThreshold': immediateErrorThreshold,
      'useLocalTimeInSubject': useLocalTimeInSubject,
    };

    if (fromName != null) config['fromName'] = fromName;
    if (attachmentFilePattern != null) {
      config['attachmentFilePattern'] = attachmentFilePattern;
    }
    if (username != null) config['username'] = username;
    if (passwordOrApiKey != null) config['password'] = passwordOrApiKey;
    if (ccEmails != null && ccEmails.isNotEmpty) config['ccEmails'] = ccEmails;
    if (bccEmails != null && bccEmails.isNotEmpty) {
      config['bccEmails'] = bccEmails;
    }
    if (replyTo != null) config['replyTo'] = replyTo;

    return addAppenderConfig(config);
  }

  /// Adds a Gmail email appender using app-specific password.
  LoggerBuilder gmailWithAppPassword({
    required String fromEmail,
    required String appPassword,
    required List<String> toEmails,
    String? fromName,
    Level level = Level.WARN,
    String subjectPrefix = '[LOG]',
    RotationCycle rotationCycle = RotationCycle.HOURLY, // Add rotation parameter
    bool sendAsHtml = true,
    bool includeStackTrace = true,
    bool sendImmediatelyOnError = true,
    int immediateErrorThreshold = 10,
    String? attachmentFilePattern,
    bool useLocalTimeInSubject = true,
  }) {
    return email(
      smtpHost: 'smtp.gmail.com',
      smtpPort: 587,
      ssl: false,
      fromEmail: fromEmail,
      fromName: fromName,
      toEmails: toEmails,
      username: fromEmail,
      passwordOrApiKey: appPassword,
      level: level,
      subjectPrefix: subjectPrefix,
      rotationCycle: rotationCycle,
      // Pass the rotation cycle
      sendAsHtml: sendAsHtml,
      includeStackTrace: includeStackTrace,
      sendImmediatelyOnError: sendImmediatelyOnError,
      immediateErrorThreshold: immediateErrorThreshold,
      attachmentFilePattern: attachmentFilePattern,
      useLocalTimeInSubject: useLocalTimeInSubject,
    );
  }

  /// Adds an Outlook/Office 365 email appender using app-specific password.
  LoggerBuilder outlookWithAppPassword({
    required String fromEmail,
    required String appPassword,
    required List<String> toEmails,
    String? fromName,
    Level level = Level.WARN,
    String subjectPrefix = '[LOG]',
    RotationCycle rotationCycle = RotationCycle.HOURLY, // Add rotation parameter
    bool sendAsHtml = true,
    bool includeStackTrace = true,
    bool sendImmediatelyOnError = true,
    int immediateErrorThreshold = 10,
    String? attachmentFilePattern,
    bool useLocalTimeInSubject = true,
  }) {
    return email(
      smtpHost: 'smtp.office365.com',
      smtpPort: 587,
      ssl: false,
      fromEmail: fromEmail,
      fromName: fromName,
      toEmails: toEmails,
      username: fromEmail,
      passwordOrApiKey: appPassword,
      level: level,
      subjectPrefix: subjectPrefix,
      rotationCycle: rotationCycle,
      // Pass the rotation cycle
      sendAsHtml: sendAsHtml,
      includeStackTrace: includeStackTrace,
      sendImmediatelyOnError: sendImmediatelyOnError,
      immediateErrorThreshold: immediateErrorThreshold,
      attachmentFilePattern: attachmentFilePattern,
      useLocalTimeInSubject: useLocalTimeInSubject,
    );
  }

  /// Adds a SendGrid email appender using API key.
  LoggerBuilder sendGridWithApiKey({
    required String apiKey,
    required String fromEmail,
    required List<String> toEmails,
    String? fromName,
    Level level = Level.WARN,
    String subjectPrefix = '[LOG]',
    RotationCycle rotationCycle = RotationCycle.HOURLY, // Add rotation parameter
    bool sendAsHtml = true,
    bool includeStackTrace = true,
    bool sendImmediatelyOnError = true,
    int immediateErrorThreshold = 10,
    String? attachmentFilePattern,
    bool useLocalTimeInSubject = true,
  }) {
    return email(
      smtpHost: 'smtp.sendgrid.net',
      smtpPort: 587,
      ssl: false,
      fromEmail: fromEmail,
      fromName: fromName,
      toEmails: toEmails,
      username: 'apikey',
      passwordOrApiKey: apiKey,
      level: level,
      subjectPrefix: subjectPrefix,
      rotationCycle: rotationCycle,
      // Pass the rotation cycle
      sendAsHtml: sendAsHtml,
      includeStackTrace: includeStackTrace,
      sendImmediatelyOnError: sendImmediatelyOnError,
      immediateErrorThreshold: immediateErrorThreshold,
      attachmentFilePattern: attachmentFilePattern,
      useLocalTimeInSubject: useLocalTimeInSubject,
    );
  }

  /// Adds a Mailgun email appender using API key.
  LoggerBuilder mailgunWithApiKey({
    required String apiKey,
    required String domain,
    required String fromEmail,
    required List<String> toEmails,
    String? fromName,
    Level level = Level.WARN,
    String subjectPrefix = '[LOG]',
    RotationCycle rotationCycle = RotationCycle.HOURLY, // Add rotation parameter
    bool sendAsHtml = true,
    bool includeStackTrace = true,
    bool sendImmediatelyOnError = true,
    int immediateErrorThreshold = 10,
    String? attachmentFilePattern,
    bool useLocalTimeInSubject = true,
  }) {
    return email(
      smtpHost: 'smtp.mailgun.org',
      smtpPort: 587,
      ssl: false,
      fromEmail: fromEmail,
      fromName: fromName,
      toEmails: toEmails,
      username: 'postmaster@$domain',
      passwordOrApiKey: apiKey,
      level: level,
      subjectPrefix: subjectPrefix,
      rotationCycle: rotationCycle,
      // Pass the rotation cycle
      sendAsHtml: sendAsHtml,
      includeStackTrace: includeStackTrace,
      sendImmediatelyOnError: sendImmediatelyOnError,
      immediateErrorThreshold: immediateErrorThreshold,
      attachmentFilePattern: attachmentFilePattern,
      useLocalTimeInSubject: useLocalTimeInSubject,
    );
  }
}
