import Flutter
import UIKit
import GoogleMaps // google_maps_flutter: required for GMSServices

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps SDK init — must run before the Flutter engine renders.
    // Replace YOUR_API_KEY with a key from Google Cloud Console
    // (Maps SDK for iOS must be enabled). iOS deployment target >= 14.0 required.
    GMSServices.provideAPIKey("YOUR_API_KEY")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
