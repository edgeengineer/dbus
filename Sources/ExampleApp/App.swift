import DBusSwift
import NIO
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#elseif canImport(Musl)
import Musl
#endif

@available(macOS 14.0, *)
@main
struct App {
    static func main() async throws {
        do {
            // let uid = String(getuid())
            let uid = "0"
            try await DBusClient.withConnection(
                to: SocketAddress(unixDomainSocketPath: "/var/run/dbus/system_bus_socket"),
                auth: .external(userID: uid)
            ) { inbound, outbound in
                try await outbound.write(DBusMessage.createMethodCall(
                    destination: "org.freedesktop.DBus",
                    path: "/org/freedesktop/DBus",
                    interface: "org.freedesktop.DBus",
                    method: "Hello",
                    serial: 1
                ))

                var iter = inbound.makeAsyncIterator()

                guard let helloReply = try await iter.next() else { 
                    print("No reply from Hello method call")
                    return
                }

                guard case .methodReturn = helloReply.messageType else {
                    print("Unexpected message type from Hello method call")
                    return
                }

                print("Received reply from Hello method call \(helloReply)")
                
                print("DBus client connected as UID \(uid)")

                // try await outbound.write(DBusMessage.createMethodCall(
                //     destination: "org.freedesktop.DBus",
                //     path: "/org/freedesktop/DBus",
                //     interface: "org.freedesktop.DBus",
                //     method: "ListNames",
                //     serial: 2
                // ))

                var serial: UInt32 = 2
                func nextSerial() -> UInt32 {
                    defer { serial += 1 }
                    return serial
                }

                func sendRequest(
                    withSerial: (UInt32) throws -> DBusMessage
                ) async throws -> DBusMessage {
                    let serial = nextSerial()
                    let message = try withSerial(serial)
                    try await outbound.write(message)
                    while let reply = try await iter.next() {
                        guard reply.replyTo == serial else {
                            continue
                        }
                        
                        return reply
                    }

                    throw CancellationError()
                }

                let scanReply = try await sendRequest { serial in
                    NetworkManager.scanAPs(devicePath: "/org/freedesktop/NetworkManager/Devices/6", serial: serial)
                }

                guard case .array(let aps) = scanReply.body.first else {
                    print("Unexpected arguments from Scan reply")
                    return
                }

                var hostnames = [(ssid: String, path: String)]()
                for ap in aps {
                    guard case .objectPath(let apPath) = ap else {
                        print("Unexpected arguments from Scan reply")
                        continue
                    }

                    let apObject = try await sendRequest { serial in
                        NetworkManager.getSSID(apPath: apPath, serial: serial)
                    }

                    guard
                        case .variant(let ssidVariant) = apObject.body.first,
                        case .array(let ssidBytes) = ssidVariant.value
                    else {
                        print("Unexpected arguments from GetSSID reply")
                        continue
                    }

                    let ssid = ssidBytes.compactMap { value -> UInt8? in
                        guard case .byte(let byte) = value else {
                            return nil
                        }

                        return byte
                    }

                    if let ssid = String(bytes: ssid, encoding: .utf8) {
                        hostnames.append((ssid, apPath))
                    }
                }

                print(hostnames)

                if let (name, path) = hostnames.first(where: { $0.ssid == "Orlandos Wifi" }) {
                    let reply = try await sendRequest { serial in
                        NetworkManager.connect(
                            networkDevicePath: "/org/freedesktop/NetworkManager/Devices/6",
                            apPath: path,
                            apName: name,
                            password: "",
                            serial: serial
                        )
                    }

                    print(reply)
                }
            }
        } catch {
            print("DBus error: \(error)")
            exit(1)
        }
    }
}

/// Helper for NetworkManager D-Bus API
public struct NetworkManager {
    /// Create a D-Bus message to request a Wi-Fi scan on a given device
    /// - Parameters:
    ///   - devicePath: The object path of the wireless device (e.g. "/org/freedesktop/NetworkManager/Devices/0")
    ///   - serial: The D-Bus serial number to use
    /// - Returns: A DBusMessage for the Scan method
    public static func scanAPs(devicePath: String, serial: UInt32) -> DBusMessage {
        return DBusMessage.createMethodCall(
            destination: "org.freedesktop.NetworkManager",
            path: devicePath,
            interface: "org.freedesktop.NetworkManager.Device.Wireless",
            method: "GetAllAccessPoints",
            serial: serial
        )
    }

    public static func getSSID(apPath: String, serial: UInt32) -> DBusMessage {
        return DBusMessage.createMethodCall(
            destination: "org.freedesktop.NetworkManager",
            path: apPath,
            interface: "org.freedesktop.DBus.Properties",
            method: "Get",
            serial: serial,
            body: [DBusValue.string("org.freedesktop.NetworkManager.AccessPoint"), DBusValue.string("Ssid")]
        )
    }

    public static func connect(
        networkDevicePath: String,
        apPath: String,
        apName: String,
        password: String,
        serial: UInt32
    ) -> DBusMessage {
        return DBusMessage.createMethodCall(
            destination: "org.freedesktop.NetworkManager",
            path: apPath,
            interface: "org.freedesktop.NetworkManager",
            method: "AddAndActivateConnection",
            serial: serial,
            body: [
                .array([
                    .dictionary([
                        .string("connection"): .array([
                            .dictionary([
                                .string("id"): .string(apName)
                            ]),
                            .dictionary([
                                .string("type"): .string("802-11-wireless")
                            ]),
                            .dictionary([
                                .string("uuid"): .string(UUID().uuidString)
                            ]),
                            .dictionary([
                                .string("autoconnect"): .boolean(true)
                            ]),
                        ])
                    ]),
                    .dictionary([
                        .string("802-11-wireless"): .array([
                            .dictionary([
                                .string("ssid"): .array(apName.utf8.map { DBusValue.byte($0) })
                            ]),
                            .dictionary([
                                .string("mode"): .string("infrastructure")
                            ]),
                        ])
                    ]),
                    .dictionary([
                        .string("802-11-wireless-security"): .array([
                            .dictionary([
                                .string("key-mgmt"): .string("wpa-psk")
                            ]),
                            .dictionary([
                                .string("psk"): .string(password)
                            ]),
                        ])
                    ]),
                    .dictionary([
                        .string("ipv4"): .array([
                            .dictionary([
                                .string("method"): .string("auto")
                            ]),
                        ])
                    ]),
                    .dictionary([
                        .string("ipv6"): .array([
                            .dictionary([
                                .string("method"): .string("auto")
                            ]),
                        ])
                    ]),
                ]),
                .objectPath(networkDevicePath),
                .objectPath(apPath),
            ]
        )
    }
}
