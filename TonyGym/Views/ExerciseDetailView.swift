import SwiftUI
import SwiftData

/// Vista de detalles del ejercicio para navegación (desde ExerciseListView)
/// Wrapper que usa ExerciseDetailSheet pero permite navegación en lugar de sheet
struct ExerciseDetailView: View {
    let exercise: Exercise
    
    var body: some View {
        ExerciseDetailSheetContent(exercise: exercise, isNavigationView: true)
    }
}
