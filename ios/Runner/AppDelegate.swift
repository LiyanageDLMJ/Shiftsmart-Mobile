import Flutter
import UIKit
import MSAL
import GoogleMaps // 1. Ensure this is imported
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var apnsTokenString: String?

  private func googleMapsApiKey() -> String {
    // 1. Check Info.plist for iOS-specific key
    if let key = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_IOS_KEY") as? String,
       !key.isEmpty {
      return key
    }
    // 2. Fallback to generic key in Info.plist
    if let key = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String,
       !key.isEmpty {
      return key
    }
    // 3. Check environment variable
    if let key = ProcessInfo.processInfo.environment["GOOGLE_MAPS_IOS_KEY"],
       !key.isEmpty {
      return key
    }

    // 4. Read from bundled .env file
    let assetPaths = [
      Bundle.main.path(forResource: ".env", ofType: nil, inDirectory: "flutter_assets"),
      Bundle.main.path(forResource: ".env", ofType: nil, inDirectory: "Frameworks/App.framework/flutter_assets")
    ].compactMap { $0 }

    for path in assetPaths {
      guard let contents = try? String(contentsOfFile: path, encoding: .utf8) else {
        continue
      }

      var iosKey: String? = nil
      var genericKey: String? = nil

      for line in contents.components(separatedBy: .newlines) {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("GOOGLE_MAPS_IOS_KEY=") {
          iosKey = String(trimmed.dropFirst("GOOGLE_MAPS_IOS_KEY=".count))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        } else if trimmed.hasPrefix("GOOGLE_MAPS_API_KEY=") {
          genericKey = String(trimmed.dropFirst("GOOGLE_MAPS_API_KEY=".count))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        }
      }
      // Prefer iOS-specific key, then fall back to generic
      if let key = iosKey, !key.isEmpty { return key }
      if let key = genericKey, !key.isEmpty { return key }
    }

    // 5. Hard-coded iOS Maps Key fallback
    return "YOUR_GOOGLE_MAPS_API_KEY"
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // 2. Initialize Google Maps with the same key used by Dart/Places.
    GMSServices.provideAPIKey(googleMapsApiKey())

    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "shiftsmart/native_push",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        if call.method == "getApnsToken" {
          result(self?.apnsTokenString)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    apnsTokenString = token
    Messaging.messaging().apnsToken = deviceToken
    NSLog("APNS token registered.")
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    NSLog("APNS registration failed: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  // 3. Keep your existing MSAL Logic intact
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    return MSALPublicClientApplication.handleMSALResponse(
      url,
      sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String
    )
  }
}
