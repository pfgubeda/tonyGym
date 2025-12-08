import Foundation
import SwiftData

/// Representa el streak (racha) de días consecutivos entrenando
@Model
final class WorkoutStreak {
    var currentStreak: Int // Días consecutivos actuales
    var longestStreak: Int // Racha más larga histórica
    var lastWorkoutDate: Date? // Fecha del último entrenamiento
    var streakStartDate: Date? // Fecha de inicio de la racha actual
    var longestStreakStartDate: Date? // Fecha de inicio de la racha más larga
    var longestStreakEndDate: Date? // Fecha de fin de la racha más larga
    var totalWorkoutDays: Int // Total de días con entrenamiento
    var updatedAt: Date
    
    init() {
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastWorkoutDate = nil
        self.streakStartDate = nil
        self.longestStreakStartDate = nil
        self.longestStreakEndDate = nil
        self.totalWorkoutDays = 0
        self.updatedAt = .now
    }
    
    /// Actualiza el streak basándose en la fecha del entrenamiento
    /// - Parameters:
    ///   - workoutDate: Fecha del entrenamiento
    ///   - restDays: Set de días de la semana que son de descanso planificados (opcional)
    ///   - dailyMarks: Marcas de días entrenados (para contar días sin logs completos)
    ///   - exerciseMarks: Marcas de ejercicios entrenados (para contar ejercicios sin logs completos)
    func updateStreak(workoutDate: Date, restDays: Set<Int>? = nil, dailyMarks: [DailyWorkoutMark] = [], exerciseMarks: [ExerciseMark] = []) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let workoutDay = calendar.startOfDay(for: workoutDate)
        
        // Si es el mismo día, no actualizar
        if let lastDate = lastWorkoutDate, calendar.isDate(lastDate, inSameDayAs: workoutDay) {
            return
        }
        
        // Si no hay último entrenamiento o es el día anterior, incrementar streak
        if let lastDate = lastWorkoutDate {
            let daysBetween = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastDate), to: workoutDay).day ?? 0
            
            if daysBetween == 1 {
                // Día consecutivo
                currentStreak += 1
                if streakStartDate == nil {
                    streakStartDate = lastDate
                }
            } else if daysBetween > 1 {
                // Verificar si los días intermedios son días de descanso planificados
                let canMaintainStreak = canMaintainStreakWithRestDays(
                    from: lastDate,
                    to: workoutDay,
                    restDays: restDays,
                    calendar: calendar
                )
                
                if canMaintainStreak {
                    // Los días intermedios son descanso planificado, mantener la racha
                    currentStreak += 1
                    if streakStartDate == nil {
                        streakStartDate = lastDate
                    }
                } else {
                    // Se rompió la racha (días sin entrenar que no son descanso)
                    if currentStreak > longestStreak {
                        longestStreak = currentStreak
                        longestStreakStartDate = streakStartDate
                        longestStreakEndDate = lastDate
                    }
                    currentStreak = 1
                    streakStartDate = workoutDay
                }
            }
            // Si daysBetween == 0, es el mismo día, ya retornamos arriba
        } else {
            // Primer entrenamiento
            currentStreak = 1
            streakStartDate = workoutDay
        }
        
        lastWorkoutDate = workoutDay
        totalWorkoutDays += 1
        updatedAt = .now
        
        // Actualizar racha más larga si es necesario
        if currentStreak > longestStreak {
            longestStreak = currentStreak
            longestStreakStartDate = streakStartDate
            longestStreakEndDate = workoutDay
        }
    }
    
    /// Verifica si se puede mantener la racha considerando días de descanso planificados
    private func canMaintainStreakWithRestDays(
        from startDate: Date,
        to endDate: Date,
        restDays: Set<Int>?,
        calendar: Calendar
    ) -> Bool {
        guard let restDays = restDays, !restDays.isEmpty else {
            // Si no hay días de descanso definidos, cualquier gap rompe la racha
            return false
        }
        
        // Verificar todos los días entre startDate y endDate (excluyendo ambos)
        var currentDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        let endDay = calendar.startOfDay(for: endDate)
        
        while currentDate < endDay {
            let weekday = calendar.component(.weekday, from: currentDate)
            // Convertir de Calendar weekday (1=Sunday) a Weekday enum (1=Monday)
            let weekdayEnum = weekday == 1 ? 7 : weekday - 1
            
            // Si el día no es de descanso planificado, la racha se rompe
            if !restDays.contains(weekdayEnum) {
                return false
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return true
    }
    
    /// Verifica si el streak está activo (último entrenamiento fue hoy o ayer)
    var isActive: Bool {
        guard let lastDate = lastWorkoutDate else { return false }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let lastDay = calendar.startOfDay(for: lastDate)
        
        return lastDay == today || lastDay == yesterday
    }
    
    /// Obtiene el número de días desde el último entrenamiento
    var daysSinceLastWorkout: Int {
        guard let lastDate = lastWorkoutDate else { return 0 }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastDay = calendar.startOfDay(for: lastDate)
        return calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
    }
}
