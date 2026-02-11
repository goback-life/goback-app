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
        let pathCommands = args?["pathCommands"] as? [[Any]]
        let viewBoxWidth = (args?["viewBoxWidth"] as? NSNumber)?.doubleValue
        let viewBoxHeight = (args?["viewBoxHeight"] as? NSNumber)?.doubleValue

        if #available(iOS 26.0, *) {
            let surface = LiquidGlassSurface(
                variant: variant,
                tintValue: tintValue,
                cornerRadius: cornerRadius,
                interactive: interactive,
                pathCommands: pathCommands,
                viewBoxWidth: viewBoxWidth,
                viewBoxHeight: viewBoxHeight
            )
            let controller = UIHostingController(rootView: surface)
            controller.view.backgroundColor = .clear
            controller.view.isOpaque = false
            hostingView = controller.view
        } else {
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

// MARK: - Custom Path Shape

@available(iOS 26.0, *)
struct PathShape: Shape {
    let commands: [[Any]]
    let viewBox: CGSize

    func path(in rect: CGRect) -> SwiftUI.Path {
        let sx = rect.width / viewBox.width
        let sy = rect.height / viewBox.height
        var path = SwiftUI.Path()

        for cmd in commands {
            guard let op = cmd.first as? String else { continue }
            let nums = cmd.dropFirst().compactMap { ($0 as? NSNumber)?.doubleValue }

            switch op {
            case "M" where nums.count >= 2:
                path.move(to: CGPoint(x: nums[0] * sx, y: nums[1] * sy))
            case "L" where nums.count >= 2:
                path.addLine(to: CGPoint(x: nums[0] * sx, y: nums[1] * sy))
            case "C" where nums.count >= 6:
                path.addCurve(
                    to: CGPoint(x: nums[4] * sx, y: nums[5] * sy),
                    control1: CGPoint(x: nums[0] * sx, y: nums[1] * sy),
                    control2: CGPoint(x: nums[2] * sx, y: nums[3] * sy)
                )
            case "Z":
                path.closeSubpath()
            default:
                break
            }
        }
        return path
    }
}

// MARK: - SwiftUI Glass Surface (iOS 26+)

@available(iOS 26.0, *)
struct LiquidGlassSurface: View {
    let variant: String
    let tintValue: Int?
    let cornerRadius: Double
    let interactive: Bool
    let pathCommands: [[Any]]?
    let viewBoxWidth: Double?
    let viewBoxHeight: Double?

    var body: some View {
        glassSurface
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var glassSurface: some View {
        if let cmds = pathCommands,
           let w = viewBoxWidth,
           let h = viewBoxHeight {
            applyGlass(shape: PathShape(
                commands: cmds,
                viewBox: CGSize(width: w, height: h)
            ))
        } else {
            applyGlass(shape: RoundedRectangle(cornerRadius: cornerRadius))
        }
    }

    @ViewBuilder
    private func applyGlass<S: Shape>(shape: S) -> some View {
        if let tint = tintColor {
            if interactive {
                if variant == "clear" {
                    Color.clear.glassEffect(.clear.tint(tint).interactive(), in: shape)
                } else {
                    Color.clear.glassEffect(.regular.tint(tint).interactive(), in: shape)
                }
            } else {
                if variant == "clear" {
                    Color.clear.glassEffect(.clear.tint(tint), in: shape)
                } else {
                    Color.clear.glassEffect(.regular.tint(tint), in: shape)
                }
            }
        } else {
            if interactive {
                if variant == "clear" {
                    Color.clear.glassEffect(.clear.interactive(), in: shape)
                } else {
                    Color.clear.glassEffect(.regular.interactive(), in: shape)
                }
            } else {
                if variant == "clear" {
                    Color.clear.glassEffect(.clear, in: shape)
                } else {
                    Color.clear.glassEffect(.regular, in: shape)
                }
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
