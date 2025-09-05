import 'package:any_logger/any_logger.dart';
import 'package:any_logger_email/any_logger_email.dart';

/// Example configurations for Email appender
///
/// These examples demonstrate various configuration options
/// without actually sending emails.
void main() async {
  // Ensure the EMAIL appender is registered
  AnyLoggerEmailExtension.register();

  print('Email Appender Configuration Examples\n');
  print('=' * 50);

  // Example 1: Basic configuration
  example1_basicConfig();

  // Example 2: Popular email services
  example2_emailServices();

  // Example 3: Advanced configuration
  example3_advanced();

  // Example 4: Using the builder pattern
  await example4_builder();

  // Example 5: Integration with LoggerFactory
  await example5_loggerFactory();

  print('\n' + '=' * 50);
  print('Examples completed (no actual emails sent)');
}

/// Example 1: Basic Email configuration
void example1_basicConfig() {
  print('\n### Example 1: Basic Configuration ###\n');

  final config = {
    'type': 'EMAIL',
    'smtpHost': 'smtp.example.com',
    'smtpPort': 587,
    'fromEmail': 'logger@example.com',
    'toEmails': ['admin@example.com', 'dev@example.com'],
    'username': 'logger@example.com',
    'password': 'secure_password',
    'level': 'ERROR',
    'batchSize': 50,
    'batchIntervalMinutes': 5,
  };

  print('Basic config:');
  config.forEach((key, value) {
    if (key == 'password') {
      print('  $key: ******');
    } else if (value is List) {
      print('  $key: ${(value).join(", ")}');
    } else {
      print('  $key: $value');
    }
  });

  // With SSL/TLS
  final sslConfig = {
    'type': 'EMAIL',
    'smtpHost': 'secure.mailserver.com',
    'smtpPort': 465,
    'ssl': true,
    'fromEmail': 'noreply@example.com',
    'fromName': 'App Logger',
    'toEmails': 'support@example.com', // Can be string or list
    'level': 'WARN',
  };

  print('\nSSL/TLS config:');
  sslConfig.forEach((key, value) => print('  $key: $value'));
}

/// Example 2: Popular email service configurations
void example2_emailServices() {
  print('\n### Example 2: Popular Email Services ###\n');

  // Gmail configuration
  final gmailConfig = {
    'type': 'EMAIL',
    'smtpHost': 'smtp.gmail.com',
    'smtpPort': 587,
    'ssl': false,
    'fromEmail': 'your.app@gmail.com',
    'toEmails': ['admin@example.com'],
    'username': 'your.app@gmail.com',
    'password': 'app-specific-password',
    // Use app password, not regular password
    'level': 'ERROR',
    'subjectPrefix': '[MyApp Error]',
  };

  print('Gmail config:');
  gmailConfig.forEach((key, value) {
    if (key == 'password') {
      print('  $key: ${value.toString().substring(0, 3)}...');
    } else {
      print('  $key: $value');
    }
  });

  // Office 365 configuration
  final office365Config = {
    'type': 'EMAIL',
    'smtpHost': 'smtp.office365.com',
    'smtpPort': 587,
    'ssl': false,
    'fromEmail': 'logger@company.com',
    'toEmails': ['it-team@company.com'],
    'username': 'logger@company.com',
    'password': 'secure_password',
    'level': 'ERROR',
  };

  print('\nOffice 365 config:');
  office365Config.forEach((key, value) {
    if (key == 'password') {
      print('  $key: ******');
    } else {
      print('  $key: $value');
    }
  });

  // SendGrid configuration
  final sendGridConfig = {
    'type': 'EMAIL',
    'smtpHost': 'smtp.sendgrid.net',
    'smtpPort': 587,
    'fromEmail': 'alerts@myapp.com',
    'toEmails': ['ops@myapp.com'],
    'username': 'apikey', // Always 'apikey' for SendGrid
    'password': 'SG.actual_api_key_here',
    'level': 'ERROR',
  };

  print('\nSendGrid config:');
  sendGridConfig.forEach((key, value) {
    if (key == 'password') {
      print('  $key: SG.***');
    } else {
      print('  $key: $value');
    }
  });
}

/// Example 3: Advanced configuration with all options
void example3_advanced() {
  print('\n### Example 3: Advanced Configuration ###\n');

  final advancedConfig = {
    'type': 'EMAIL',
    'smtpHost': 'mail.enterprise.com',
    'smtpPort': 587,
    'ssl': false,
    'allowInsecure': false,
    'ignoreBadCertificate': false,
    'fromEmail': 'monitoring@enterprise.com',
    'fromName': 'System Monitor',
    'toEmails': ['devops@enterprise.com', 'cto@enterprise.com'],
    'ccEmails': ['manager@enterprise.com'],
    'bccEmails': ['archive@enterprise.com'],
    'replyTo': 'support@enterprise.com',
    'username': 'monitoring@enterprise.com',
    'password': 'secure_password',
    'level': 'WARN',
    'subjectPrefix': '[PROD-ALERT]',
    'includeHostname': true,
    'includeAppInfo': true,
    'batchSize': 25,
    'batchIntervalMinutes': 10,
    'maxEmailsPerHour': 30,
    'sendAsHtml': true,
    'includeStackTrace': true,
    'includeMetadata': true,
    'groupByLevel': true,
    'sendImmediatelyOnError': true,
    'immediateErrorThreshold': 5,
  };

  print('Advanced configuration:');
  advancedConfig.forEach((key, value) {
    if (key == 'password') {
      print('  $key: ******');
    } else if (value is List) {
      print('  $key: ${(value).join(", ")}');
    } else {
      print('  $key: $value');
    }
  });

  // Configuration for daily digest
  final digestConfig = {
    'type': 'EMAIL',
    'smtpHost': 'smtp.example.com',
    'smtpPort': 587,
    'fromEmail': 'reports@example.com',
    'toEmails': ['management@example.com'],
    'level': 'INFO',
    'subjectPrefix': '[Daily Log Digest]',
    'batchSize': 1000,
    'batchIntervalMinutes': 1440, // 24 hours
    'sendImmediatelyOnError': false, // Collect all logs for digest
    'groupByLevel': true,
    'includeStackTrace': false, // Reduce size for digest
    'sendAsHtml': true,
  };

  print('\nDaily digest configuration:');
  digestConfig.forEach((key, value) {
    if (value is List) {
      print('  $key: ${(value).join(", ")}');
    } else {
      print('  $key: $value');
    }
  });
}

