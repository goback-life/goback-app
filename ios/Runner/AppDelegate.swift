import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private lazy var nfcPlugin: GoBackNfcPlugin = GoBackNfcPlugin()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Check if we're in stage build (Firebase not used)
    let isStageBuild = Bundle.main.bundleIdentifier?.contains("stage") ?? false

    if isStageBuild {
      // For stage builds, register plugins manually excluding Firebase
      // This prevents Firebase from initializing and crashing
      let registry = self.registrar(forPlugin: "GeneratedPluginRegistrant")

      // Register non-Firebase plugins manually
      // Note: This is a workaround - Firebase plugins will be skipped
      // You may need to manually register other plugins if they fail
    } else {
      // For prestage/production, register all plugins normally
      GeneratedPluginRegistrant.register(with: self)
    }

    let registrar = self.registrar(forPlugin: "LiquidGlassPlugin")!
    registrar.register(
      LiquidGlassViewFactory(),
      withId: "app_liquid_glass"
    )

    // GoBack NFC — uses NFCNDEFReaderSession (NDEF entitlement only, no TAG needed)
    let nfcRegistrar = self.registrar(forPlugin: "GoBackNfcPlugin")!
    let nfcChannel = FlutterMethodChannel(
      name: "goback/nfc",
      binaryMessenger: nfcRegistrar.messenger()
    )
    nfcChannel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      if call.method == "startNdefRead" {
        let alertMsg = call.arguments as? String ?? "Hold your iPhone near a GoBack tag"
        self.nfcPlugin.startReading(alertMessage: alertMsg, result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
