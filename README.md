# DBusSwift

A Swift 6 wrapper for the D-Bus C library with support for modern Swift concurrency.

## Overview

DBusSwift is a cross-platform Swift package that provides a Swift-friendly interface to D-Bus, a message bus system used for interprocess communication on Linux systems. This library enables Swift applications to communicate with system services and other applications on Linux.

## Features

- Modern Swift 6 API with full async/await support
- Cross-platform compatibility (tested on Linux)
- Proper memory management with automatic resource cleanup
- Type-safe argument handling
- Support for method calls, signals, and replies
- Comprehensive error handling
- Fully documented API

## Requirements

- Swift 6.0 or later
- On Linux: libdbus-1-dev package installed

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/apache-edge/dbus.git", from: "0.0.1")
]
```

Then add the dependency to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: ["DBusSwift"]),
```

### Linux Dependencies

On Linux, you need to install the D-Bus development package:

```bash
sudo apt-get install libdbus-1-dev
```

## Usage

### Connecting to D-Bus

```swift
import DBusSwift

// Connect to the session bus
let sessionBus = try DBusAsync()

// Or connect to the system bus
let systemBus = try DBusAsync(busType: DBUS_BUS_SYSTEM)
```

### Calling a Method

```swift
// Call ListNames method on the D-Bus service
let result = try await dbus.callMethod(
    destination: "org.freedesktop.DBus",
    path: "/org/freedesktop/DBus",
    interface: "org.freedesktop.DBus",
    method: "ListNames",
    replySignature: "as"
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
try await dbus.emitSignal(
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
let result = try await dbus.callMethod(
    destination: "org.freedesktop.DBus",
    path: "/org/freedesktop/DBus",
    interface: "org.freedesktop.DBus",
    method: "GetConnectionUnixProcessID",
    args: ["org.freedesktop.DBus"],
    signature: "s",
    replySignature: "u"
)

if let pid = result.first as? UInt32 {
    print("The D-Bus daemon's PID is: \(pid)")
}
```

### Handling Errors

```swift
do {
    let dbus = try DBusAsync()
    // Use dbus...
} catch let error as DBusError {
    switch error {
    case .connectionFailed(let reason):
        print("Connection failed: \(reason)")
    case .messageFailed(let reason):
        print("Message failed: \(reason)")
    case .invalidReply(let reason):
        print("Invalid reply: \(reason)")
    case .notSupported:
        print("Operation not supported")
    }
} catch {
    print("Other error: \(error)")
}
```

## D-Bus Type Signatures

DBusSwift maps D-Bus types to Swift types as follows:

| D-Bus Type | Signature | Swift Type |
|------------|-----------|------------|
| String     | s         | String     |
| Int32      | i         | Int32      |
| UInt32     | u         | UInt32     |
| Boolean    | b         | Bool       |
| Double     | d         | Double     |

More complex types will be added in future versions.

## License

This project is available under the Apache License 2.0. See the LICENSE file for more info.