import Logging

/// A protocol for logging D-Bus operations and diagnostics.
///
/// This protocol allows applications to provide their own logging implementation
/// to the D-Bus client, enabling better integration with application-specific
/// logging systems and debugging workflows.
///
/// ## Overview
///
/// The D-Bus client uses this protocol to log various operations including:
/// - Connection establishment and authentication
/// - Message encoding/decoding
/// - Error conditions and debugging information
/// - Protocol-level communication details
///
/// ## Default Implementation
///
/// A default implementation using swift-log's `Logger` is provided. Applications
/// can either use this default or provide their own custom implementation.
///
/// ## Example
/// ```swift
/// // Using default swift-log implementation
/// let logger = DefaultDBusLogger(label: "com.myapp.dbus")
///
/// // Using custom implementation
/// struct MyDBusLogger: DBusLogger {
///     func trace(_ message: String, file: String, function: String, line: UInt) {
///         MyLoggingSystem.log(level: .trace, message: message)
///     }
///
///     func debug(_ message: String, file: String, function: String, line: UInt) {
///         MyLoggingSystem.log(level: .debug, message: message)
///     }
///
///     // ... implement other methods
/// }
/// ```
public protocol DBusLogger: Sendable {
  /// Log a trace-level message (most verbose).
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - file: The file where the log was called (automatically filled)
  ///   - function: The function where the log was called (automatically filled)
  ///   - line: The line where the log was called (automatically filled)
  func trace(_ message: @autoclosure () -> String, file: String, function: String, line: UInt)

  /// Log a debug-level message.
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - file: The file where the log was called (automatically filled)
  ///   - function: The function where the log was called (automatically filled)
  ///   - line: The line where the log was called (automatically filled)
  func debug(_ message: @autoclosure () -> String, file: String, function: String, line: UInt)

  /// Log an info-level message.
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - file: The file where the log was called (automatically filled)
  ///   - function: The function where the log was called (automatically filled)
  ///   - line: The line where the log was called (automatically filled)
  func info(_ message: @autoclosure () -> String, file: String, function: String, line: UInt)

  /// Log a warning-level message.
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - file: The file where the log was called (automatically filled)
  ///   - function: The function where the log was called (automatically filled)
  ///   - line: The line where the log was called (automatically filled)
  func warning(_ message: @autoclosure () -> String, file: String, function: String, line: UInt)

  /// Log an error-level message.
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - file: The file where the log was called (automatically filled)
  ///   - function: The function where the log was called (automatically filled)
  ///   - line: The line where the log was called (automatically filled)
  func error(_ message: @autoclosure () -> String, file: String, function: String, line: UInt)

  /// Log a critical-level message (least verbose, most severe).
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - file: The file where the log was called (automatically filled)
  ///   - function: The function where the log was called (automatically filled)
  ///   - line: The line where the log was called (automatically filled)
  func critical(_ message: @autoclosure () -> String, file: String, function: String, line: UInt)
}

/// Convenience extensions for DBusLogger that provide default parameter values.
extension DBusLogger {
  /// Log a trace-level message (most verbose).
  public func trace(
    _ message: @autoclosure () -> String, file: String = #file, function: String = #function,
    line: UInt = #line
  ) {
    trace(message(), file: file, function: function, line: line)
  }

  /// Log a debug-level message.
  public func debug(
    _ message: @autoclosure () -> String, file: String = #file, function: String = #function,
    line: UInt = #line
  ) {
    debug(message(), file: file, function: function, line: line)
  }

  /// Log an info-level message.
  public func info(
    _ message: @autoclosure () -> String, file: String = #file, function: String = #function,
    line: UInt = #line
  ) {
    info(message(), file: file, function: function, line: line)
  }

  /// Log a warning-level message.
  public func warning(
    _ message: @autoclosure () -> String, file: String = #file, function: String = #function,
    line: UInt = #line
  ) {
    warning(message(), file: file, function: function, line: line)
  }