/// Example 4: Using the builder pattern
Future<void> example4_builder() async {
  print('\n### Example 4: Builder Pattern ###\n');

  // Create appender using builder (in test mode)
  final appender = await emailAppenderBuilder()
      .withSmtp('smtp.gmail.com', 587)
      .withCredentials('app@gmail.com', 'app-password')
      .withFrom('app@gmail.com', 'My App')
      .withTo(['admin@example.com', 'dev@example.com'])
      .withCc(['manager@example.com'])
      .withLevel(Level.ERROR)
      .withSubjectPrefix('[APP ERROR]')
      .withHtmlFormat(true)
      .withStackTraces(true)
      .withMetadata(true)
      .withGroupByLevel(true)
      .withImmediateErrors(true)
      .withErrorThreshold(3)
      .build(test: true);

  print('Built appender with:');
  print('  SMTP: ${appender.smtpHost}:${appender.smtpPort}');
  print('  From: ${appender.fromEmail}');
  print('  To: ${appender.toEmails.join(", ")}');
  print('  Level: ${appender.level}');
  print('  Batch interval: ${appender.batchInterval}');
  print('  HTML format: ${appender.sendAsHtml}');

  // Using presets
  final gmailAppender = await emailAppenderBuilder()
      .withGmailAppPassword('user@gmail.com', 'app-password')
      .withTo(['alerts@example.com'])
      .withCriticalAlertPreset()
      .build(test: true);

  print('\nGmail with critical alert preset:');
  print('  SMTP: ${gmailAppender.smtpHost}:${gmailAppender.smtpPort}');
  print('  Subject prefix: ${gmailAppender.subjectPrefix}');
  print('  Send immediately on error: ${gmailAppender.sendImmediatelyOnError}');

  await appender.dispose();
  await gmailAppender.dispose();
}

/// Example 5: Integration with LoggerFactory
Future<void> example5_loggerFactory() async {
  print('\n### Example 5: LoggerFactory Integration ###\n');

  // Configuration-based setup
  final config = {
    'appenders': [
      {
        'type': 'CONSOLE',
        'level': 'INFO',
        'format': '[%l] %m',
      },
      {
        'type': 'EMAIL',
        'smtpHost': 'smtp.example.com',
        'smtpPort': 587,
        'fromEmail': 'logger@example.com',
        'toEmails': ['admin@example.com'],
        'username': 'logger@example.com',
        'password': 'password',
        'level': 'ERROR',
        'batchSize': 10,
        'batchIntervalMinutes': 5,
        'sendAsHtml': true,
      }
    ]
  };

  print('LoggerFactory configuration:');
  final appenders = config['appenders'] as List<Map<String, dynamic>>;
  print('  Appenders: ${appenders.length}');
  for (var i = 0; i < appenders.length; i++) {
    final appender = appenders[i];
    print('    ${i + 1}. Type: ${appender['type']}, Level: ${appender['level']}');
  }

  // Initialize in test mode to avoid actual email connections
  await LoggerFactory.init(config, test: true);

  // Get the logger and check appenders
  final logger = LoggerFactory.getRootLogger();
  print('\nLogger configured with ${logger.appenders.length} appenders:');
  for (var appender in logger.appenders) {
    print('  - ${appender.getType()} (Level: ${appender.level})');
  }

  // Clean up
  await LoggerFactory.dispose();

  // Builder-based setup with Gmail
  print('\nUsing LoggerBuilder with Gmail:');
  await LoggerFactory.builder()
      .replaceAll()
      .console(level: Level.INFO)
      .gmailWithAppPassword(
        fromEmail: 'app@gmail.com',
        appPassword: 'app-password',
        toEmails: ['alerts@example.com'],
        level: Level.WARN,
        subjectPrefix: '[MyApp]',
        rotationCycle: RotationCycle.HOURLY,
      )
      .build(test: true);

  final logger2 = LoggerFactory.getRootLogger();
  print('Builder created ${logger2.appenders.length} appenders');

  await LoggerFactory.dispose();

  // Using presets
  print('\nUsing production preset with email:');
  final prodConfig = EmailPresets.productionWithEmail(
    smtpHost: 'smtp.example.com',
    smtpPort: 587,
    fromEmail: 'prod@example.com',
    toEmails: ['ops@example.com'],
    username: 'prod@example.com',
    password: 'secure_password',
  );

  await LoggerFactory.init(prodConfig, test: true);
  final logger3 = LoggerFactory.getRootLogger();
  print('Production preset created ${logger3.appenders.length} appenders');

  await LoggerFactory.dispose();
}
