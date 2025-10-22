import Foundation
import SwiftData

@Model
final class BilboExercise {
    @Relationship var exercise: Exercise?
    var oneRepMax: Double // 1RM del usuario para este ejercicio
    var currentWeight: Double // Peso actual (50% del 1RM)
    var targetReps: Int // Repeticiones objetivo (15-50)
    var lastSessionDate: Date?
    var lastRepsCompleted: Int?
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    var isOneRMAutoCalculated: Bool // Si el 1RM fue calculado automáticamente
    var oneRMCalculationDate: Date? // Fecha del último cálculo automático
    var oneRMFormula: String // Fórmula usada para calcular el 1RM
    
    init(exercise: Exercise?, oneRepMax: Double, notes: String = "", isAutoCalculated: Bool = false) {
        self.exercise = exercise
        self.oneRepMax = oneRepMax
        self.currentWeight = oneRepMax * 0.5 // 50% del 1RM
        self.targetReps = 15 // Comenzar con 15 repeticiones objetivo
        self.notes = notes
        self.createdAt = .now
        self.updatedAt = .now
        self.isOneRMAutoCalculated = isAutoCalculated
        self.oneRMCalculationDate = isAutoCalculated ? .now : nil
        self.oneRMFormula = OneRMCalculator.Formula.epley.rawValue
    }
    
    // Calcula el peso sugerido para la próxima sesión
    func suggestedNextWeight() -> Double {
        guard let lastReps = lastRepsCompleted else { return currentWeight }
        
        // Si completó más de 15 repeticiones, sugiere aumentar 2.5 kg
        if lastReps > 15 {
            return OneRMCalculator.roundToIncrement(currentWeight + 2.5)
        }
        
        // Si completó menos de 15, mantiene el peso actual
        return currentWeight
    }
    
    // Verifica si debe progresar en peso
    func shouldProgress() -> Bool {
        guard let lastReps = lastRepsCompleted else { return false }
        return lastReps > 15
    }
}

@Model
final class BilboSession {
    var date: Date
    @Relationship var bilboExercise: BilboExercise?
    var weightUsed: Double
    var repsCompleted: Int
    var notes: String
    var createdAt: Date
    
    init(bilboExercise: BilboExercise?, weightUsed: Double, repsCompleted: Int, notes: String = "") {
        self.date = .now
        self.bilboExercise = bilboExercise
        self.weightUsed = weightUsed
        self.repsCompleted = repsCompleted
        self.notes = notes
        self.createdAt = .now
    }
}

// Extensión para cálculos del método BILBO
extension BilboExercise {
    // Calcula el porcentaje del 1RM actual
    var currentPercentage: Double {
        guard oneRepMax > 0 else { return 0 }
        return (currentWeight / oneRepMax) * 100
    }
    
    // Verifica si el peso actual está en el rango correcto (45-55% del 1RM)
    var isInCorrectRange: Bool {
        let percentage = currentPercentage
        return percentage >= 45 && percentage <= 55
    }
    
    // Calcula las repeticiones en reserva estimadas
    func estimatedRepsInReserve() -> Int {
        guard let lastReps = lastRepsCompleted else { return 0 }
        // Estimación simple: si completó 15+ reps, probablemente tiene 1-3 en reserva
        if lastReps >= 15 {
            return min(3, max(1, 20 - lastReps))
        }
        return 0
    }
    
    // Calcula automáticamente el 1RM basándose en el historial de entrenamientos
    func calculateOneRMFromHistory(workoutLogs: [WorkoutLog], formula: OneRMCalculator.Formula = .epley) -> Double? {
        guard !workoutLogs.isEmpty else { return nil }
        
        // Convertir WorkoutLogs a WorkoutData
        let workoutData = workoutLogs.compactMap { log -> OneRMCalculator.WorkoutData? in
            guard log.weightUsed > 0, log.reps > 0 else { return nil }
            return OneRMCalculator.WorkoutData(
                weight: log.weightUsed,
                reps: log.reps,
                date: log.date
            )
        }
        
        guard !workoutData.isEmpty else { return nil }
        
        // Calcular el 1RM más reciente y confiable
        let calculatedOneRM = OneRMCalculator.findRecentReliableOneRM(from: workoutData, formula: formula)
        
        // Solo actualizar si el nuevo 1RM es significativamente diferente (más del 5%)
        let difference = abs(calculatedOneRM - oneRepMax) / oneRepMax
        if difference > 0.05 { // 5% de diferencia
            return calculatedOneRM
        }
        
        return nil
    }
    
    // Actualiza el 1RM y recalcula el peso de entrenamiento
    func updateOneRM(_ newOneRM: Double, formula: OneRMCalculator.Formula = .epley, isAutoCalculated: Bool = false) {
        self.oneRepMax = newOneRM
        self.currentWeight = OneRMCalculator.calculateBilboWeight(oneRM: newOneRM)
        self.oneRMFormula = formula.rawValue
        self.isOneRMAutoCalculated = isAutoCalculated
        self.oneRMCalculationDate = isAutoCalculated ? .now : nil
        self.updatedAt = .now
    }
    
    // Obtiene estadísticas del historial de entrenamientos
    func getWorkoutStats(workoutLogs: [WorkoutLog]) -> (maxWeight: Double, maxReps: Int, totalSessions: Int, lastWorkout: Date?) {
        let workoutData = workoutLogs.compactMap { log -> OneRMCalculator.WorkoutData? in
            guard log.weightUsed > 0, log.reps > 0 else { return nil }
            return OneRMCalculator.WorkoutData(
                weight: log.weightUsed,
                reps: log.reps,
                date: log.date
            )
        }
        
        return OneRMCalculator.getWorkoutStats(from: workoutData)
    }
    
    // Verifica si el 1RM necesita ser recalculado
    func shouldRecalculateOneRM() -> Bool {
        guard isOneRMAutoCalculated, let calculationDate = oneRMCalculationDate else { return false }
        
        // Recalcular si han pasado más de 7 días desde el último cálculo
        let daysSinceCalculation = Calendar.current.dateComponents([.day], from: calculationDate, to: .now).day ?? 0
        return daysSinceCalculation >= 7
    }
}
