# Any Logger Email

An email appender extension for [Any Logger](https://pub.dev/packages/any_logger) that enables sending log notifications via SMTP to any email address. Perfect for critical error alerts, daily digests, system monitoring, and production incident notifications.

## Features

- **Universal SMTP Support** - Works with any SMTP server including Gmail, Office 365, SendGrid, and more
- **Smart Batching** - Automatically batches logs to reduce email volume
- **Rate Limiting** - Prevents email flooding with configurable limits
- **HTML & Plain Text** - Beautiful HTML emails with fallback to plain text
- **Priority Alerts** - Immediate sending for critical errors
- **Multiple Recipients** - Support for TO, CC, and BCC recipients
- **Flexible Templates** - Customizable email templates or use built-in formats
- **Service Presets** - Pre-configured settings for popular email services

## Installation

```yaml
dependencies:
  any_logger: ^x.y.z
  any_logger_email: ^x.y.z  // See Installing
```

To register the EMAIL appender you have to import the library

```dart
import 'package:any_logger/any_logger.dart';
import 'package:any_logger_email/any_logger_email.dart';
```
and call:

```dart
AnyLoggerEmailExtension.register();
```

## Quick Start

### Simple Setup with Gmail

```dart
await LoggerFactory.builder()
    .console(level: Level.INFO)
    .gmail(
      username: 'your.app@gmail.com',
      appPassword: 'your-app-password', // Use App Password, not regular password
      toEmails: ['admin@example.com'],
      level: Level.ERROR,
    )
    .build();

Logger.info('This only goes to console');
Logger.error('This triggers an email alert!');
```

### Custom SMTP Server

```dart
await LoggerFactory.builder()
    .email(
      smtpHost: 'smtp.company.com',
      smtpPort: 587,
      fromEmail: 'logger@company.com',
      toEmails: ['dev-team@company.com'],
      username: 'logger@company.com',
      password: 'secure_password',
      level: Level.ERROR,
      sendAsHtml: true,
    )
    .build();
```

## Email Service Configuration

### Gmail

```dart
final appender = await emailAppenderBuilder()
    .withGmailPreset('your.app@gmail.com', 'app-password')
    .withTo(['alerts@example.com'])
    .withLevel(Level.ERROR)
    .build();
```

**Important**: Use an [App Password](https://support.google.com/accounts/answer/185833) for Gmail, not your regular password.

### Office 365 / Outlook

```dart
final appender = await emailAppenderBuilder()
    .withOffice365Preset('user@company.com', 'password')
    .withTo(['team@company.com'])
    .withLevel(Level.ERROR)
    .build();
```

### SendGrid

```dart
final appender = await emailAppenderBuilder()
    .withSendGridPreset('your-sendgrid-api-key')
    .withFrom('noreply@yourapp.com')
    .withTo(['ops@yourapp.com'])
    .build();
```

### Custom SMTP

```dart
final appender = await emailAppenderBuilder()
    .withSmtp('mail.server.com', 465, ssl: true)
    .withCredentials('username', 'password')
    .withFrom('logger@server.com', 'System Logger')
    .withTo(['admin@server.com'])
    .build();
```

## Configuration Options

### Using Builder Pattern

```dart
final appender = await emailAppenderBuilder()
    .withSmtp('smtp.example.com', 587)
    .withCredentials('user', 'pass')
    .withFrom('app@example.com', 'My App')
    .withTo(['dev@example.com', 'ops@example.com'])
    .withCc(['manager@example.com'])
    .withBcc(['archive@example.com'])
    .withReplyTo('support@example.com')
    .withSubjectPrefix('[PRODUCTION]')
    .withLevel(Level.ERROR)
    .withBatchSize(10)
    .withBatchIntervalMinutes(5)
    .withRateLimit(20) // Max 20 emails per hour
    .withHtmlFormat(true)
    .withStackTraces(true)
    .withMetadata(true)
    .withGroupByLevel(true)
    .withImmediateErrors(true)
    .withErrorThreshold(3)
    .build();
```

### Using Configuration Map

```dart
final config = {
  'appenders': [
    {
      'type': 'EMAIL',
      'smtpHost': 'smtp.example.com',
      'smtpPort': 587,
      'ssl': false,
      'fromEmail': 'logger@example.com',
      'fromName': 'App Logger',
      'toEmails': ['admin@example.com', 'dev@example.com'],
      'ccEmails': ['manager@example.com'],
      'username': 'logger@example.com',
      'password': 'secure_password',
      'level': 'ERROR',
      'subjectPrefix': '[APP ERROR]',
      'batchSize': 25,
      'batchIntervalMinutes': 10,
      'maxEmailsPerHour': 30,
      'sendAsHtml': true,
      'includeStackTrace': true,
      'includeMetadata': true,
      'groupByLevel': true,
      'sendImmediatelyOnError': true,
      'immediateErrorThreshold': 5,
    }
  ]
};

await LoggerFactory.init(config);
```

### Configuration Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `smtpHost` | String | Required | SMTP server hostname |
| `smtpPort` | int | Required | SMTP server port (25, 465, 587, etc.) |
| `ssl` | bool | false | Use SSL/TLS encryption |
| `allowInsecure` | bool | false | Allow insecure connections |
| `ignoreBadCertificate` | bool | false | Ignore certificate errors |
| `fromEmail` | String | Required | Sender email address |
| `fromName` | String | null | Sender display name |
| `toEmails` | List/String | Required | Recipient email(s) |
| `ccEmails` | List/String | [] | CC recipients |
| `bccEmails` | List/String | [] | BCC recipients |
| `replyTo` | String | null | Reply-to address |
| `username` | String | null | SMTP username |
| `password` | String | null | SMTP password |
| `level` | Level | ERROR | Minimum log level to email |
| `subjectPrefix` | String | '[LOG]' | Email subject prefix |
| `includeHostname` | bool | true | Include hostname in emails |
| `includeAppInfo` | bool | true | Include app version/device ID |
| `batchSize` | int | 50 | Logs per batch |
| `batchIntervalMinutes` | int | 5 | Minutes before sending partial batch |
| `maxEmailsPerHour` | int | 20 | Rate limit per hour |
| `sendAsHtml` | bool | true | Send HTML formatted emails |
| `includeStackTrace` | bool | true | Include stack traces |
| `includeMetadata` | bool | true | Include metadata |
| `groupByLevel` | bool | true | Group logs by level in email |
| `sendImmediatelyOnError` | bool | true | Send immediately on errors |
| `immediateErrorThreshold` | int | 10 | Error count to trigger immediate send |

## Email Format Examples

### HTML Email (Default)

The appender sends beautifully formatted HTML emails with:
- Color-coded log levels
- Grouped sections by severity
- Syntax-highlighted stack traces
- Metadata header with system info
- Responsive design for mobile

### Plain Text Email

For systems that require plain text:

```dart
.withHtmlFormat(false)
```

Produces clean, readable plain text emails with proper formatting.

## Presets

### Critical Alert Preset

```dart
final appender = await emailAppenderBuilder()
    .withSmtp('smtp.example.com', 587)
    .withFrom('alerts@example.com')
    .withTo(['oncall@example.com'])
    .withCriticalAlertPreset()
    .build();

// Configures:
// - Level: ERROR
// - Batch size: 5
// - Interval: 1 minute
// - Immediate sending on first error
// - Include full stack traces
// - Subject: [CRITICAL ALERT]
```

### Daily Digest Preset

```dart
final appender = await emailAppenderBuilder()
    .withSmtp('smtp.example.com', 587)
    .withFrom('reports@example.com')
    .withTo(['management@example.com'])
    .withDailyDigestPreset()
    .build();

// Configures:
// - Level: INFO
// - Batch size: 1000
// - Interval: 24 hours
// - No immediate sending
// - Group by level
// - No stack traces (summary only)
```

### Development Preset

```dart
final appender = await emailAppenderBuilder()
    .withSmtp('smtp.example.com', 587)
    .withFrom('dev@example.com')
    .withTo(['developers@example.com'])
    .withDevelopmentPreset()
    .build();

// Configures:
// - Level: DEBUG
// - Batch size: 20
// - Interval: 5 minutes
// - Include everything for debugging
```

## Use Cases

### Production Error Monitoring

```dart
await LoggerFactory.builder()
    .file(filePattern: 'app', level: Level.INFO) // Log everything to file
    .email(
      smtpHost: 'smtp.sendgrid.net',
      smtpPort: 587,
      fromEmail: 'errors@myapp.com',
      toEmails: ['oncall@myapp.com'],
      username: 'apikey',
      password: process.env['SENDGRID_API_KEY'],
      level: Level.ERROR,
      subjectPrefix: '[PROD ERROR]',
      batchSize: 5,
      sendImmediatelyOnError: true,
    )
    .build();
```

### Daily Summary Reports

```dart
await LoggerFactory.builder()
    .console(level: Level.INFO)
    .email(
      smtpHost: 'smtp.gmail.com',
      smtpPort: 587,
      fromEmail: 'reports@company.com',
      toEmails: ['management@company.com'],
      username: 'reports@company.com',
      password: 'app-password',
      level: Level.INFO,
      subjectPrefix: '[Daily Report]',
      batchSize: 1000,
      batchIntervalMinutes: 1440, // 24 hours
      sendImmediatelyOnError: false,
      groupByLevel: true,
      includeStackTrace: false,
    )
    .build();
```

### Critical System Alerts

```dart
// Send to multiple channels for critical issues
await LoggerFactory.builder()
    .email(
      smtpHost: 'smtp.example.com',
      smtpPort: 587,
      fromEmail: 'critical@system.com',
      toEmails: [
        'oncall@company.com',
        '5551234567@vtext.com', // SMS via email gateway
      ],
      level: Level.ERROR,
      subjectPrefix: '🚨 CRITICAL',
      batchSize: 1, // Send immediately
      maxEmailsPerHour: 100, // Allow more for critical
    )
    .build();
```

### Development Debugging

```dart
await LoggerFactory.builder()
    .console(level: Level.DEBUG)
    .gmail(
      username: 'dev@gmail.com',
      appPassword: 'app-password',
      toEmails: ['developer@example.com'],
      level: Level.ERROR,
      subjectPrefix: '[DEV ERROR]',
      sendAsHtml: true,
      includeStackTrace: true,
    )
    .build();
```

## Best Practices

### 1. Use App Passwords

For Gmail and other services with 2FA, always use app-specific passwords:
- Gmail: [Create App Password](https://support.google.com/accounts/answer/185833)
- Outlook: [App passwords in Microsoft 365](https://support.microsoft.com/en-us/account-billing/using-app-passwords-with-apps-that-don-t-support-two-step-verification-5896ed9b-4263-e681-128a-a6f2979a7944)

### 2. Configure Rate Limits

Prevent email flooding:

```dart
.withRateLimit(20) // Max 20 emails per hour
.withBatchSize(50) // Batch up to 50 logs
.withBatchIntervalMinutes(10) // Send every 10 minutes
```

### 3. Set Appropriate Thresholds

```dart
// For critical systems
.withLevel(Level.ERROR)
.withImmediateErrors(true)
.withErrorThreshold(1) // Send on first error

// For development
.withLevel(Level.WARN)
.withErrorThreshold(10) // Batch warnings
```

### 4. Use Different Recipients for Different Levels

```dart
// Critical errors to on-call
await LoggerFactory.builder()
    .email(
      // ... config
      toEmails: ['oncall@company.com'],
      level: Level.ERROR,
      subjectPrefix: '[CRITICAL]',
    )
    // Daily digest to management
    .email(
      // ... config
      toEmails: ['reports@company.com'],
      level: Level.INFO,
      subjectPrefix: '[DAILY]',
      batchIntervalMinutes: 1440,
    )
    .build();
```

### 5. Include Context in Subject

```dart
final hostname = Platform.localHostname;
.withSubjectPrefix('[$hostname ERROR]')
```

## Troubleshooting

### Emails Not Being Sent

1. **Check SMTP credentials**: Verify username/password are correct
2. **Check firewall**: Ensure SMTP ports (25, 465, 587) are open
3. **Enable less secure apps**: Some providers require this setting
4. **Use app passwords**: For accounts with 2FA enabled
5. **Check rate limits**: You may have hit the hourly limit
6. **Enable self-debugging**:

```dart
await LoggerFactory.builder()
    .email(/* config */)
    .withSelfDebug(Level.DEBUG)
    .build();
```

### Gmail Specific Issues

- Enable "Less secure app access" or use App Passwords
- Use port 587 (not 465) for TLS
- Ensure 2-factor authentication is properly configured

### SSL/TLS Issues

```dart
// For self-signed certificates
.withSmtp('smtp.internal.com', 465, 
    ssl: true, 
    ignoreBadCertificate: true)
```

### High Memory Usage

- Reduce `batchSize` to limit memory usage
- Increase `batchIntervalMinutes` for less frequent sends
- Disable `includeStackTrace` for large volumes

## Testing

For unit tests, use test mode to avoid sending actual emails:

```dart
final appender = await emailAppenderBuilder()
    .withSmtp('smtp.test.com', 587)
    .withFrom('test@example.com')
    .withTo(['test@example.com'])
    .build(test: true); // No emails will be sent
```

## Security Considerations

1. **Never commit credentials**: Use environment variables or secure vaults
2. **Use encrypted connections**: Enable SSL/TLS when possible
3. **Rotate passwords regularly**: Especially for production systems
4. **Limit recipient lists**: Avoid exposing email addresses unnecessarily
5. **Sanitize log content**: Be careful with sensitive data in logs

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Support

- Main Package: [any_logger](https://pub.dev/packages/any_logger)
- Issues: [GitHub Issues](https://github.com/raoulsson/any_logger_email/issues)
- Examples: See `/example` folder in the package

---

Part of the [Any Logger](https://pub.dev/packages/any_logger) ecosystem.

## 💚 Funding

- 🏅 https://github.com/sponsors/raoulsson
- 🪙 https://www.buymeacoffee.com/raoulsson

---

**Happy Logging! 🎉**