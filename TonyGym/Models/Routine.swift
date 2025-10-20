import Foundation
import SwiftData

enum Weekday: Int, Codable, CaseIterable, Identifiable {
    case monday = 1, tuesday, wednesday, thursday, friday, saturday, sunday

    var id: Int { rawValue }
    var short: String {
        switch self {
        case .monday: return NSLocalizedString("home.weekday.mon", comment: "Monday short")
        case .tuesday: return NSLocalizedString("home.weekday.tue", comment: "Tuesday short")
        case .wednesday: return NSLocalizedString("home.weekday.wed", comment: "Wednesday short")
        case .thursday: return NSLocalizedString("home.weekday.thu", comment: "Thursday short")
        case .friday: return NSLocalizedString("home.weekday.fri", comment: "Friday short")
        case .saturday: return NSLocalizedString("home.weekday.sat", comment: "Saturday short")
        case .sunday: return NSLocalizedString("home.weekday.sun", comment: "Sunday short")
        }
    }
    
    var fullName: String {
        switch self {
        case .monday: return NSLocalizedString("home.weekday.monday", comment: "Monday full name")
        case .tuesday: return NSLocalizedString("home.weekday.tuesday", comment: "Tuesday full name")
        case .wednesday: return NSLocalizedString("home.weekday.wednesday", comment: "Wednesday full name")
        case .thursday: return NSLocalizedString("home.weekday.thursday", comment: "Thursday full name")
        case .friday: return NSLocalizedString("home.weekday.friday", comment: "Friday full name")
        case .saturday: return NSLocalizedString("home.weekday.saturday", comment: "Saturday full name")
        case .sunday: return NSLocalizedString("home.weekday.sunday", comment: "Sunday full name")
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


