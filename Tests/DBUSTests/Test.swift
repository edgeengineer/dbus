import NIOCore
import Testing

@testable import DBUS

@Suite
struct MessageTests {
  @Test
  func decodeMessageBody() throws {
    let bytes: [UInt8] = [
      108, 2, 1, 1, 10, 0, 0, 0, 1, 0, 0, 0, 61, 0, 0, 0, 6, 1, 115, 0, 5, 0, 0, 0, 58, 49, 46, 54,
      54, 0, 0, 0, 5, 1, 117, 0, 1, 0, 0, 0, 8, 1, 103, 0, 1, 115, 0, 0, 7, 1, 115, 0, 20, 0, 0, 0,
      111, 114, 103, 46, 102, 114, 101, 101, 100, 101, 115, 107, 116, 111, 112, 46, 68, 66, 117,
      115, 0, 0, 0, 0, 5, 0, 0, 0, 58, 49, 46, 54, 54, 0, 108, 4, 1, 1, 10, 0, 0, 0, 2, 0, 0, 0,
      141, 0, 0, 0, 1, 1, 111, 0, 21, 0, 0, 0, 47, 111, 114, 103, 47, 102, 114, 101, 101, 100, 101,
      115, 107, 116, 111, 112, 47, 68, 66, 117, 115, 0, 0, 0, 2, 1, 115, 0, 20, 0, 0, 0, 111, 114,
      103, 46, 102, 114, 101, 101, 100, 101, 115, 107, 116, 111, 112, 46, 68, 66, 117, 115, 0, 0, 0,
      0, 3, 1, 115, 0, 12, 0, 0, 0, 78, 97, 109, 101, 65, 99, 113, 117, 105, 114, 101, 100, 0, 0, 0,
      0, 6, 1, 115, 0, 5, 0, 0, 0, 58, 49, 46, 54, 54, 0, 0, 0, 8, 1, 103, 0, 1, 115, 0, 0, 7, 1,
      115, 0, 20, 0, 0, 0, 111, 114, 103, 46, 102, 114, 101, 101, 100, 101, 115, 107, 116, 111, 112,
      46, 68, 66, 117, 115, 0, 0, 0, 0, 5, 0, 0, 0, 58, 49, 46, 54, 54, 0,
    ]

    var buffer = ByteBuffer(bytes: bytes)
    var writeBuffer = ByteBuffer()

    while buffer.readableBytes > 0 {
      let message = try DBusMessage(from: &buffer)
      buffer.discardReadBytes()

      var writeBuffer2 = ByteBuffer()
      message.write(to: &writeBuffer2)
      writeBuffer.writeImmutableBuffer(writeBuffer2)
    }

    while writeBuffer.readableBytes > 0 {
      let message = try DBusMessage(from: &writeBuffer)
      writeBuffer.discardReadBytes()
      print(message)
    }
  }
    
    @Test func decodeBooleanMessage() throws {
        let bytes: [UInt8] = [108, 2, 1, 1, 4, 0, 0, 0, 3, 0, 0, 0, 61, 0, 0, 0, 6, 1, 115, 0, 5, 0, 0, 0, 58, 49, 46, 49, 48, 0, 0, 0, 5, 1, 117, 0, 2, 0, 0, 0, 8, 1, 103, 0, 1, 98, 0, 0, 7, 1, 115, 0, 20, 0, 0, 0, 111, 114, 103, 46, 102, 114, 101, 101, 100, 101, 115, 107, 116, 111, 112, 46, 68, 66, 117, 115, 0, 0, 0, 0, 1, 0, 0, 0]
        
        var buffer = ByteBuffer(bytes: bytes)
        _ = try DBusMessage(from: &buffer)
    }

  @Test func createMethodCall() throws {
    let message = DBusMessage.createMethodCall(
      destination: "org.freedesktop.NetworkManager",
      path: "/org/freedesktop/NetworkManager/AccessPoint/1",
      interface: "org.freedesktop.DBus.Properties",
      method: "Get",
      serial: 2,
      body: [
        DBusValue.string("org.freedesktop.NetworkManager.AccessPoint"), DBusValue.string("Ssid"),
      ]
    )

    var buffer = ByteBuffer()
    message.write(to: &buffer)

    let message2 = try DBusMessage(from: &buffer)
    #expect(message.body == message2.body)
  }
}
