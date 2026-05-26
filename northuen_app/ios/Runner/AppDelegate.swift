import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let key = googleMapsApiKey(), !key.isEmpty {
      GMSServices.provideAPIKey(key)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func googleMapsApiKey() -> String? {
    if let key = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsApiKey") as? String,
       !key.isEmpty,
       !key.hasPrefix("$(") {
      return key
    }
    guard let dartDefines = Bundle.main.object(forInfoDictionaryKey: "DART_DEFINES") as? String,
          !dartDefines.isEmpty,
          !dartDefines.hasPrefix("$(") else {
      return nil
    }
    for encoded in dartDefines.split(separator: ",") {
      var base64 = String(encoded)
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")
      while base64.count % 4 != 0 {
        base64.append("=")
      }
      guard let data = Data(base64Encoded: base64),
            let decoded = String(data: data, encoding: .utf8) else {
        continue
      }
      if decoded.hasPrefix("GOOGLE_MAPS_API_KEY=") {
        return String(decoded.dropFirst("GOOGLE_MAPS_API_KEY=".count))
      }
    }
    return nil
  }
}
