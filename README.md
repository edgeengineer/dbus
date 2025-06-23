# DBusSwift


[![Swift 6.0.0](https://img.shields.io/badge/Swift-6.0.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-Linux-green.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)
[![Linux](https://img.shields.io/github/actions/workflow/status/apache-edge/dbus/swift.yml?branch=main&label=Linux)](https://github.com/apache-edge/dbus/actions/workflows/swift.yml)

A Swift 6 wrapper for the D-Bus C library with support for modern Swift concurrency.

## Overview

DBUS is a Swift package that provides a Swift-friendly interface to D-Bus, a message bus system used for interprocess communication on Linux systems. This library enables Swift applications to communicate with system services and other applications on Linux.

## Features

- Modern Swift 6 API with full async/await support
- Proper memory management with automatic resource cleanup
- Type-safe argument handling
- Support for method calls, signals, and replies
- Comprehensive error handling
- Fully documented API with DocC comments

## Requirements

- Swift 6.0 or later

### Platform Support

DBUS is designed specifically for Linux environments where D-Bus is natively available. D-Bus is a core component of Linux desktop environments and is not natively supported on other platforms.

#### Docker Testing

For development and testing on non-Linux platforms, a Docker environment is provided:

```bash
# Run tests in Docker
./run-tests-in-docker.sh
```

This will build a Docker container with all necessary dependencies and run the test suite in a Linux environment.

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/edgeengineer/dbus.git", from: "0.1.0")
]
```

Then add the dependency to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: ["DBUS"]),
```

## Usage

### Connecting to D-Bus

```swift
import DBUS

try await DBusClient.withConnection(
    to: SocketAddress(unixDomainSocketPath: "/var/run/dbus/system_bus_socket"),
    auth: .external(userID: uid)
) { replies, send in
    // You've got a DBUS connection!
}
// Connect to the session bus
let sessionBus = try DBusAsync(busType: .session)

// Or connect to the system bus
let systemBus = try DBusAsync(busType: .system)
```

### Calling a Method

```swift
// Call ListNames method on the D-Bus service
let result = try await sessionBus.call(
    destination: "org.freedesktop.DBus",
    path: "/org/freedesktop/DBus",
    interface: "org.freedesktop.DBus",
    method: "ListNames"
)

// The result is an array of Any type, but we know it's an array of strings
if let services = result.first as? [String] {
    print("Available D-Bus services:")
    for service in services {
        print("- \(service)")
    }
}
```

### Emitting a Signal

```swift
// Emit a signal
try await sessionBus.emitSignal(
    path: "/org/example/Path",
    interface: "org.example.Interface",
    name: "ExampleSignal",
    args: ["Hello from Swift!", 42],
    signature: "si"
)
```

### Calling a Method with Arguments

```swift
// Call GetConnectionUnixProcessID to get the PID of a connection
let result = try await sessionBus.call(
    destination: "org.freedesktop.DBus",
    path: "/org/freedesktop/DBus",
    interface: "org.freedesktop.DBus",
    method: "GetConnectionUnixProcessID",
    args: ["org.freedesktop.DBus"],
    signature: "s"
)

if let pid = result.first as? UInt32 {
    print("The D-Bus daemon's PID is: \(pid)")
}
```

### Handling Errors

```swift
try await DBusClient.withConnection(
    to: SocketAddress(unixDomainSocketPath: "/var/run/dbus/system_bus_socket"),
    auth: .external(userID: "0") // root user
) { replies, send in
    // Send request
    try await send(DBusMessage.createMethodCall(
        destination: "org.freedesktop.DBus",
        path: "/org/freedesktop/DBus",
        interface: "org.freedesktop.DBus",
        method: "Hello",
        serial: 1
    ))

    guard 
        let helloReply = try await replies.next(),
        case .methodReturn = helloReply.messageType
    else {
        print("No reply from Hello method call")
        return
    }

    print("Received reply from Hello method call \(helloReply)")
}
```

### Using Logging

DBUS logs to [swift-log](https://github.com/swiftlang/swift-log) to help with debugging and understanding internal operations. You can provide your own logger implementation or use the standard adapters. We'll log to `.debug` and `.trace` levels in compliant with [established standards](https://www.swift.org/documentation/server/guides/libraries/log-levels.html).

## D-Bus Type Signatures

DBusSwift maps D-Bus types to Swift types as follows:

| D-Bus Type | Signature | Swift Type |
|------------|-----------|------------|
| Byte       | y         | UInt8      |
| Boolean    | b         | Bool       |
| Int16      | n         | Int16      |
| UInt16     | q         | UInt16     |
| Int32      | i         | Int32      |
| UInt32     | u         | UInt32     |
| Int64      | x         | Int64      |
| UInt64     | t         | UInt64     |
| Double     | d         | Double     |
| String     | s         | String     |
| Object Path| o         | String     |
| Signature  | g         | String     |
| Array      | a         | [DBusValue]|
| Variant    | v         | DBusVariant|

## Testing

DBusSwift includes comprehensive tests using Swift Testing. The tests are designed to run on Linux.

### Running Tests

```bash
swift test
```

## License

This project is available under the Apache License 2.0. See the LICENSE file for more info.