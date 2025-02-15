import Flutter
import UIKit
import GoogleMaps // Import the GoogleMaps library

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Provide the Google Maps API key
    GMSServices.provideAPIKey("AIzaSyC9ydcIG4Ok45dj57AISS4-cAv0tnmUUOY")

    // Register the Flutter plugins
    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}