  /// Log an error-level message.
  public func error(
    _ message: @autoclosure () -> String, file: String = #file, function: String = #function,
    line: UInt = #line
  ) {
    error(message(), file: file, function: function, line: line)
  }

  /// Log a critical-level message (least verbose, most severe).
  public func critical(
    _ message: @autoclosure () -> String, file: String = #file, function: String = #function,
    line: UInt = #line
  ) {
    critical(message(), file: file, function: function, line: line)
  }
}

/// Default implementation of ``DBusLogger`` using swift-log's `Logger`.
///
/// This implementation forwards all logging calls to a swift-log `Logger` instance,
/// providing a convenient default for applications already using swift-log.
///
/// ## Example
/// ```swift
/// let logger = DefaultDBusLogger(label: "com.myapp.dbus")
/// let client = try await DBusClient.withConnection(to: address, auth: .anonymous, logger: logger) { ... }
/// ```
public struct DefaultDBusLogger: DBusLogger {
  private let logger: Logger

  /// Creates a new default logger with the specified label.
  ///
  /// - Parameter label: The label to use for the underlying swift-log Logger
  public init(label: String) {
    self.logger = Logger(label: label)
  }

  /// Creates a new default logger wrapping an existing swift-log Logger.
  ///
  /// - Parameter logger: The swift-log Logger to wrap
  public init(logger: Logger) {
    self.logger = logger
  }

  public func trace(
    _ message: @autoclosure () -> String, file: String = #file, function: String = #function,
    line: UInt = #line
  ) {
    logger.trace(
      Logger.Message(stringLiteral: message()), file: file, function: function, line: line)
  }

  public func debug(
    _ message: @autoclosure () -> String, file: String = #file, function: String = #function,
    line: UInt = #line
  ) {
    logger.debug(
      Logger.Message(stringLiteral: message()), file: file, function: function, line: line)
  }

  public func info(
    _ message: @autoclosure () -> String, file: String = #file, function: String = #function,
    line: UInt = #line
  ) {
    logger.info(
      Logger.Message(stringLiteral: message()), file: file, function: function, line: line)
  }

  public func warning(
    _ message: @autoclosure () -> String, file: String = #file, function: String = #function,
    line: UInt = #line
  ) {
    logger.warning(
      Logger.Message(stringLiteral: message()), file: file, function: function, line: line)
  }

  public func error(
    _ message: @autoclosure () -> String, file: String = #file, function: String = #function,
    line: UInt = #line
  ) {
    logger.error(
      Logger.Message(stringLiteral: message()), file: file, function: function, line: line)
  }

  public func critical(
    _ message: @autoclosure () -> String, file: String = #file, function: String = #function,
    line: UInt = #line
  ) {
    logger.critical(
      Logger.Message(stringLiteral: message()), file: file, function: function, line: line)
  }
}

/// A no-op logger that discards all log messages.
///
/// This logger can be used when logging is not desired or during testing
/// when log output would be distracting.
///
/// ## Example
/// ```swift
/// let client = try await DBusClient.withConnection(to: address, auth: .anonymous, logger: NoOpDBusLogger()) { ... }
/// ```
public struct NoOpDBusLogger: DBusLogger {
  /// Creates a new no-op logger.
  public init() {}

  public func trace(
    _ message: @autoclosure () -> String, file: String = #file, function: String = #function,
    line: UInt = #line
  ) {}
  public func debug(
    _ message: @autoclosure () -> String, file: String = #file, function: String = #function,
    line: UInt = #line
  ) {}
  public func info(
    _ message: @autoclosure () -> String, file: String = #file, function: String = #function,
    line: UInt = #line
  ) {}
  public func warning(
    _ message: @autoclosure () -> String, file: String = #file, function: String = #function,
    line: UInt = #line
  ) {}
  public func error(
    _ message: @autoclosure () -> String, file: String = #file, function: String = #function,
    line: UInt = #line
  ) {}
  public func critical(
    _ message: @autoclosure () -> String, file: String = #file, function: String = #function,
    line: UInt = #line
  ) {}
}
