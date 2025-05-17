# DBusSwift


[![Swift 6.0.0](https://img.shields.io/badge/Swift-6.0.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-Linux-green.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)
[![Linux](https://img.shields.io/github/actions/workflow/status/apache-edge/dbus/swift.yml?branch=main&label=Linux)](https://github.com/apache-edge/dbus/actions/workflows/swift.yml)

A Swift 6 wrapper for the D-Bus C library with support for modern Swift concurrency.

## Overview

DBusSwift is a Swift package that provides a Swift-friendly interface to D-Bus, a message bus system used for interprocess communication on Linux systems. This library enables Swift applications to communicate with system services and other applications on Linux.

## Features

- Modern Swift 6 API with full async/await support
- Proper memory management with automatic resource cleanup
- Type-safe argument handling
- Support for method calls, signals, and replies
- Comprehensive error handling
- Fully documented API with DocC comments

## Requirements

- Swift 6.0 or later
- libdbus-1-dev package installed

### Platform Support

DBusSwift is designed specifically for Linux environments where D-Bus is natively available. D-Bus is a core component of Linux desktop environments and is not natively supported on other platforms.

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
    .package(url: "https://github.com/edgeengineer/dbus.git", from: "0.0.1")
]
```

Then add the dependency to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: ["DBusSwift"]),
```

### Linux Dependencies

#### For Development
If you're developing applications with DBusSwift or building the package from source, you need the D-Bus development package:

```bash
sudo apt-get install libdbus-1-dev
```

#### For Runtime Only
If you're only running applications that use DBusSwift (e.g., distributing a compiled application), you only need the runtime library:

```bash
sudo apt-get install libdbus-1-3
```

## Usage

### Connecting to D-Bus

```swift
import DBusSwift

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
do {
    let dbus = try DBusAsync(busType: .session)
    // Use dbus...
} catch let error as DBusConnectionError {
    switch error {
    case .connectionFailed(let reason):
        print("Connection failed: \(reason)")
    case .messageFailed(let reason):
        print("Message failed: \(reason)")
    case .invalidReply(let reason):
        print("Invalid reply: \(reason)")
    }
} catch {
    print("Other error: \(error)")
}
```

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
| Array      | a         | [Any]      |
| Variant    | v         | Any        |

## Testing

DBusSwift includes comprehensive tests using Swift Testing. The tests are designed to run on Linux.

### Running Tests

```bash
swift test
```

## License

This project is available under the Apache License 2.0. See the LICENSE file for more info.