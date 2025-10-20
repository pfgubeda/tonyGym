import Foundation
import SwiftData

@Model
final class DayPlan {
    var weekdayRaw: Int
    var title: String
    @Relationship var routine: Routine?

    var weekday: Weekday {
        get { Weekday(rawValue: weekdayRaw) ?? .monday }
        set { weekdayRaw = newValue.rawValue }
    }

    init(weekday: Weekday, title: String = "", routine: Routine? = nil) {
        self.weekdayRaw = weekday.rawValue
        self.title = title
        self.routine = routine
    }
}


