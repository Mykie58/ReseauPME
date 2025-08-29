import Foundation

#if os(iOS)
  @_exported import Flutter
#elseif os(macOS)
  import FlutterMacOS
#else
  #error("Unsupported platform.")
#endif

