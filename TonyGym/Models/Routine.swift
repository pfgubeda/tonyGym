import Foundation
import SwiftData

enum Weekday: Int, Codable, CaseIterable, Identifiable {
    case monday = 1, tuesday, wednesday, thursday, friday, saturday, sunday

    var id: Int { rawValue }
    var short: String {
        switch self {
        case .monday: return "L"
        case .tuesday: return "M"
        case .wednesday: return "X"
        case .thursday: return "J"
        case .friday: return "V"
        case .saturday: return "S"
        case .sunday: return "D"
        }
    }
}

@Model
final class RoutineEntry {
    var weekdayRaw: Int
    @Relationship var exercise: Exercise?
    @Relationship var routine: Routine?
    var note: String
    var order: Int

    var weekday: Weekday {
        get { Weekday(rawValue: weekdayRaw) ?? .monday }
        set { weekdayRaw = newValue.rawValue }
    }

    init(weekday: Weekday, exercise: Exercise?, note: String = "", order: Int = 0) {
        self.weekdayRaw = weekday.rawValue
        self.exercise = exercise
        self.note = note
        self.order = order
    }
}

@Model
final class Routine {
    var name: String
    @Relationship(deleteRule: .cascade, inverse: \RoutineEntry.routine) var entries: [RoutineEntry]
    @Relationship(deleteRule: .cascade, inverse: \DayPlan.routine) var dayPlans: [DayPlan]
    var createdAt: Date
    var updatedAt: Date

    init(name: String, entries: [RoutineEntry] = [], dayPlans: [DayPlan] = []) {
        self.name = name
        self.entries = entries
        self.dayPlans = dayPlans
        self.createdAt = .now
        self.updatedAt = .now
    }
}


