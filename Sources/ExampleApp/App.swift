import DBUS
import NIOCore

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
      ) { connection in
        guard
          let devicesReply = try await connection.send(NetworkManager.getDevices()),
          let bodyValue = devicesReply.body.first,
          let devices = bodyValue.array
        else {
          print("No body in GetDevices reply")
          return
        }

        let devicePaths: [String] = devices.compactMap(\.objectPath)

        print("Found \(devicePaths.count) devices")

        // Find the Wi-Fi device by checking device type
        var wifiDevicePath: String? = nil
        for devicePath in devicePaths {
          guard
            let deviceTypeReply = try await connection.send(
              NetworkManager.getDeviceType(devicePath: devicePath)),
            let typeValue = deviceTypeReply.body.first,
            let type = typeValue.uint32,
            type == 2  // NM_DEVICE_TYPE_WIFI = 2
          else {
            print("No body in GetDeviceType reply for device \(devicePath)")
            continue
          }

          wifiDevicePath = devicePath
          print("Found Wi-Fi device at \(devicePath)")
          break
        }

        guard let wifiDevicePath = wifiDevicePath else {
          print("No Wi-Fi device found")
          return
        }

        // Now use the correct Wi-Fi device path
        guard
          let scanReply = try await connection.send(
            NetworkManager.scanAPs(devicePath: wifiDevicePath)),
          let bodyValue = scanReply.body.first,
          let aps = bodyValue.array
        else {
          print("No body in Scan reply")
          return
        }

        var networks = [(ssid: String, path: String)]()
        for ap in aps.compactMap(\.objectPath) {
          guard
            let ssidReply = try await connection.send(NetworkManager.getSSID(apPath: ap)),
            let bodyValue = ssidReply.body.first,
            let ssid = bodyValue.array
          else {
            print("No body in GetSSID reply")
            continue
          }

          let ssidBytes = ssid.compactMap(\.uint8)
          if let ssidString = String(bytes: ssidBytes, encoding: .utf8) {
            networks.append((ssid: ssidString, path: ap))
          }
        }

        print(networks)

        if let (name, path) = networks.first(where: { $0.ssid == "<My Wifi>" }) {
          guard
            let reply = try await connection.send(
              NetworkManager.connect(
                networkDevicePath: wifiDevicePath,
                apPath: path,
                apName: name,
                password: ""
              ))
          else {
            print("No reply from Connect method call")
            return
          }

          print("Connect reply: \(reply)")
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
  /// Get all network devices from NetworkManager
  /// - Parameter serial: The D-Bus serial number to use
  /// - Returns: A DBusMessage for the GetDevices method
  public static func getDevices() -> DBusRequest {
    return DBusRequest.createMethodCall(
      destination: "org.freedesktop.NetworkManager",
      path: "/org/freedesktop/NetworkManager",
      interface: "org.freedesktop.NetworkManager",
      method: "GetDevices",
    )
  }

  /// Get the type of a network device
  /// - Parameters:
  ///   - devicePath: The object path of the device
  /// - Returns: A DBusMessage for the Get method to get device type
  public static func getDeviceType(devicePath: String) -> DBusRequest {
    return DBusRequest.createMethodCall(
      destination: "org.freedesktop.NetworkManager",
      path: devicePath,
      interface: "org.freedesktop.DBus.Properties",
      method: "Get",
      body: [
        .string("org.freedesktop.NetworkManager.Device"),
        .string("DeviceType"),
      ]
    )
  }

  /// Create a D-Bus message to request a Wi-Fi scan on a given device
  /// - Parameters:
  ///   - devicePath: The object path of the wireless device (e.g. "/org/freedesktop/NetworkManager/Devices/0")
  /// - Returns: A DBusMessage for the Scan method
  public static func scanAPs(devicePath: String) -> DBusRequest {
    return DBusRequest.createMethodCall(
      destination: "org.freedesktop.NetworkManager",
      path: devicePath,
      interface: "org.freedesktop.NetworkManager.Device.Wireless",
      method: "GetAllAccessPoints"
    )
  }

  public static func getSSID(apPath: String) -> DBusRequest {
    return DBusRequest.createMethodCall(
      destination: "org.freedesktop.NetworkManager",
      path: apPath,
      interface: "org.freedesktop.DBus.Properties",
      method: "Get",
      body: [
        DBusValue.string("org.freedesktop.NetworkManager.AccessPoint"), DBusValue.string("Ssid"),
      ]
    )
  }

  public static func connect(
    networkDevicePath: String,
    apPath: String,
    apName: String,
    password: String
  ) -> DBusRequest {
    return DBusRequest.createMethodCall(
      destination: "org.freedesktop.NetworkManager",
      path: apPath,
      interface: "org.freedesktop.NetworkManager",
      method: "AddAndActivateConnection",
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
              ])
            ])
          ]),
          .dictionary([
            .string("ipv6"): .array([
              .dictionary([
                .string("method"): .string("auto")
              ])
            ])
          ]),
        ]),
        .objectPath(networkDevicePath),
        .objectPath(apPath),
      ]
    )
  }
}
