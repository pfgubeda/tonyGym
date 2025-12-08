import Foundation
import UserNotifications

/// Gestor de notificaciones locales para la app
class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    /// Solicita permisos de notificación
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    /// Envía una notificación de celebración por nuevo PR
    func celebrateNewPR(exerciseName: String, recordType: PersonalRecord.RecordType, value: String) {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification.pr.title", comment: "New PR!")
        content.body = String(format: NSLocalizedString("notification.pr.body", comment: "New PR message"), exerciseName, recordType.displayName, value)
        content.sound = .default
        content.badge = 1
        
        // Agregar categoría para acciones
        content.categoryIdentifier = "PR_CATEGORY"
        
        let request = UNNotificationRequest(
            identifier: "pr_\(UUID().uuidString)",
            content: content,
            trigger: nil // Inmediata
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending PR notification: \(error)")
            }
        }
    }
    
    /// Programa un resumen semanal de progreso
    func scheduleWeeklySummary() {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification.weekly.title", comment: "Weekly summary")
        content.body = NSLocalizedString("notification.weekly.body", comment: "Check your progress this week")
        content.sound = .default
        
        // Programar para cada domingo a las 9 AM
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Domingo
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "weekly_summary",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling weekly summary: \(error)")
            }
        }
    }
    
    /// Envía una notificación de hito (milestone)
    func celebrateMilestone(milestone: Milestone) {
        let content = UNMutableNotificationContent()
        content.title = milestone.title
        content.body = milestone.message
        content.sound = .default
        content.badge = 1
        
        let request = UNNotificationRequest(
            identifier: "milestone_\(milestone.id)",
            content: content,
            trigger: nil // Inmediata
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending milestone notification: \(error)")
            }
        }
    }
    
    /// Cancela todas las notificaciones programadas
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    /// Cancela una notificación específica
    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}

/// Representa un hito o milestone
struct Milestone {
    let id: String
    let title: String
    let message: String
    
    static let workout100 = Milestone(
        id: "workout_100",
        title: NSLocalizedString("milestone.100.title", comment: "100 workouts milestone"),
        message: NSLocalizedString("milestone.100.message", comment: "100 workouts message")
    )
    
    static let workout250 = Milestone(
        id: "workout_250",
        title: NSLocalizedString("milestone.250.title", comment: "250 workouts milestone"),
        message: NSLocalizedString("milestone.250.message", comment: "250 workouts message")
    )
    
    static let workout500 = Milestone(
        id: "workout_500",
        title: NSLocalizedString("milestone.500.title", comment: "500 workouts milestone"),
        message: NSLocalizedString("milestone.500.message", comment: "500 workouts message")
    )
    
    static let streak7 = Milestone(
        id: "streak_7",
        title: NSLocalizedString("milestone.streak7.title", comment: "7 day streak"),
        message: NSLocalizedString("milestone.streak7.message", comment: "7 day streak message")
    )
    
    static let streak30 = Milestone(
        id: "streak_30",
        title: NSLocalizedString("milestone.streak30.title", comment: "30 day streak"),
        message: NSLocalizedString("milestone.streak30.message", comment: "30 day streak message")
    )
    
    static let streak100 = Milestone(
        id: "streak_100",
        title: NSLocalizedString("milestone.streak100.title", comment: "100 day streak"),
        message: NSLocalizedString("milestone.streak100.message", comment: "100 day streak message")
    )
}
