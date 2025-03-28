# DBusSwift


[![Swift 6.0.0](https://img.shields.io/badge/Swift-6.0.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20|%20Linux%20)](https://swift.org)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)
[![macOS](https://img.shields.io/github/actions/workflow/status/apache-edge/dbus/swift.yml?branch=main&label=macOS)](https://github.com/apache-edge/dbus/actions/workflows/swift.yml)
[![Linux](https://img.shields.io/github/actions/workflow/status/apache-edge/dbus/swift.yml?branch=main&label=Linux)](https://github.com/apache-edge/dbus/actions/workflows/swift.yml)

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
- Fully documented API with DocC comments

## Requirements

- Swift 6.0 or later
- On Linux: libdbus-1-dev package installed

### Platform Support

#### Linux
D-Bus is natively supported on Linux and is the primary target platform for this library. All functionality is available on Linux systems with D-Bus installed.

#### macOS
macOS does not natively include D-Bus, but you can install it via Homebrew:

```bash
brew install dbus
```

After installation, you need to start the D-Bus daemon:

```bash
brew services start dbus
```

Note that while the library can be built on macOS for development purposes, some functionality may be limited compared to Linux. The test suite automatically skips D-Bus-specific tests on macOS.

Important: If you're working on this codebase on a macOS machine, you will need to install D-Bus and start the D-Bus daemon as described above or else the tests will fail.

#### Other Platforms
Other platforms like Windows are not currently supported for running D-Bus, but the package can still be built on these platforms for cross-compilation purposes.

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

### Using Combine Extensions

DBusSwift provides Combine extensions for reactive programming on Apple platforms. These extensions are conditionally compiled and only available when Combine is supported.

You will need to install dbus with `homebrew install dbus` and run it in the background with `brew services start dbus`.

```swift
import DBusSwift
import Combine

// Create a publisher for D-Bus signals
let connection = try DBusConnection(busType: .session)
let signalPublisher = connection.signalPublisher(
    interface: "org.freedesktop.DBus",
    member: "NameOwnerChanged"
)

// Subscribe to signals
var cancellables = Set<AnyCancellable>()
signalPublisher
    .sink(
        receiveCompletion: { completion in
            if case .failure(let error) = completion {
                print("Error: \(error)")
            }
        },
        receiveValue: { signal in
            print("Received signal: \(signal)")
        }
    )
    .store(in: &cancellables)

// Create a publisher for method calls
let dbusAsync = try DBusAsync(busType: .session)
let callPublisher = await dbusAsync.callPublisher(
    destination: "org.freedesktop.DBus",
    path: "/org/freedesktop/DBus",
    interface: "org.freedesktop.DBus",
    method: "ListNames"
)

// Subscribe to method call results
callPublisher
    .sink(
        receiveCompletion: { completion in
            if case .failure(let error) = completion {
                print("Error: \(error)")
            }
        },
        receiveValue: { result in
            print("Method call result: \(result)")
        }
    )
    .store(in: &cancellables)
```

Note: While the Combine extensions are available on macOS, the actual D-Bus functionality requires a D-Bus daemon to be running. On macOS, you'll need to install D-Bus via Homebrew as described in the Platform Support section.

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

DBusSwift includes comprehensive integration tests using Swift Testing. The tests are conditionally compiled to run only on Linux platforms where D-Bus is available.

### Running Tests

```bash
swift test
```

On non-Linux platforms, the tests will be skipped with appropriate messages.

### macOS Testing Considerations

When developing on macOS, you can:

1. **Build and run the non-D-Bus parts of your tests**: The test suite is designed to skip D-Bus-specific tests on macOS.

2. **Use a Linux VM or container**: For full testing, consider using a Linux virtual machine or container.

3. **Use CI/CD**: The GitHub Actions workflow included with this package automatically tests on Linux platforms.

### Writing Tests for D-Bus Applications

When writing tests for your own applications that use DBusSwift, follow this pattern:

```swift
import Testing
@testable import DBusSwift

@Suite("Your D-Bus Tests")
struct YourDBusTests {
    #if os(Linux)
    @Test("Test D-Bus Connection")
    func testDBusConnection() throws {
        let dbus = try DBusAsync(busType: .session)
        // Your test code here
        #expect(dbus != nil)
    }
    #else
    @Test("Skip on Non-Linux")
    func testSkipOnNonLinux() {
        print("Skipping D-Bus tests on non-Linux platform")
    }
    #endif
}
```

## License

This project is available under the Apache License 2.0. See the LICENSE file for more info.