import Foundation
import Testing

@testable import DBusSwift

struct TestMessage {
  let level: String
  let message: String
  let file: String
  let function: String
  let line: UInt
}

actor TestDBusLogger: DBusLogger {
  private var messages: [TestMessage] = []

  init() {}

  func getMessages() -> [TestMessage] {
    return messages
  }

  func clearMessages() {
    messages.removeAll()
  }

  nonisolated func trace(
    _ message: @autoclosure () -> String, file: String, function: String, line: UInt
  ) {
    let messageText = message()
    Task {
      await addMessage(
        TestMessage(
          level: "trace", message: messageText, file: file, function: function, line: line))
    }
  }

  nonisolated func debug(
    _ message: @autoclosure () -> String, file: String, function: String, line: UInt
  ) {
    let messageText = message()
    Task {
      await addMessage(
        TestMessage(
          level: "debug", message: messageText, file: file, function: function, line: line))
    }
  }

  nonisolated func info(
    _ message: @autoclosure () -> String, file: String, function: String, line: UInt
  ) {
    let messageText = message()
    Task {
      await addMessage(
        TestMessage(level: "info", message: messageText, file: file, function: function, line: line)
      )
    }
  }

  nonisolated func warning(
    _ message: @autoclosure () -> String, file: String, function: String, line: UInt
  ) {
    let messageText = message()
    Task {
      await addMessage(
        TestMessage(
          level: "warning", message: messageText, file: file, function: function, line: line))
    }
  }

  nonisolated func error(
    _ message: @autoclosure () -> String, file: String, function: String, line: UInt
  ) {
    let messageText = message()
    Task {
      await addMessage(
        TestMessage(
          level: "error", message: messageText, file: file, function: function, line: line))
    }
  }

  nonisolated func critical(
    _ message: @autoclosure () -> String, file: String, function: String, line: UInt
  ) {
    let messageText = message()
    Task {
      await addMessage(
        TestMessage(
          level: "critical", message: messageText, file: file, function: function, line: line))
    }
  }

  private func addMessage(_ message: TestMessage) {
    messages.append(message)
  }
}

@Test("DefaultDBusLogger forwards to swift-log Logger")
func testDefaultDBusLogger() {
  let logger = DefaultDBusLogger(label: "test.logger")

  // These calls should not crash and should forward to the underlying Logger
  logger.trace("trace message")
  logger.debug("debug message")
  logger.info("info message")
  logger.warning("warning message")
  logger.error("error message")
  logger.critical("critical message")
}

@Test("NoOpDBusLogger discards all messages")
func testNoOpDBusLogger() {
  let logger = NoOpDBusLogger()

  // These calls should not crash and should be no-ops
  logger.trace("trace message")
  logger.debug("debug message")
  logger.info("info message")
  logger.warning("warning message")
  logger.error("error message")
  logger.critical("critical message")
}

@Test("Custom logger receives all log levels")
func testCustomLogger() async {
  let logger = TestDBusLogger()

  logger.trace("trace message")
  logger.debug("debug message")
  logger.info("info message")
  logger.warning("warning message")
  logger.error("error message")
  logger.critical("critical message")

  // Give the tasks time to complete
  try? await Task.sleep(for: .milliseconds(10))

  let messages = await logger.getMessages()
  #expect(messages.count == 6)

  #expect(messages[0].level == "trace")
  #expect(messages[0].message == "trace message")

  #expect(messages[1].level == "debug")
  #expect(messages[1].message == "debug message")

  #expect(messages[2].level == "info")
  #expect(messages[2].message == "info message")

  #expect(messages[3].level == "warning")
  #expect(messages[3].message == "warning message")

  #expect(messages[4].level == "error")
  #expect(messages[4].message == "error message")

  #expect(messages[5].level == "critical")
  #expect(messages[5].message == "critical message")
}

@Test("Logger preserves file, function, and line information")
func testLoggerMetadata() async {
  let logger = TestDBusLogger()

  logger.info("test message")  // This will capture the current file/function/line

  // Give the task time to complete
  try? await Task.sleep(for: .milliseconds(10))

  let messages = await logger.getMessages()
  #expect(messages.count == 1)

  let message = messages[0]
  #expect(message.level == "info")
  #expect(message.message == "test message")
  #expect(message.file.contains("DBusLoggerTests.swift"))
  #expect(message.function == "testLoggerMetadata()")
  #expect(message.line > 0)
}
