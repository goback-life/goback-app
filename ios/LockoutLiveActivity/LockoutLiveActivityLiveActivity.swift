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
                Image("GobackLogo")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.white)
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

private let accentBlue = Color(red: 89/255, green: 142/255, blue: 181/255)

private struct LockScreenBanner: View {
    let appGroupId: String
    let context: ActivityViewContext<LiveActivitiesAppAttributes>

    private var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupId)!
    }

    private var endDate: Date {
        let ts = defaults.integer(forKey: context.attributes.prefixedKey("endTimestamp"))
        return Date(timeIntervalSince1970: TimeInterval(ts))
    }

    private var startDate: Date {
        let ts = defaults.integer(forKey: context.attributes.prefixedKey("startTimestamp"))
        return Date(timeIntervalSince1970: TimeInterval(ts))
    }

    private var isOpenEnded: Bool {
        defaults.integer(forKey: context.attributes.prefixedKey("isOpenEnded")) != 0
    }

    var body: some View {
        HStack {
            Image("GobackLogo")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(height: 40)
            Spacer()
            if isOpenEnded {
                Text(timerInterval: startDate...Date.distantFuture, countsDown: false)
                    .font(.system(size: 22, weight: .medium, design: .monospaced))
                    .multilineTextAlignment(.trailing)
            } else if endDate > Date.now {
                Text(timerInterval: Date.now...endDate, countsDown: true)
                    .font(.system(size: 22, weight: .medium, design: .monospaced))
                    .multilineTextAlignment(.trailing)
            } else {
                Text("0:00")
                    .font(.system(size: 22, weight: .medium, design: .monospaced))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .foregroundColor(accentBlue)
        .activityBackgroundTint(.white.opacity(1))
        .activitySystemActionForegroundColor(accentBlue)
    }
}

// MARK: - Dynamic Island Expanded

private struct ExpandedContent: View {
    let appGroupId: String
    let context: ActivityViewContext<LiveActivitiesAppAttributes>

    private var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupId)!
    }

    private var endDate: Date {
        let ts = defaults.integer(forKey: context.attributes.prefixedKey("endTimestamp"))
        return Date(timeIntervalSince1970: TimeInterval(ts))
    }

    private var startDate: Date {
        let ts = defaults.integer(forKey: context.attributes.prefixedKey("startTimestamp"))
        return Date(timeIntervalSince1970: TimeInterval(ts))
    }

    private var isOpenEnded: Bool {
        defaults.integer(forKey: context.attributes.prefixedKey("isOpenEnded")) != 0
    }

    var body: some View {
        HStack {
            Image("GobackLogo")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(height: 28)
                .foregroundColor(.white)
            Spacer()
            if isOpenEnded {
                Text(timerInterval: startDate...Date.distantFuture, countsDown: false)
                    .font(.system(size: 24, weight: .medium, design: .monospaced))
                    .multilineTextAlignment(.trailing)
            } else if endDate > Date.now {
                Text(timerInterval: Date.now...endDate, countsDown: true)
                    .font(.system(size: 24, weight: .medium, design: .monospaced))
                    .multilineTextAlignment(.trailing)
            } else {
                Text("0:00")
                    .font(.system(size: 24, weight: .medium, design: .monospaced))
            }
        }
    }
}

// MARK: - Compact / Minimal Timer

private struct CountdownText: View {
    let appGroupId: String
    let context: ActivityViewContext<LiveActivitiesAppAttributes>
    let size: CGFloat

    private var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupId)!
    }

    private var endDate: Date {
        let ts = defaults.integer(forKey: context.attributes.prefixedKey("endTimestamp"))
        return Date(timeIntervalSince1970: TimeInterval(ts))
    }

    private var startDate: Date {
        let ts = defaults.integer(forKey: context.attributes.prefixedKey("startTimestamp"))
        return Date(timeIntervalSince1970: TimeInterval(ts))
    }

    private var isOpenEnded: Bool {
        defaults.integer(forKey: context.attributes.prefixedKey("isOpenEnded")) != 0
    }

    var body: some View {
        if isOpenEnded {
            Text(timerInterval: startDate...Date.distantFuture, countsDown: false)
                .font(.system(size: size, weight: .medium, design: .monospaced))
                .multilineTextAlignment(.trailing)
        } else if endDate > Date.now {
            Text(timerInterval: Date.now...endDate, countsDown: true)
                .font(.system(size: size, weight: .medium, design: .monospaced))
                .multilineTextAlignment(.trailing)
        } else {
            Text("0:00")
                .font(.system(size: size, weight: .medium, design: .monospaced))
        }
    }
}
