# Any Logger Email

An email appender extension for [Any Logger](https://pub.dev/packages/any_logger) that enables
sending log notifications via SMTP to any email address. Perfect for critical error alerts, daily
digests, system monitoring, and production incident notifications.

## Features

- **Universal SMTP Support** - Works with any SMTP server including Gmail, Office 365, SendGrid, and
  more
- **App Password Support** - Clear API for using app-specific passwords (required by Gmail/Outlook)
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
  any_logger_email: ^2.0.0  # Note: v2.0.0+ has breaking changes
```

To register the EMAIL appender you have to import the library:

```dart
import 'package:any_logger/any_logger.dart';
import 'package:any_logger_email/any_logger_email.dart';
```

and call:

```dart
AnyLoggerEmailExtension.register();
```

## Quick Start

### 🚨 Authentication Requirements

**Gmail, Outlook, Yahoo and most email providers no longer accept regular passwords for SMTP.**

You MUST use:

- **App-specific passwords** for Gmail, Outlook, Yahoo Mail
- **API keys** for SendGrid, Mailgun, AWS SES
- **SMTP credentials** for dedicated email services

### Simple Setup with Gmail

```dart
// ✅ CORRECT: Using app-specific password
await LoggerBuilder()
  .console(level: Level.INFO)
  .gmailWithAppPassword(
    emailAddress: 'your.app@gmail.com',
    appPassword: 'abcd-efgh-ijkl-mnop', // 16-char app password from Google
    toEmails: ['admin@example.com'],
    level: Level.ERROR,
  )
  .build();

// ❌ WRONG: This will NOT work
// .gmail(username: 'your.app@gmail.com', password: 'YourGooglePassword123!')
```

**To get a Gmail app password:**

1. Enable 2-factor authentication on your Google account
2. Go to [Google Account → Security → App passwords](https://myaccount.google.com/apppasswords)
3. Generate a new app password
4. Use the 16-character password shown (format: xxxx-xxxx-xxxx-xxxx)

### Custom SMTP Server

```dart
await LoggerBuilder()
  .email(
    smtpHost: 'smtp.company.com',
    smtpPort: 587,
    fromEmail: 'logger@company.com',
    toEmails: ['dev-team@company.com'],
    username: 'logger@company.com',
    passwordOrApiKey: 'secure_password_or_api_key', // Note the renamed parameter
    level: Level.ERROR,
    sendAsHtml: true,
  )
  .build();
```

## Email Service Configuration

### Gmail (App Password Required)

```dart
// Using LoggerBuilder extension
await LoggerBuilder()
  .gmailWithAppPassword(
    emailAddress: 'your.app@gmail.com',
    appPassword: 'xxxx-xxxx-xxxx-xxxx', // NOT your Google password!
    toEmails: ['alerts@example.com'],
  )
  .build();

// Using EmailAppenderBuilder
final appender = await emailAppenderBuilder()
  .withGmailAppPassword('your.app@gmail.com', 'xxxx-xxxx-xxxx-xxxx')
  .withTo(['alerts@example.com'])
  .withLevel(Level.ERROR)
  .build();
```

**Get your Gmail app password here:** [Google Account → Security → App passwords](https://myaccount.google.com/apppasswords)

### Office 365 / Outlook (App Password Required)

```dart
// Using LoggerBuilder extension
await LoggerBuilder()
  .outlookWithAppPassword(
    emailAddress: 'user@company.com',
    appPassword: 'generated-app-password', // NOT your Microsoft password!
    toEmails: ['team@company.com'],
  )
  .build();

// Using EmailAppenderBuilder
final appender = await emailAppenderBuilder()
  .withOutlookAppPassword('user@company.com', 'generated-app-password')
  .withTo(['team@company.com'])
  .build();
```

**Get your Outlook app password here:** [Microsoft Account → Security → App passwords](https://account.microsoft.com/security/)

### SendGrid (API Key)

```dart
// Using LoggerBuilder extension
await LoggerBuilder()
  .sendGridWithApiKey(
    apiKey: 'SG.actualApiKeyHere',
    fromEmail: 'noreply@yourapp.com',
    toEmails: ['ops@yourapp.com'],
  )
  .build();

// Using EmailAppenderBuilder
final appender = await emailAppenderBuilder()
  .withSendGridApiKey('SG.actualApiKeyHere', 'noreply@yourapp.com')
  .withTo(['ops@yourapp.com'])
  .build();
```

### Mailgun (API Key)

```dart
// Using LoggerBuilder extension
await LoggerBuilder()
  .mailgunWithApiKey(
    apiKey: 'key-xxxxx',
    domain: 'mg.yourdomain.com',
    fromEmail: 'alerts@yourdomain.com',
    toEmails: ['admin@yourdomain.com'],
  )
  .build();

// Using EmailAppenderBuilder
final appender = await emailAppenderBuilder()
  .withMailgunApiKey('key-xxxxx', 'mg.yourdomain.com', 'alerts@yourdomain.com')
  .withTo(['admin@yourdomain.com'])
  .build();
```

### AWS SES

```dart
final appender = await emailAppenderBuilder()
  .withAwsSes(
    region: 'us-east-1',
    smtpUsername: 'AKIA...', // SMTP credentials from SES console
    smtpPassword: 'BLx9...', // NOT your AWS IAM credentials!
    fromEmail: 'noreply@yourdomain.com',
  )
  .withTo(['alerts@yourdomain.com'])
  .build();
```

### Custom SMTP

```dart
final appender = await emailAppenderBuilder()
  .withCustomSmtp(
    host: 'mail.server.com',
    port: 465,
    username: 'logger@server.com',
    password: 'app-specific-password-or-api-key',
    ssl: true,
    fromEmail: 'logger@server.com',
  )
  .withTo(['admin@server.com'])
  .build();
```

## Configuration Options

### Using Builder Pattern

```dart
final appender = await emailAppenderBuilder()
  .withSmtp('smtp.example.com', 587)
  .withAppPassword('user@example.com', 'app-specific-password') // Clear method name
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
  .withGroupByLevel(false) // Changed default: chronological for better debugging
  .withImmediateErrors(true)
  .withErrorThreshold(3)
  .build();
```

### Configuration Parameters

| Parameter                 | Type        | Default   | Description                                    |
|---------------------------|-------------|-----------|------------------------------------------------|
| `smtpHost`                | String      | Required  | SMTP server hostname                           |
| `smtpPort`                | int         | Required  | SMTP server port (25, 465, 587, etc.)          |
| `ssl`                     | bool        | false     | Use SSL/TLS encryption                         |
| `allowInsecure`           | bool        | false     | Allow insecure connections                     |
| `ignoreBadCertificate`    | bool        | false     | Ignore certificate errors                      |
| `fromEmail`               | String      | Required  | Sender email address                           |
| `fromName`                | String      | null      | Sender display name                            |
| `toEmails`                | List/String | Required  | Recipient email(s)                             |
| `ccEmails`                | List/String | []        | CC recipients                                  |
| `bccEmails`               | List/String | []        | BCC recipients                                 |
| `replyTo`                 | String      | null      | Reply-to address                               |
| `username`                | String      | null      | SMTP username                                  |
| `passwordOrApiKey`        | String      | null      | App password or API key (NOT regular password) |
| `level`                   | Level       | ERROR     | Minimum log level to email                     |
| `subjectPrefix`           | String      | '[LOG]'   | Email subject prefix                           |
| `includeHostname`         | bool        | true      | Include hostname in emails                     |
| `includeAppInfo`          | bool        | true      | Include app version/device ID                  |
| `batchSize`               | int         | 50        | Logs per batch                                 |
| `batchIntervalMinutes`    | int         | 5         | Minutes before sending partial batch           |
| `maxEmailsPerHour`        | int         | 20        | Rate limit per hour                            |
| `sendAsHtml`              | bool        | true      | Send HTML formatted emails                     |
| `includeStackTrace`       | bool        | true      | Include stack traces                           |
| `includeMetadata`         | bool        | true      | Include metadata                               |
| `groupByLevel`            | bool        | **false** | Group logs by level (v2.0 default change)      |
| `sendImmediatelyOnError`  | bool        | true      | Send immediately on errors                     |
| `immediateErrorThreshold` | int         | 10        | Error count to trigger immediate send          |

## Presets

### Critical Alert Preset

```dart
final appender = await emailAppenderBuilder()
  .withGmailAppPassword('alerts@gmail.com', 'xxxx-xxxx-xxxx-xxxx')
  .withTo(['oncall@example.com'])
  .withCriticalAlertPreset()
  .build();

// Configures:
// - Level: ERROR
// - Immediate sending on first error
// - Include full stack traces
// - Chronological order (not grouped)
// - Subject: [CRITICAL ALERT]
```

### Daily Digest Preset

```dart
final appender = await emailAppenderBuilder()
  .withSendGridApiKey('SG.xxxxx', 'reports@example.com')
  .withTo(['management@example.com'])
  .withDailyDigestPreset()
  .build();

// Configures:
// - Level: INFO
// - 24-hour batching
// - Group by level for summary
// - No immediate sending
// - Subject: [DAILY LOG DIGEST]
```

## Use Cases

### Production Error Monitoring

```dart
await LoggerBuilder()
  .file(filePattern: 'app', level: Level.INFO)
  .sendGridWithApiKey(
    apiKey: env['SENDGRID_API_KEY']!, // Use environment variables!
    fromEmail: 'errors@myapp.com',
    toEmails: ['oncall@myapp.com'],
    level: Level.ERROR,
    subjectPrefix: '[PROD ERROR]',
    batchSize: 5,
    sendImmediatelyOnError: true,
  )
  .build();
```

### Daily Summary Reports

```dart
await LoggerBuilder()
  .console(level: Level.INFO)
  .gmailWithAppPassword(
    emailAddress: 'reports@company.com',
    appPassword: env['GMAIL_APP_PASSWORD']!, // From environment
    toEmails: ['management@company.com'],
    level: Level.INFO,
    subjectPrefix: '[Daily Report]',
    batchSize: 1000,
    batchIntervalMinutes: 1440, // 24 hours
    sendImmediatelyOnError: false,
  )
  .build();
```

## Troubleshooting

### ❌ Authentication Failures

**Problem**: "Invalid credentials" or "Authentication failed"

**Solutions**:

1. **Gmail**: You MUST use an [app password](https://myaccount.google.com/apppasswords), not your
   Google password
2. **Outlook**: You MUST use an [app password](https://account.microsoft.com/security/) if 2FA is
   enabled
3. **Yahoo**: Requires an app password from Account Security settings
4. **SendGrid**: Use API key starting with 'SG.'
5. **Check for spaces**: Ensure no leading/trailing spaces in passwords

### Common Issues

1. **"Less secure apps" error**: This setting no longer exists. Use app passwords instead.
2. **Port issues**: Use 587 for TLS, 465 for SSL, 25 for unencrypted (not recommended)
3. **Rate limiting**: Reduce `maxEmailsPerHour` if hitting provider limits
4. **Large attachments**: Reduce `batchSize` or increase `batchIntervalMinutes`

### Enable Debug Logging

```dart
await LoggerBuilder()
  .withSelfDebug(Level.DEBUG)
  .email(/* config */)
  .build();
```

## Security Best Practices

1. **Never commit credentials**:
   ```dart
   // ✅ GOOD
   appPassword: env['GMAIL_APP_PASSWORD']!
   
   // ❌ BAD  
   appPassword: 'abcd-efgh-ijkl-mnop'
   ```

2. **Use app-specific passwords**: Never use your main account password

3. **Rotate credentials regularly**: Especially for production systems

4. **Limit recipients**: Use groups/aliases instead of individual emails

5. **Test configuration**: Use test mode during development:
   ```dart
   final appender = await emailAppenderBuilder()
       .withGmailAppPassword('test@gmail.com', 'test-password')
       .withTo(['test@example.com'])
       .build(test: true);  // No emails sent
   ```

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