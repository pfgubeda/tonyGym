import Foundation
import SwiftData

/// Marca un día como entrenado sin necesidad de un log completo
/// Útil para mantener la racha cuando entrenas pero no registras ejercicios específicos
@Model
final class DailyWorkoutMark {
    var date: Date // Fecha del entrenamiento (solo día, sin hora)
    var notes: String // Notas opcionales
    var createdAt: Date
    
    init(date: Date, notes: String = "") {
        let calendar = Calendar.current
        self.date = calendar.startOfDay(for: date)
        self.notes = notes
        self.createdAt = .now
    }
    
    /// Verifica si hay una marca para una fecha específica
    static func hasMark(for date: Date, in marks: [DailyWorkoutMark]) -> Bool {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        return marks.contains { calendar.isDate($0.date, inSameDayAs: targetDay) }
    }
}
