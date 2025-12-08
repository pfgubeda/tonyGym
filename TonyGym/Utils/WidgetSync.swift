import Foundation
import WidgetKit

enum WidgetSync {
    // NOTE: Set this App Group in both the app and the widget target capabilities
    private static let appGroupId = "group.com.pafego.TonyGym"
    private static let key = "todayRoutineSnapshot"
    private static let fullKey = "routineFullSnapshot"

    static func writeTodaySnapshot(snapshot: WidgetRoutineSnapshot) {
        guard let defaults = UserDefaults(suiteName: appGroupId) else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(snapshot) {
            defaults.set(data, forKey: key)
            defaults.synchronize()
            if #available(iOS 14.0, *) {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }

    /// Lightweight format the widget can use to compute today's content independently
    struct FullRoutineSnapshot: Codable {
        struct Item: Codable {
            let title: String
            let categoryRaw: Int
            let weightKg: Double
        }
        // Map Weekday.rawValue (1..7) -> items for that day
        let routineName: String
        let itemsByWeekday: [Int: [Item]]
        let generatedAt: Date
    }

    /// Write the entire routine once so the widget can pick today's items without launching the app
    static func writeFullRoutineSnapshot(routineName: String, entries: [RoutineEntry]) {
        guard let defaults = UserDefaults(suiteName: appGroupId) else { return }

        // Build items grouped by weekday, sorted by order
        var map: [Int: [FullRoutineSnapshot.Item]] = [:]
        let sorted = entries.sorted { $0.order < $1.order }
        for entry in sorted {
            guard let ex = entry.exercise else { continue }
            let item = FullRoutineSnapshot.Item(
                title: ex.title,
                categoryRaw: ex.category.rawValue,
                weightKg: ex.defaultWeightKg
            )
            var arr = map[entry.weekday.rawValue] ?? []
            arr.append(item)
            map[entry.weekday.rawValue] = arr
        }

        let payload = FullRoutineSnapshot(
            routineName: routineName,
            itemsByWeekday: map,
            generatedAt: Date()
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(payload) {
            defaults.set(data, forKey: fullKey)
            defaults.synchronize()
            if #available(iOS 14.0, *) {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }

    static func buildSnapshot(routineName: String, weekday: Weekday, entries: [RoutineEntry]) -> WidgetRoutineSnapshot {
        // Sort entries by order before creating widget items
        let sortedEntries = entries.sorted { $0.order < $1.order }
        let items: [WidgetRoutineItem] = sortedEntries.compactMap { entry in
            guard let ex = entry.exercise else { return nil }
            return WidgetRoutineItem(title: ex.title, categoryRaw: ex.category.rawValue, weightKg: ex.defaultWeightKg)
        }
        return WidgetRoutineSnapshot(date: Date(), weekday: weekday.rawValue, routineName: routineName, items: items)
    }
    
    static func buildTodaySnapshot(routineName: String, entries: [RoutineEntry]) -> WidgetRoutineSnapshot {
        let today = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: today)
        let weekdayEnum = Weekday(rawValue: weekday == 1 ? 7 : weekday - 1) ?? .monday // Convert Sunday=1 to Sunday=7
        
        // Sort entries by order before creating widget items
        let sortedEntries = entries.sorted { $0.order < $1.order }
        let items: [WidgetRoutineItem] = sortedEntries.compactMap { entry in
            guard let ex = entry.exercise else { return nil }
            return WidgetRoutineItem(title: ex.title, categoryRaw: ex.category.rawValue, weightKg: ex.defaultWeightKg)
        }
        return WidgetRoutineSnapshot(date: today, weekday: weekdayEnum.rawValue, routineName: routineName, items: items)
    }
    
    // MARK: - Streak Snapshot
    
    struct StreakSnapshot: Codable {
        let currentStreak: Int
        let longestStreak: Int
        let lastWorkoutDate: Date?
        let isActive: Bool
        let totalWorkoutDays: Int
    }
    
    static func writeStreakSnapshot(streak: WorkoutStreak) {
        guard let defaults = UserDefaults(suiteName: appGroupId) else { return }
        
        let snapshot = StreakSnapshot(
            currentStreak: streak.currentStreak,
            longestStreak: streak.longestStreak,
            lastWorkoutDate: streak.lastWorkoutDate,
            isActive: streak.isActive,
            totalWorkoutDays: streak.totalWorkoutDays
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(snapshot) {
            defaults.set(data, forKey: "streakSnapshot")
            defaults.synchronize()
            if #available(iOS 14.0, *) {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}


