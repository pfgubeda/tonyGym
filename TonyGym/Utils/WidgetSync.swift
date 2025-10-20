import Foundation
import WidgetKit

enum WidgetSync {
    // NOTE: Set this App Group in both the app and the widget target capabilities
    private static let appGroupId = "group.com.pafego.TonyGym"
    private static let key = "todayRoutineSnapshot"

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

    static func buildSnapshot(routineName: String, weekday: Weekday, entries: [RoutineEntry]) -> WidgetRoutineSnapshot {
        let items: [WidgetRoutineItem] = entries.compactMap { entry in
            guard let ex = entry.exercise else { return nil }
            return WidgetRoutineItem(title: ex.title, categoryRaw: ex.category.rawValue, weightKg: ex.defaultWeightKg)
        }
        return WidgetRoutineSnapshot(date: Date(), weekday: weekday.rawValue, routineName: routineName, items: items)
    }
}


