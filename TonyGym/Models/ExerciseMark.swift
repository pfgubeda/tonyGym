import Foundation
import SwiftData

/// Marca un ejercicio como entrenado en una fecha específica sin necesidad de un log completo
/// Útil para mantener la racha cuando entrenas un ejercicio pero no cambias peso o no registras detalles
@Model
final class ExerciseMark {
    var date: Date // Fecha del entrenamiento (solo día, sin hora)
    @Relationship var exercise: Exercise?
    var notes: String // Notas opcionales
    var createdAt: Date
    
    init(date: Date, exercise: Exercise?, notes: String = "") {
        let calendar = Calendar.current
        self.date = calendar.startOfDay(for: date)
        self.exercise = exercise
        self.notes = notes
        self.createdAt = .now
    }
    
    /// Verifica si hay una marca para un ejercicio en una fecha específica
    static func hasMark(for exercise: Exercise, date: Date, in marks: [ExerciseMark]) -> Bool {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        return marks.contains { 
            $0.exercise?.id == exercise.id && 
            calendar.isDate($0.date, inSameDayAs: targetDay)
        }
    }
}
