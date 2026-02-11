import Flutter
import SwiftUI
import UIKit

/// Platform view that hosts a SwiftUI liquid glass surface.
///
/// On iOS 26+: renders Apple's native `.glassEffect()`.
/// On older iOS: renders a transparent view (Flutter's shader handles the glass).
class LiquidGlassView: NSObject, FlutterPlatformView {
    private let hostingView: UIView

    init(frame: CGRect, arguments args: [String: Any]?) {
        let variant = args?["variant"] as? String ?? "regular"
        let tintValue = args?["tint"] as? Int
        let cornerRadius = args?["cornerRadius"] as? Double ?? 24.0
        let interactive = args?["interactive"] as? Bool ?? false

        if #available(iOS 26.0, *) {
            let surface = LiquidGlassSurface(
                variant: variant,
                tintValue: tintValue,
                cornerRadius: cornerRadius,
                interactive: interactive
            )
            let controller = UIHostingController(rootView: surface)
            controller.view.backgroundColor = .clear
            controller.view.isOpaque = false
            hostingView = controller.view
        } else {
            // Transparent placeholder — Flutter shader renderer handles glass.
            let view = UIView()
            view.backgroundColor = .clear
            hostingView = view
        }

        super.init()
    }

    func view() -> UIView {
        return hostingView
    }
}

// MARK: - SwiftUI Glass Surface (iOS 26+)

@available(iOS 26.0, *)
struct LiquidGlassSurface: View {
    let variant: String
    let tintValue: Int?
    let cornerRadius: Double
    let interactive: Bool

    var body: some View {
        glassSurface
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var glassSurface: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)

        if variant == "clear" {
            clearGlass(shape: shape)
        } else {
            regularGlass(shape: shape)
        }
    }

    // MARK: Regular variant

    @ViewBuilder
    private func regularGlass(shape: RoundedRectangle) -> some View {
        if let tint = tintColor {
            if interactive {
                Color.clear.glassEffect(.regular.tint(tint).interactive(), in: shape)
            } else {
                Color.clear.glassEffect(.regular.tint(tint), in: shape)
            }
        } else {
            if interactive {
                Color.clear.glassEffect(.regular.interactive(), in: shape)
            } else {
                Color.clear.glassEffect(.regular, in: shape)
            }
        }
    }

    // MARK: Clear variant

    @ViewBuilder
    private func clearGlass(shape: RoundedRectangle) -> some View {
        if let tint = tintColor {
            if interactive {
                Color.clear.glassEffect(.clear.tint(tint).interactive(), in: shape)
            } else {
                Color.clear.glassEffect(.clear.tint(tint), in: shape)
            }
        } else {
            if interactive {
                Color.clear.glassEffect(.clear.interactive(), in: shape)
            } else {
                Color.clear.glassEffect(.clear, in: shape)
            }
        }
    }

    // MARK: Helpers

    private var tintColor: Color? {
        guard let value = tintValue else { return nil }
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        let a = Double((value >> 24) & 0xFF) / 255.0
        return Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
