//
//  TodayWorkoutWidgetBundle.swift
//  TodayWorkoutWidget
//
//  Created by Pablo Fernandez Gonzalez on 20/10/25.
//

import WidgetKit
import SwiftUI

@main
struct TodayWorkoutWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayWorkoutWidget()
        TodayWorkoutWidgetControl()
        TodayWorkoutWidgetLiveActivity()
    }
}
