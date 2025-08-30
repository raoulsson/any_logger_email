import 'package:any_logger/any_logger.dart';
import 'package:any_logger_email/any_logger_email.dart';
import 'package:test/test.dart';

void main() {
  // Ensure the EMAIL appender is registered before all tests
  setUpAll(() {
    AnyLoggerEmailExtension.register();
  });

  group('EmailAppender Configuration', () {
    tearDown(() async {
      await LoggerFactory.dispose();
    });

    test('should create appender from config', () async {
      final config = {
        'type': 'EMAIL',
        'smtpHost': 'smtp.test.com',
        'smtpPort': 587,
        'fromEmail': 'test@example.com',
        'toEmails': ['admin@example.com'],
        'level': 'ERROR',
        'batchSize': 50,
        'batchIntervalMinutes': 5,
      };

      final appender = await EmailAppender.fromConfig(config, test: true);

      expect(appender.getType(), equals('EMAIL'));
      expect(appender.smtpHost, equals('smtp.test.com'));
      expect(appender.smtpPort, equals(587));
      expect(appender.fromEmail, equals('test@example.com'));
      expect(appender.toEmails, equals(['admin@example.com']));
      expect(appender.level, equals(Level.ERROR));
      expect(appender.batchSize, equals(50));
      expect(appender.batchInterval, equals(Duration(minutes: 5)));
    });

    test('should handle toEmails as string or list', () async {
      // String format (comma-separated)
      final stringConfig = {
        'type': 'EMAIL',
        'smtpHost': 'smtp.test.com',
        'smtpPort': 587,
        'fromEmail': 'test@example.com',
        'toEmails': 'admin@example.com, dev@example.com, support@example.com',
      };

      final stringAppender = await EmailAppender.fromConfig(stringConfig, test: true);
      expect(stringAppender.toEmails, equals(['admin@example.com', 'dev@example.com', 'support@example.com']));

      // List format
      final listConfig = {
        'type': 'EMAIL',
        'smtpHost': 'smtp.test.com',
        'smtpPort': 587,
        'fromEmail': 'test@example.com',
        'toEmails': ['admin@example.com', 'dev@example.com'],
      };

      final listAppender = await EmailAppender.fromConfig(listConfig, test: true);
      expect(listAppender.toEmails, equals(['admin@example.com', 'dev@example.com']));
    });

    test('should configure SMTP settings correctly', () async {
      final config = {
        'type': 'EMAIL',
        'smtpHost': 'secure.mail.com',
        'smtpPort': 465,
        'ssl': true,
        'allowInsecure': false,
        'ignoreBadCertificate': true,
        'fromEmail': 'test@example.com',
        'toEmails': ['admin@example.com'],
        'username': 'user',
        'password': 'pass',
      };

      final appender = await EmailAppender.fromConfig(config, test: true);
      expect(appender.ssl, equals(true));
      expect(appender.allowInsecure, equals(false));
      expect(appender.ignoreBadCertificate, equals(true));
      expect(appender.username, equals('user'));
      expect(appender.password, equals('pass'));
    });

    test('should configure email recipients correctly', () async {
      final config = {
        'type': 'EMAIL',
        'smtpHost': 'smtp.test.com',
        'smtpPort': 587,
        'fromEmail': 'test@example.com',
        'fromName': 'Test Logger',
        'toEmails': ['to@example.com'],
        'ccEmails': ['cc1@example.com', 'cc2@example.com'],
        'bccEmails': 'bcc@example.com',
        'replyTo': 'reply@example.com',
      };

      final appender = await EmailAppender.fromConfig(config, test: true);
      expect(appender.fromName, equals('Test Logger'));
      expect(appender.ccEmails, equals(['cc1@example.com', 'cc2@example.com']));
      expect(appender.bccEmails, equals(['bcc@example.com']));
      expect(appender.replyTo, equals('reply@example.com'));
    });

    test('should throw on missing required fields', () {
      // Missing smtpHost
      expect(
        () async => await EmailAppender.fromConfig({
          'type': 'EMAIL',
          'smtpPort': 587,
          'fromEmail': 'test@example.com',
          'toEmails': ['admin@example.com'],
        }),
        throwsA(isA<ArgumentError>()),
      );

      // Missing smtpPort
      expect(
        () async => await EmailAppender.fromConfig({
          'type': 'EMAIL',
          'smtpHost': 'smtp.test.com',
          'fromEmail': 'test@example.com',
          'toEmails': ['admin@example.com'],
        }),
        throwsA(isA<ArgumentError>()),
      );

      // Missing fromEmail
      expect(
        () async => await EmailAppender.fromConfig({
          'type': 'EMAIL',
          'smtpHost': 'smtp.test.com',
          'smtpPort': 587,
          'toEmails': ['admin@example.com'],
        }),
        throwsA(isA<ArgumentError>()),
      );

      // Missing toEmails
      expect(
        () async => await EmailAppender.fromConfig({
          'type': 'EMAIL',
          'smtpHost': 'smtp.test.com',
          'smtpPort': 587,
          'fromEmail': 'test@example.com',
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw for synchronous factory', () {
      final config = {
        'type': 'EMAIL',
        'smtpHost': 'smtp.test.com',
        'smtpPort': 587,
        'fromEmail': 'test@example.com',
        'toEmails': ['admin@example.com'],
      };

      expect(
        () => EmailAppender.fromConfigSync(config),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('EmailAppender Batching', () {
    late EmailAppender appender;

    tearDown(() async {
      await appender.dispose();
      await LoggerFactory.dispose();
    });

    test('should batch logs until batch size reached', () async {
      appender = await EmailAppender.fromConfig({
        'smtpHost': 'smtp.test.com',
        'smtpPort': 587,
        'fromEmail': 'test@example.com',
        'toEmails': ['admin@example.com'],
        'batchSize': 3,
        'batchIntervalMinutes': 60,
      }, test: true);

      final contextInfo = LoggerStackTrace.from(StackTrace.current);

      // Add logs but don't reach batch size
      appender.append(LogRecord(Level.INFO, 'Message 1', null, contextInfo));
      appender.append(LogRecord(Level.INFO, 'Message 2', null, contextInfo));

      // Buffer should have 2 items
      expect(appender.getStatistics()['bufferSize'], equals(2));

      // Add one more to trigger batch
      appender.append(LogRecord(Level.INFO, 'Message 3', null, contextInfo));

      // In test mode, buffer is cleared after batch
      expect(appender.getStatistics()['bufferSize'], equals(0));
    });

    test('should send immediately for error threshold', () async {
      appender = await EmailAppender.fromConfig({
        'smtpHost': 'smtp.test.com',
        'smtpPort': 587,
        'fromEmail': 'test@example.com',
        'toEmails': ['admin@example.com'],
        'batchSize': 100,
        'sendImmediatelyOnError': true,
        'immediateErrorThreshold': 5,
      }, test: true);

      final contextInfo = LoggerStackTrace.from(StackTrace.current);

      // Add less than threshold - should not send
      for (int i = 0; i < 4; i++) {
        appender.append(LogRecord(Level.ERROR, 'Error $i', null, contextInfo));
      }
      expect(appender.getStatistics()['bufferSize'], equals(4));

      // Add one more to reach threshold - should send
      appender.append(LogRecord(Level.ERROR, 'Error 5', null, contextInfo));

      // Should send immediately when threshold reached
      expect(appender.getStatistics()['bufferSize'], equals(0));
    });

    test('should flush on dispose', () async {
      appender = await EmailAppender.fromConfig({
        'smtpHost': 'smtp.test.com',
        'smtpPort': 587,
        'fromEmail': 'test@example.com',
        'toEmails': ['admin@example.com'],
        'batchSize': 100,
      }, test: true);

      final contextInfo = LoggerStackTrace.from(StackTrace.current);

      // Add some logs
      appender.append(LogRecord(Level.INFO, 'Message 1', null, contextInfo));
      appender.append(LogRecord(Level.INFO, 'Message 2', null, contextInfo));

      expect(appender.getStatistics()['bufferSize'], equals(2));

      // Dispose should flush
      await appender.dispose();
      expect(appender.getStatistics()['bufferSize'], equals(0));
    });
  });

  group('EmailAppender Rate Limiting', () {
    test('should track rate limit correctly', () async {
      final appender = await EmailAppender.fromConfig({
        'smtpHost': 'smtp.test.com',
        'smtpPort': 587,
        'fromEmail': 'test@example.com',
        'toEmails': ['admin@example.com'],
        'maxEmailsPerHour': 10,
      }, test: true);

      final stats = appender.getStatistics();
      expect(stats['rateLimitRemaining'], equals(10));

      await appender.dispose();
    });

    test('should configure formatting options', () async {
      final appender = await EmailAppender.fromConfig({
        'smtpHost': 'smtp.test.com',
        'smtpPort': 587,
        'fromEmail': 'test@example.com',
        'toEmails': ['admin@example.com'],
        'sendAsHtml': false,
        'includeStackTrace': false,
        'includeMetadata': false,
        'groupByLevel': false,
        'includeHostname': false,
        'includeAppInfo': false,
        'subjectPrefix': '[TEST]',
      }, test: true);

      expect(appender.sendAsHtml, equals(false));
      expect(appender.includeStackTrace, equals(false));
      expect(appender.includeMetadata, equals(false));
      expect(appender.groupByLevel, equals(false));
      expect(appender.includeHostname, equals(false));
      expect(appender.includeAppInfo, equals(false));
      expect(appender.subjectPrefix, equals('[TEST]'));

      await appender.dispose();
    });
  });

  group('EmailAppenderBuilder', () {
    tearDown(() async {
      await LoggerFactory.dispose();
    });

    test('should build with basic configuration', () async {
      final appender = await emailAppenderBuilder()
          .withSmtp('smtp.test.com', 587)
          .withFrom('test@example.com')
          .withTo(['admin@example.com'])
          .withLevel(Level.WARN)
          .withBatchSize(25)
          .build(test: true);

      expect(appender.smtpHost, equals('smtp.test.com'));
      expect(appender.smtpPort, equals(587));
      expect(appender.fromEmail, equals('test@example.com'));
      expect(appender.toEmails, equals(['admin@example.com']));
      expect(appender.level, equals(Level.WARN));
      expect(appender.batchSize, equals(25));

      await appender.dispose();
    });

    test('should build with credentials', () async {
      final appender = await emailAppenderBuilder()
          .withSmtp('smtp.test.com', 587)
          .withCredentials('user', 'pass')
          .withFrom('test@example.com')
          .withTo(['admin@example.com']).build(test: true);

      expect(appender.username, equals('user'));
      expect(appender.password, equals('pass'));

      await appender.dispose();
    });

    test('should apply Gmail preset correctly', () async {
      final appender = await emailAppenderBuilder()
          .withGmailPreset('user@gmail.com', 'app-password')
          .withTo(['admin@example.com']).build(test: true);

      expect(appender.smtpHost, equals('smtp.gmail.com'));
      expect(appender.smtpPort, equals(587));
      expect(appender.ssl, equals(false));
      expect(appender.username, equals('user@gmail.com'));
      expect(appender.password, equals('app-password'));
      expect(appender.fromEmail, equals('user@gmail.com'));

      await appender.dispose();
    });

    test('should apply critical alert preset correctly', () async {
      final appender = await emailAppenderBuilder()
          .withSmtp('smtp.test.com', 587)
          .withFrom('test@example.com')
          .withTo(['admin@example.com'])
          .withCriticalAlertPreset()
          .build(test: true);

      expect(appender.level, equals(Level.ERROR));
      expect(appender.batchSize, equals(5));
      expect(appender.batchInterval, equals(Duration(minutes: 1)));
      expect(appender.sendImmediatelyOnError, equals(true));
      expect(appender.immediateErrorThreshold, equals(1));
      expect(appender.subjectPrefix, equals('[CRITICAL ALERT]'));

      await appender.dispose();
    });

    test('should throw if required fields are missing', () async {
      // Missing SMTP host
      expect(
        () async => await emailAppenderBuilder().withFrom('test@example.com').withTo(['admin@example.com']).build(),
        throwsA(isA<ArgumentError>()),
      );

      // Missing from email
      expect(
        () async => await emailAppenderBuilder().withSmtp('smtp.test.com', 587).withTo(['admin@example.com']).build(),
        throwsA(isA<ArgumentError>()),
      );

      // Missing to emails
      expect(
        () async => await emailAppenderBuilder().withSmtp('smtp.test.com', 587).withFrom('test@example.com').build(),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('EmailAppender Integration', () {
    tearDown(() async {
      await LoggerFactory.dispose();
    });

    test('should register with AppenderRegistry', () async {
      // The registration happens in setUpAll()
      expect(AppenderRegistry.instance.isRegistered('EMAIL'), isTrue);
    });

    test('should work with LoggerFactory.init', () async {
      final config = {
        'appenders': [
          {
            'type': 'CONSOLE',
            'level': 'INFO',
          },
          {
            'type': 'EMAIL',
            'smtpHost': 'smtp.test.com',
            'smtpPort': 587,
            'fromEmail': 'test@example.com',
            'toEmails': ['admin@example.com'],
            'level': 'ERROR',
            'batchSize': 10,
          },
        ],
      };

      await LoggerFactory.init(config, test: true);
      final logger = LoggerFactory.getRootLogger();

      expect(logger.appenders.length, equals(2));
      expect(logger.appenders[1].getType(), equals('EMAIL'));
    });

    test('should work with LoggerBuilder extension', () async {
      await LoggerFactory.builder()
          .replaceAll()
          .console(level: Level.INFO)
          .email(
            smtpHost: 'smtp.test.com',
            smtpPort: 587,
            fromEmail: 'test@example.com',
            toEmails: ['admin@example.com'],
            level: Level.ERROR,
            batchSize: 20,
          )
          .build(test: true);

      final logger = LoggerFactory.getRootLogger();
      expect(logger.appenders.length, equals(2));

      final emailAppender = logger.appenders[1] as EmailAppender;
      expect(emailAppender.getType(), equals('EMAIL'));
      expect(emailAppender.smtpHost, equals('smtp.test.com'));
      expect(emailAppender.batchSize, equals(20));
    });

    test('should work with Gmail extension method', () async {
      await LoggerFactory.builder()
          .replaceAll()
          .console(level: Level.INFO)
          .gmail(
            username: 'user@gmail.com',
            appPassword: 'app-pass',
            toEmails: ['admin@example.com'],
            level: Level.ERROR,
          )
          .build(test: true);

      final logger = LoggerFactory.getRootLogger();
      final emailAppender = logger.appenders[1] as EmailAppender;
      expect(emailAppender.smtpHost, equals('smtp.gmail.com'));
      expect(emailAppender.smtpPort, equals(587));
    });

    test('should handle deep copy correctly', () async {
      final original = await EmailAppender.fromConfig({
        'smtpHost': 'smtp.test.com',
        'smtpPort': 587,
        'fromEmail': 'test@example.com',
        'fromName': 'Test',
        'toEmails': ['admin@example.com'],
        'ccEmails': ['cc@example.com'],
        'batchSize': 75,
        'sendAsHtml': true,
      }, test: true);

      final copy = original.createDeepCopy() as EmailAppender;

      expect(copy.smtpHost, equals(original.smtpHost));
      expect(copy.smtpPort, equals(original.smtpPort));
      expect(copy.fromEmail, equals(original.fromEmail));
      expect(copy.fromName, equals(original.fromName));
      expect(copy.toEmails, equals(original.toEmails));
      expect(copy.ccEmails, equals(original.ccEmails));
      expect(copy.batchSize, equals(original.batchSize));
      expect(copy.sendAsHtml, equals(original.sendAsHtml));
      expect(identical(copy, original), isFalse);
      expect(identical(copy.toEmails, original.toEmails), isFalse);

      await original.dispose();
      await copy.dispose();
    });

    test('should respect enabled state', () async {
      final appender = await EmailAppender.fromConfig({
        'smtpHost': 'smtp.test.com',
        'smtpPort': 587,
        'fromEmail': 'test@example.com',
        'toEmails': ['admin@example.com'],
        'enabled': false,
      }, test: true);

      expect(appender.enabled, isFalse);

      final contextInfo = LoggerStackTrace.from(StackTrace.current);
      appender.append(LogRecord(Level.ERROR, 'Test', null, contextInfo));

      // Should not add to buffer when disabled
      expect(appender.getStatistics()['bufferSize'], equals(0));

      await appender.dispose();
    });

    test('should track statistics correctly', () async {
      final appender = await EmailAppender.fromConfig({
        'smtpHost': 'smtp.test.com',
        'smtpPort': 587,
        'fromEmail': 'test@example.com',
        'toEmails': ['admin@example.com'],
        'batchSize': 100,
      }, test: true);

      final stats = appender.getStatistics();
      expect(stats['successfulSends'], equals(0));
      expect(stats['failedSends'], equals(0));
      expect(stats['bufferSize'], equals(0));
      expect(stats['lastSendTime'], isNull);

      // Add some logs and trigger send
      final contextInfo = LoggerStackTrace.from(StackTrace.current);
      for (int i = 0; i < 100; i++) {
        appender.append(LogRecord(Level.INFO, 'Message $i', null, contextInfo));
      }

      // After batch is sent (in test mode)
      final statsAfter = appender.getStatistics();
      expect(statsAfter['successfulSends'], equals(1));
      expect(statsAfter['bufferSize'], equals(0));
      expect(statsAfter['lastSendTime'], isNotNull);

      await appender.dispose();
    });
  });
}
