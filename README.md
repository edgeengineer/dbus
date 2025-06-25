# DBUS


[![Swift 6.0.0](https://img.shields.io/badge/Swift-6.0.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-Linux-green.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)
[![Linux](https://img.shields.io/github/actions/workflow/status/apache-edge/dbus/swift.yml?branch=main&label=Linux)](https://github.com/apache-edge/dbus/actions/workflows/swift.yml)

A Swift 6 D-Bus protocol implementation with SwiftNIO and modern Swift concurrency support.

## Overview

DBUS is a Swift package that provides a pure Swift implementation of the D-Bus protocol built on SwiftNIO. D-Bus is a message bus system used for interprocess communication on Linux systems. This library enables Swift applications to communicate with system services and other applications using modern Swift concurrency features.

## Features

- **Pure Swift Implementation**: No C library dependencies, built entirely on SwiftNIO
- **Modern Swift 6 API**: Full async/await support with Swift concurrency
- **Complete D-Bus Protocol**: Message parsing, authentication, and type system
- **Type-Safe Interface**: Swift types mapped to D-Bus types with compile-time safety
- **SwiftNIO Foundation**: High-performance networking with proper resource management
- **Authentication Support**: ANONYMOUS and EXTERNAL authentication methods
- **Comprehensive Testing**: Full test coverage with real-world scenarios
- **Well Documented**: DocC comments and extensive usage examples

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
    auth: .external(userID: getuid())
) { connection in
    // You've got a DBUS connection!
}
```

### Calling a Method

```swift
try await DBusClient.withConnection(
    to: SocketAddress(unixDomainSocketPath: "/var/run/dbus/system_bus_socket"),
    auth: .external(userID: getuid())
) { connection in
    // Send a method call and get reply
    let reply = try await connection.send(DBusRequest.createMethodCall(
        destination: "org.freedesktop.DBus",
        path: "/org/freedesktop/DBus", 
        interface: "org.freedesktop.DBus",
        method: "ListNames"
    ))
    
    // Handle the reply
    if let reply = reply {
        print("Received reply: \(reply)")
    }
}
```

### Sending a Signal

```swift
try await DBusClient.withConnection(
    to: SocketAddress(unixDomainSocketPath: "/var/run/dbus/session_bus_socket"),
    auth: .external(userID: getuid())
) { connection in
    // Create and send a signal
    let signal = DBusRequest.createSignal(
        path: "/org/example/Path",
        interface: "org.example.Interface", 
        name: "ExampleSignal"
    )
    try await connection.send(signal)
}
```

### Working with D-Bus Types

```swift
// D-Bus types are represented as DBusValue
let stringValue = DBusValue.string("Hello")
let intValue = DBusValue.uint32(42)
let arrayValue = DBusValue.array([stringValue, intValue])

// Create requests with typed arguments
let request = DBusRequest.createMethodCall(
    destination: "org.freedesktop.DBus",
    path: "/org/freedesktop/DBus",
    interface: "org.freedesktop.DBus", 
    method: "GetConnectionUnixProcessID",
    body: [DBusValue.string("org.freedesktop.DBus")]
)
```

### Handling Errors

```swift
try await DBusClient.withConnection(
    to: SocketAddress(unixDomainSocketPath: "/var/run/dbus/system_bus_socket"),
    auth: .external(userID: "0") // root user
) { connection in
    // Send request
    let reply = try await connection.send(DBusRequest.createMethodCall(
        destination: "org.freedesktop.DBus",
        path: "/org/freedesktop/DBus",
        interface: "org.freedesktop.DBus",
        method: "Hello"
    ))

    guard 
        let helloReply = reply,
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

DBUS maps D-Bus types to Swift types as follows:

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

## Limitations and Missing Features

While DBUS provides a solid foundation for D-Bus communication, some features are not yet implemented:

### **Not Yet Implemented**
- **Signal Subscription**: No built-in signal filtering and callback registration
- **Service Registration**: Cannot expose Swift objects as D-Bus services  
- **Introspection Support**: No XML parsing or automatic proxy generation
- **Connection Pooling**: Limited to single-use connections
- **Standard Interfaces**: No built-in support for `org.freedesktop.DBus.Properties`, `org.freedesktop.DBus.Introspectable`, etc.
- **Bus Name Management**: No automatic name reservation or ownership monitoring
- **Property Interface**: Basic property access only, no caching or change notifications
- **High-Level API**: Currently requires low-level message construction

### **Known Issues**
- Empty arrays default to byte array type signature regardless of intended type
- Complex nested dictionary structures may have parsing edge cases
- Message serial number overflow not handled
- Authentication handler has potential race conditions

### **Planned Features**
Future releases may include:
- Higher-level convenience APIs
- Signal subscription and routing
- Service registration capabilities  
- Introspection and proxy generation
- Connection management improvements

## Testing

DBUS includes comprehensive tests using Swift Testing. The tests are designed to run on Linux and include real-world scenarios with NetworkManager integration.

### Running Tests

```bash
swift test
```

## License

This project is available under the Apache License 2.0. See the LICENSE file for more info.