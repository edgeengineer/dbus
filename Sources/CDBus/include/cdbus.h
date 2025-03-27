#ifndef CDBUS_H
#define CDBUS_H

// Platform-specific includes for D-Bus
#if defined(__APPLE__)
  // On macOS, use the Homebrew installation with absolute paths
  #include "/opt/homebrew/opt/dbus/include/dbus-1.0/dbus/dbus.h"
#elif defined(__linux__)
  // On Linux, use the system headers
  #include <dbus/dbus.h>
#else
  #error "Unsupported platform"
#endif

#endif /* CDBUS_H */