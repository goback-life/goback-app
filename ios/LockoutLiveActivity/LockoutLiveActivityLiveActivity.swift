//
//  LockoutLiveActivityLiveActivity.swift
//  LockoutLiveActivity
//
//  Created by goback on 09/03/2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Attributes (must match the plugin's definition exactly)

struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
    public typealias LiveDeliveryData = ContentState

    public struct ContentState: Codable, Hashable {
        var appGroupId: String
    }

    var id = UUID()
}

extension LiveActivitiesAppAttributes {
    func prefixedKey(_ key: String) -> String {
        "\(id)_\(key)"
    }
}

// MARK: - Widget

struct LockoutLiveActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
            LockScreenBanner(
                appGroupId: context.state.appGroupId,
                context: context
            )
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    ExpandedContent(
                        appGroupId: context.state.appGroupId,
                        context: context
                    )
                }
            } compactLeading: {
                Text("gb")
                    .font(.system(size: 14, weight: .bold))
            } compactTrailing: {
                CountdownText(
                    appGroupId: context.state.appGroupId,
                    context: context,
                    size: 14
                )
            } minimal: {
                CountdownText(
                    appGroupId: context.state.appGroupId,
                    context: context,
                    size: 12
                )
            }
        }
    }
}

// MARK: - Lock Screen Banner

private struct LockScreenBanner: View {
    let appGroupId: String
    let context: ActivityViewContext<LiveActivitiesAppAttributes>

    private var endDate: Date {
        let defaults = UserDefaults(suiteName: appGroupId)!
        let ts = defaults.integer(forKey: context.attributes.prefixedKey("endTimestamp"))
        return Date(timeIntervalSince1970: TimeInterval(ts))
    }

    var body: some View {
        HStack {
            Text("goback.")
                .font(.system(size: 20, weight: .bold))
            Spacer()
            if endDate > Date.now {
                Text(timerInterval: Date.now...endDate, countsDown: true)
                    .font(.system(size: 20, weight: .medium, design: .monospaced))
                    .multilineTextAlignment(.trailing)
            } else {
                Text("0:00")
                    .font(.system(size: 20, weight: .medium, design: .monospaced))
            }
        }
        .padding()
        .foregroundColor(.white)
        .background(
            Image("GobackLogo")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(height: 40)
                .foregroundColor(.white)
                .opacity(0.15)
        )
        .activityBackgroundTint(.black)
    }
}

// MARK: - Dynamic Island Expanded

private struct ExpandedContent: View {
    let appGroupId: String
    let context: ActivityViewContext<LiveActivitiesAppAttributes>

    private var endDate: Date {
        let defaults = UserDefaults(suiteName: appGroupId)!
        let ts = defaults.integer(forKey: context.attributes.prefixedKey("endTimestamp"))
        return Date(timeIntervalSince1970: TimeInterval(ts))
    }

    var body: some View {
        VStack(spacing: 4) {
            Image("GobackLogo")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(height: 20)
                .foregroundColor(.white)
            Text("goback.")
                .font(.system(size: 16, weight: .bold))
            if endDate > Date.now {
                Text(timerInterval: Date.now...endDate, countsDown: true)
                    .font(.system(size: 24, weight: .medium, design: .monospaced))
                    .multilineTextAlignment(.center)
            } else {
                Text("0:00")
                    .font(.system(size: 24, weight: .medium, design: .monospaced))
            }
        }
    }
}

// MARK: - Compact / Minimal Countdown

private struct CountdownText: View {
    let appGroupId: String
    let context: ActivityViewContext<LiveActivitiesAppAttributes>
    let size: CGFloat

    private var endDate: Date {
        let defaults = UserDefaults(suiteName: appGroupId)!
        let ts = defaults.integer(forKey: context.attributes.prefixedKey("endTimestamp"))
        return Date(timeIntervalSince1970: TimeInterval(ts))
    }

    var body: some View {
        if endDate > Date.now {
            Text(timerInterval: Date.now...endDate, countsDown: true)
                .font(.system(size: size, weight: .medium, design: .monospaced))
                .multilineTextAlignment(.trailing)
        } else {
            Text("0:00")
                .font(.system(size: size, weight: .medium, design: .monospaced))
        }
    }
}
