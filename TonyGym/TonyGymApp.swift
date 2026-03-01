import SwiftUI
import SwiftData

@main
struct TonyGymApp: App {
    var sharedModelContainer: ModelContainer = {
        do {
            let container = try ModelContainer(for: Exercise.self, ImageAttachment.self, Routine.self, RoutineEntry.self, DayPlan.self, WorkoutLog.self, DailyProgress.self, BilboExercise.self, BilboSession.self, BilboCycle.self, BilboDay.self, PersonalRecord.self, WorkoutStreak.self, WorkoutSet.self, DailyWorkoutMark.self, ExerciseMark.self, FoodEntry.self, NutritionGoal.self, FavoriteFood.self)
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .onAppear {
                    // Solicitar permisos de notificación al iniciar
                    NotificationManager.shared.requestAuthorization()
                    NotificationManager.shared.scheduleWeeklySummary()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}


