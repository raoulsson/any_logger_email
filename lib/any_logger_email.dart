library any_logger_email;

import 'package:any_logger/any_logger.dart';

// Import the implementation files
import 'src/email_appender.dart';

// Export public APIs
export 'src/email_appender.dart';
export 'src/email_appender_builder.dart';
export 'src/email_logger_builder_extension.dart';
export 'src/email_presets_extension.dart';

/// Extension initialization for Email appender.
///
/// This registers the EMAIL appender type with the AnyLogger registry,
/// allowing it to be used in configuration files and builders.
class AnyLoggerEmailExtension {
  static bool _registered = false;

  /// Registers the Email appender with the AnyLogger registry.
  ///
  /// This is called automatically when the package is imported.
  /// Calling it multiple times is safe - it will only register once.
  static void register() {
    if (_registered) return;

    AppenderRegistry.instance.register(EmailAppender.appenderName, (config,
        {test = false, date}) async {
      return await EmailAppender.fromConfig(config, test: test, date: date);
    });

    _registered = true;

    // Log registration if self-debugging is enabled
    Logger.getSelfLogger()
        ?.logDebug('EMAIL appender registered with AppenderRegistry');
  }

  /// Unregisters the Email appender (mainly for testing).
  static void unregister() {
    AppenderRegistry.instance.unregister(EmailAppender.appenderName);
    _registered = false;
  }

  /// Check if the appender is registered
  static bool get isRegistered => _registered;
}

// Auto-register when the library is imported
// Use a simple static initialization that Dart guarantees to run
class _Init {
  static final _instance = _Init._();

  _Init._() {
    AnyLoggerEmailExtension.register();
  }
}

// Force initialization by accessing the singleton
final ensureInitialized = _Init._instance;
