import SwiftUI
import SwiftData

@main
struct TonyGymApp: App {
    var sharedModelContainer: ModelContainer = {
        do {
            let container = try ModelContainer(for: Exercise.self, ImageAttachment.self, Routine.self, RoutineEntry.self, DayPlan.self)
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}


