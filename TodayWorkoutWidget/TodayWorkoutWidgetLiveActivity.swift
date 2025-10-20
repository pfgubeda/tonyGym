//
//  TodayWorkoutWidgetLiveActivity.swift
//  TodayWorkoutWidget
//
//  Created by Pablo Fernandez Gonzalez on 20/10/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TodayWorkoutWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct TodayWorkoutWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TodayWorkoutWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension TodayWorkoutWidgetAttributes {
    fileprivate static var preview: TodayWorkoutWidgetAttributes {
        TodayWorkoutWidgetAttributes(name: "World")
    }
}

extension TodayWorkoutWidgetAttributes.ContentState {
    fileprivate static var smiley: TodayWorkoutWidgetAttributes.ContentState {
        TodayWorkoutWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: TodayWorkoutWidgetAttributes.ContentState {
         TodayWorkoutWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: TodayWorkoutWidgetAttributes.preview) {
   TodayWorkoutWidgetLiveActivity()
} contentStates: {
    TodayWorkoutWidgetAttributes.ContentState.smiley
    TodayWorkoutWidgetAttributes.ContentState.starEyes
}
