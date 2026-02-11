import Flutter
import UIKit

/// Factory that creates native liquid glass platform views for Flutter.
class LiquidGlassViewFactory: NSObject, FlutterPlatformViewFactory {
    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return LiquidGlassView(frame: frame, arguments: args as? [String: Any])
    }

    func createArgsCodec() -> (any FlutterMessageCodec & NSObjectProtocol) {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}
