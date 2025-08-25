import 'package:any_logger/any_logger.dart';

/// Extension methods for adding EmailAppender to presets
extension EmailPresets on LoggerPresets {
  /// Production preset with email alerts for critical errors
  static Map<String, dynamic> productionWithEmail({
    required String smtpHost,
    required int smtpPort,
    required String fromEmail,
    required List<String> toEmails,
    String? username,
    String? password,
    String? appVersion,
  }) {
    return {
      'appenders': [
        {
          'type': 'CONSOLE',
          'format': '[%sid][%l] %m',
          'level': 'WARN',
          'dateFormat': 'HH:mm:ss',
        },
        {
          'type': 'FILE',
          'format': '[%d][%app][%did][%sid][%l] %m [%f]',
          'level': 'INFO',
          'dateFormat': 'yyyy-MM-dd HH:mm:ss.SSS',
          'filePattern': 'app',
          'path': 'logs/',
          'rotationCycle': 'DAY',
        },
        {
          'type': 'EMAIL',
          'smtpHost': smtpHost,
          'smtpPort': smtpPort,
          'fromEmail': fromEmail,
          'toEmails': toEmails,
          'username': username,
          'password': password,
          'level': 'ERROR',
          'subjectPrefix': '[PRODUCTION ERROR]',
          'batchSize': 10,
          'batchIntervalMinutes': 2,
          'sendImmediatelyOnError': true,
          'immediateErrorThreshold': 5,
          'includeMetadata': true,
          'includeStackTrace': true,
          'sendAsHtml': true,
          'groupByLevel': true,
        }
      ]
    };
  }

  /// Development preset with email for debugging
  static Map<String, dynamic> developmentWithEmail({
    required String smtpHost,
    required int smtpPort,
    required String fromEmail,
    required List<String> developerEmails,
    String? username,
    String? password,
  }) {
    return {
      'appenders': [
        {
          'type': 'CONSOLE',
          'format': '[%d][%l][%c] %m [%f]',
          'level': 'DEBUG',
          'dateFormat': 'HH:mm:ss.SSS',
        },
        {
          'type': 'EMAIL',
          'smtpHost': smtpHost,
          'smtpPort': smtpPort,
          'fromEmail': fromEmail,
          'toEmails': developerEmails,
          'username': username,
          'password': password,
          'level': 'ERROR',
          'subjectPrefix': '[DEV ERROR]',
          'batchSize': 5,
          'batchIntervalMinutes': 1,
          'includeMetadata': true,
          'includeStackTrace': true,
          'sendAsHtml': true,
        }
      ]
    };
  }

  /// Mobile app preset with crash reporting via email
  static Map<String, dynamic> mobileWithEmail({
    required String smtpHost,
    required int smtpPort,
    required String fromEmail,
    required List<String> supportEmails,
    String? username,
    String? password,
    String? appVersion,
  }) {
    return {
      'appenders': [
        {
          'type': 'CONSOLE',
          'format': '[%l] %m',
          'level': 'ERROR',
          'dateFormat': 'HH:mm:ss',
        },
        {
          'type': 'FILE',
          'format': '[%d][%app][%did][%sid][%l] %m [%f]',
          'level': 'WARN',
          'dateFormat': 'yyyy-MM-dd HH:mm:ss.SSS',
          'filePattern': 'crash',
          'path': 'logs/',
          'rotationCycle': 'DAY',
        },
        {
          'type': 'EMAIL',
          'smtpHost': smtpHost,
          'smtpPort': smtpPort,
          'fromEmail': fromEmail,
          'toEmails': supportEmails,
          'username': username,
          'password': password,
          'level': 'ERROR',
          'subjectPrefix': '[MOBILE CRASH]',
          'batchSize': 1, // Send immediately
          'batchIntervalMinutes': 1,
          'sendImmediatelyOnError': true,
          'immediateErrorThreshold': 1,
          'includeMetadata': true,
          'includeStackTrace': true,
          'includeAppInfo': true,
          'includeHostname': false,
          'sendAsHtml': true,
        }
      ]
    };
  }

  /// Server monitoring preset with daily digest emails
  static Map<String, dynamic> serverMonitoringWithEmail({
    required String smtpHost,
    required int smtpPort,
    required String fromEmail,
    required List<String> adminEmails,
    String? username,
    String? password,
  }) {
    return {
      'appenders': [
        {
          'type': 'CONSOLE',
          'format': '[%d][%l] %m',
          'level': 'INFO',
          'dateFormat': 'HH:mm:ss',
        },
        {
          'type': 'FILE',
          'format': '[%d][%l][%c] %m [%f]',
          'level': 'INFO',
          'dateFormat': 'yyyy-MM-dd HH:mm:ss.SSS',
          'filePattern': 'server',
          'path': 'logs/',
          'rotationCycle': 'DAY',
          'maxFileSize': '100MB',
        },
        {
          'type': 'EMAIL',
          'smtpHost': smtpHost,
          'smtpPort': smtpPort,
          'fromEmail': fromEmail,
          'toEmails': adminEmails,
          'username': username,
          'password': password,
          'level': 'INFO',
          'subjectPrefix': '[SERVER DIGEST]',
          'batchSize': 1000,
          'batchIntervalMinutes': 1440, // Daily digest
          'sendImmediatelyOnError': false,
          'includeMetadata': true,
          'includeStackTrace': false,
          'groupByLevel': true,
          'sendAsHtml': true,
        }
      ]
    };
  }

  /// Critical alerts preset for immediate notification
  static Map<String, dynamic> criticalAlertsWithEmail({
    required String smtpHost,
    required int smtpPort,
    required String fromEmail,
    required List<String> alertEmails,
    String? username,
    String? password,
    List<String>? smsEmails, // Email-to-SMS gateways
  }) {
    final config = {
      'appenders': [
        {
          'type': 'CONSOLE',
          'format': '[CRITICAL][%d] %m',
          'level': 'ERROR',
          'dateFormat': 'yyyy-MM-dd HH:mm:ss',
        },
        {
          'type': 'EMAIL',
          'smtpHost': smtpHost,
          'smtpPort': smtpPort,
          'fromEmail': fromEmail,
          'toEmails': alertEmails,
          'username': username,
          'password': password,
          'level': 'ERROR',
          'subjectPrefix': '[🚨 CRITICAL ALERT]',
          'batchSize': 1, // Send immediately
          'batchIntervalMinutes': 1,
          'sendImmediatelyOnError': true,
          'immediateErrorThreshold': 1,
          'includeMetadata': true,
          'includeStackTrace': true,
          'includeHostname': true,
          'sendAsHtml': true,
          'maxEmailsPerHour': 100, // Higher limit for critical alerts
        }
      ]
    };

    // Add SMS gateway emails if provided
    if (smsEmails != null && smsEmails.isNotEmpty) {
      config['appenders']!.add({
        'type': 'EMAIL',
        'smtpHost': smtpHost,
        'smtpPort': smtpPort,
        'fromEmail': fromEmail,
        'toEmails': smsEmails,
        'username': username,
        'password': password,
        'level': 'ERROR',
        'subjectPrefix': 'ALERT',
        'batchSize': 1,
        'sendImmediatelyOnError': true,
        'immediateErrorThreshold': 1,
        'sendAsHtml': false, // Plain text for SMS
        'includeStackTrace': false,
        'includeMetadata': false,
        'includeHostname': true,
      });
    }

    return config;
  }
}
