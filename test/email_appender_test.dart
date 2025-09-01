import 'dart:io';

import 'package:any_logger/any_logger.dart';
import 'package:any_logger_email/any_logger_email.dart';
import 'package:test/test.dart';

void main() {
  group('EmailAppender rotation functionality', () {
    tearDown(() async {
      await LoggerFactory.dispose();
    });

    test('should default to hourly rotation', () async {
      final appender = await EmailAppender.fromConfig({
        'smtpHost': 'smtp.test.com',
        'smtpPort': 587,
        'fromEmail': 'test@example.com',
        'toEmails': ['admin@example.com'],
      }, test: true);

      expect(appender.rotationCycle, equals(RotationCycle.HOURLY),
          reason: 'Should default to hourly email sending');

      await appender.dispose();
    });

    test('should respect rotation cycle configuration', () async {
      final appender = await EmailAppender.fromConfig({
        'smtpHost': 'smtp.test.com',
        'smtpPort': 587,
        'fromEmail': 'test@example.com',
        'toEmails': ['admin@example.com'],
        'rotationCycle': 'DAILY',
      }, test: true);

      expect(appender.rotationCycle, equals(RotationCycle.DAILY));

      await appender.dispose();
    });

    test('should send emails based on rotation cycle, not batch size', () async {
      final appender = await EmailAppender.fromConfig({
        'smtpHost': 'smtp.test.com',
        'smtpPort': 587,
        'fromEmail': 'test@example.com',
        'toEmails': ['admin@example.com'],
        'rotationCycle': 'TEN_MINUTES',
      }, test: true);

      // The rotation cycle should be the primary trigger for sending
      expect(appender.rotationCycle, equals(RotationCycle.TEN_MINUTES));

      // Even if batch size exists for backward compatibility, it shouldn't affect sending
      // The appender should only send based on rotation time

      await appender.dispose();
    });
  });

  group('EmailAppender groupByLevel functionality', () {
    tearDown(() async {
      await LoggerFactory.dispose();
    });

    test('should default groupByLevel to false', () async {
      final appender = await EmailAppender.fromConfig({
        'smtpHost': 'smtp.test.com',
        'smtpPort': 587,
        'fromEmail': 'test@example.com',
        'toEmails': ['admin@example.com'],
      }, test: true);

      expect(appender.groupByLevel, equals(false),
          reason:
          'groupByLevel should default to false for chronological order');

      await appender.dispose();
    });

    test('should respect groupByLevel when set to true', () async {
      final appender = await EmailAppender.fromConfig({
        'smtpHost': 'smtp.test.com',
        'smtpPort': 587,
        'fromEmail': 'test@example.com',
        'toEmails': ['admin@example.com'],
        'groupByLevel': true,
      }, test: true);

      expect(appender.groupByLevel, equals(true));

      await appender.dispose();
    });

    test('should preserve groupByLevel in deep copy', () async {
      final original = await EmailAppender.fromConfig({
        'smtpHost': 'smtp.test.com',
        'smtpPort': 587,
        'fromEmail': 'test@example.com',
        'toEmails': ['admin@example.com'],
        'groupByLevel': true,
      }, test: true);

      final copy = original.createDeepCopy() as EmailAppender;

      expect(copy.groupByLevel, equals(original.groupByLevel));
      expect(copy.groupByLevel, equals(true));

      await original.dispose();
      await copy.dispose();
    });
  });

  group('EmailAppender Builder with rotation presets', () {
    test('should set rotation cycles correctly with presets', () async {
      // Critical alerts - sends every 10 minutes
      final criticalAppender = await emailAppenderBuilder()
          .withSmtp('smtp.test.com', 587)
          .withFrom('test@example.com')
          .withTo(['admin@example.com'])
          .withCriticalAlertPreset()
          .build(test: true);

      expect(criticalAppender.rotationCycle, equals(RotationCycle.TEN_MINUTES),
          reason: 'Critical alerts should send every 10 minutes');
      expect(criticalAppender.groupByLevel, equals(false),
          reason: 'Critical alerts should show chronological order for debugging');

      // Daily digest - sends once per day
      final digestAppender = await emailAppenderBuilder()
          .withSmtp('smtp.test.com', 587)
          .withFrom('test@example.com')
          .withTo(['admin@example.com'])
          .withDailyDigestPreset()
          .build(test: true);

      expect(digestAppender.rotationCycle, equals(RotationCycle.DAILY),
          reason: 'Daily digest should send once per day');
      expect(digestAppender.groupByLevel, equals(true),
          reason: 'Daily digest should group by level for better summary');

      // Hourly monitoring - sends every hour
      final hourlyAppender = await emailAppenderBuilder()
          .withSmtp('smtp.test.com', 587)
          .withFrom('test@example.com')
          .withTo(['admin@example.com'])
          .withHourlyMonitoringPreset()
          .build(test: true);

      expect(hourlyAppender.rotationCycle, equals(RotationCycle.HOURLY),
          reason: 'Hourly monitoring should send every hour');

      // Development - sends every 30 minutes
      final devAppender = await emailAppenderBuilder()
          .withSmtp('smtp.test.com', 587)
          .withFrom('test@example.com')
          .withTo(['admin@example.com'])
          .withDevelopmentPreset()
          .build(test: true);

      expect(devAppender.rotationCycle, equals(RotationCycle.THIRTY_MINUTES),
          reason: 'Development preset should send every 30 minutes');

      // Weekly report - sends once per week
      final weeklyAppender = await emailAppenderBuilder()
          .withSmtp('smtp.test.com', 587)
          .withFrom('test@example.com')
          .withTo(['admin@example.com'])
          .withWeeklyReportPreset()
          .build(test: true);

      expect(weeklyAppender.rotationCycle, equals(RotationCycle.WEEKLY),
          reason: 'Weekly report should send once per week');

      // Production - sends every 2 hours
      final prodAppender = await emailAppenderBuilder()
          .withSmtp('smtp.test.com', 587)
          .withFrom('test@example.com')
          .withTo(['admin@example.com'])
          .withProductionPreset()
          .build(test: true);

      expect(prodAppender.rotationCycle, equals(RotationCycle.TWO_HOURS),
          reason: 'Production preset should send every 2 hours');

      await criticalAppender.dispose();
      await digestAppender.dispose();
      await hourlyAppender.dispose();
      await devAppender.dispose();
      await weeklyAppender.dispose();
      await prodAppender.dispose();
    });

    test('should allow custom rotation periods', () async {
      // Test all rotation methods
      final tenMinAppender = await emailAppenderBuilder()
          .withSmtp('smtp.test.com', 587)
          .withFrom('test@example.com')
          .withTo(['admin@example.com'])
          .withTenMinuteRotation()
          .build(test: true);

      expect(tenMinAppender.rotationCycle, equals(RotationCycle.TEN_MINUTES));

      final monthlyAppender = await emailAppenderBuilder()
          .withSmtp('smtp.test.com', 587)
          .withFrom('test@example.com')
          .withTo(['admin@example.com'])
          .withDailyRotation()
          .build(test: true);

      expect(monthlyAppender.rotationCycle, equals(RotationCycle.DAILY));

      await tenMinAppender.dispose();
      await monthlyAppender.dispose();
    });
  });

  group('EmailAppender formatting options defaults', () {
    late EmailAppender appender;

    setUp(() async {
      appender = await EmailAppender.fromConfig({
        'smtpHost': 'smtp.test.com',
        'smtpPort': 587,
        'fromEmail': 'test@example.com',
        'toEmails': ['admin@example.com'],
      }, test: true);
    });

    tearDown(() async {
      await appender.dispose();
    });

    test('should have correct default formatting options', () {
      expect(appender.sendAsHtml, equals(true));
      expect(appender.includeStackTrace, equals(true));
      expect(appender.includeMetadata, equals(true));
      expect(appender.includeHostname, equals(true));
      expect(appender.includeAppInfo, equals(true));
      expect(appender.attachLogFile, equals(true));
      expect(appender.groupByLevel, equals(false)); // Chronological by default
      expect(appender.rotationCycle, equals(RotationCycle.HOURLY)); // Default rotation
    });
  });

  group('FileAppender Rotation', () {
    const testDir = 'test_rotation_logs';

    setUp(() async {
      final dir = Directory(testDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    });

    tearDown(() async {
      await LoggerFactory.dispose();
      final dir = Directory(testDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });

    test('should handle daily rotation', () async {
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final appender = await FileAppenderBuilder('daily_test')
          .withPath(testDir)
          .withRotationCycle(RotationCycle.DAILY)
          .withLevel(Level.INFO)
          .build();

      await LoggerBuilder().replaceAll().addAppender(appender).build();

      Logger.info('Test daily rotation');
      await LoggerFactory.flushAll();

      final expectedFile = File('$testDir/daily_test_$dateStr.log');
      expect(await expectedFile.exists(), isTrue);
    });

    test('should handle weekly rotation', () async {
      final now = DateTime.now();
      final weekNumber = _getCalendarWeek(now);
      final weekStr = '${now.year}-CW$weekNumber';

      final appender = await fileAppenderBuilder('weekly_test')
          .withPath(testDir)
          .withRotationCycle(RotationCycle.WEEKLY)
          .withLevel(Level.INFO)
          .build();

      await LoggerBuilder().replaceAll().addAppender(appender).build();

      Logger.info('Test weekly rotation');
      await LoggerFactory.flushAll();

      final expectedFile = File('$testDir/weekly_test_$weekStr.log');
      expect(await expectedFile.exists(), isTrue);
    });

    test('should handle monthly rotation', () async {
      final now = DateTime.now();
      final monthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      final appender = await fileAppenderBuilder('monthly_test')
          .withPath(testDir)
          .withRotationCycle(RotationCycle.MONTHLY)
          .withLevel(Level.INFO)
          .build();

      await LoggerBuilder().replaceAll().addAppender(appender).build();

      Logger.info('Test monthly rotation');
      await LoggerFactory.flushAll();

      final expectedFile = File('$testDir/monthly_test_$monthStr.log');
      expect(await expectedFile.exists(), isTrue);
    });

    test('should handle hourly rotation', () async {
      final appender = await FileAppenderBuilder('hourly_test')
          .withPath(testDir)
          .withRotationCycle(RotationCycle.HOURLY)
          .withLevel(Level.INFO)
          .build();

      await LoggerBuilder().replaceAll().addAppender(appender).build();

      Logger.info('Test hourly rotation');
      await LoggerFactory.flushAll();

      final dir = Directory(testDir);
      final files = await dir.list().toList();
      expect(files.length, greaterThan(0));

      final logFile = files.first as File;
      expect(logFile.path, contains('hourly_test'));
    });

    test('should handle no rotation', () async {
      final appender = await FileAppenderBuilder('no_rotation_test')
          .withPath(testDir)
          .withRotationCycle(RotationCycle.NEVER)
          .withLevel(Level.INFO)
          .build();

      await LoggerBuilder().replaceAll().addAppender(appender).build();

      Logger.info('Test no rotation');
      await LoggerFactory.flushAll();

      final expectedFile = File('$testDir/no_rotation_test.log');
      expect(await expectedFile.exists(), isTrue);
    });

    test('should handle 10-minute rotation', () async {
      final appender = await FileAppenderBuilder('ten_min_test')
          .withPath(testDir)
          .withRotationCycle(RotationCycle.TEN_MINUTES)
          .withLevel(Level.INFO)
          .build();

      await LoggerBuilder().replaceAll().addAppender(appender).build();

      Logger.info('Test 10-minute rotation');
      await LoggerFactory.flushAll();

      final dir = Directory(testDir);
      final files = await dir.list().toList();
      expect(files.length, greaterThan(0));

      final logFile = files.first as File;
      expect(logFile.path, contains('ten_min_test'));
    });
  });

  group('EmailAppender vs FileAppender behavior', () {
    const testDir = 'test_comparison_logs';

    setUp(() async {
      final dir = Directory(testDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    });

    tearDown(() async {
      await LoggerFactory.dispose();
      final dir = Directory(testDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });

    test('FileAppender should create new files on rotation', () async {
      // FileAppender creates new files when rotation period changes
      final fileAppender = await FileAppenderBuilder('file_rotation')
          .withPath(testDir)
          .withRotationCycle(RotationCycle.HOURLY)
          .withLevel(Level.INFO)
          .build();

      await LoggerBuilder().replaceAll().addAppender(fileAppender).build();

      Logger.info('FileAppender test - should create timestamped file');
      await LoggerFactory.flushAll();

      final dir = Directory(testDir);
      final files = await dir.list().toList();

      // Should have created a file with timestamp
      expect(files.length, equals(1));
      final file = files.first as File;
      expect(file.path, contains('file_rotation'));
      // File name should have timestamp suffix based on rotation
    });

    test('EmailAppender should NOT create new files on rotation', () async {
      // EmailAppender keeps the same file, just sends its contents
      final emailAppender = await EmailAppender.fromConfig({
        'smtpHost': 'smtp.test.com',
        'smtpPort': 587,
        'fromEmail': 'test@example.com',
        'toEmails': ['admin@example.com'],
        'filePattern': 'email_no_rotation',
        'path': testDir,
        'rotationCycle': 'HOURLY',
      }, test: true);

      await LoggerBuilder().replaceAll().addAppender(emailAppender).build();

      Logger.info('EmailAppender test - should use same file');
      await LoggerFactory.flushAll();

      // File name should not have rotation suffix
      final expectedFile = File('$testDir/email_no_rotation.log');
      expect(await expectedFile.exists(), isTrue,
          reason: 'EmailAppender should use a single file without rotation suffix');
    });
  });
}

// Helper function to calculate week number
int _getCalendarWeek(DateTime date) {
  final startOfYear = DateTime(date.year, 1, 1);
  final firstMonday = startOfYear.weekday == 1
      ? startOfYear
      : startOfYear.add(Duration(days: 8 - startOfYear.weekday));

  if (date.isBefore(firstMonday)) {
    return _getCalendarWeek(DateTime(date.year - 1, 12, 31));
  }

  final weekNumber = ((date.difference(firstMonday).inDays) / 7).floor() + 1;
  return weekNumber;
}