import Foundation
import SwiftData

/// Representa una serie individual dentro de un entrenamiento
@Model
final class WorkoutSet {
    @Relationship var workoutLog: WorkoutLog?
    var setNumber: Int // Número de serie (1, 2, 3, ...)
    var weight: Double
    var reps: Int
    var rpe: Int? // Rate of Perceived Exertion (1-10, opcional)
    var restTime: TimeInterval? // Tiempo de descanso después de esta serie (en segundos)
    var isCompleted: Bool
    var notes: String
    var completedAt: Date?
    
    init(
        workoutLog: WorkoutLog? = nil,
        setNumber: Int,
        weight: Double,
        reps: Int,
        rpe: Int? = nil,
        restTime: TimeInterval? = nil,
        isCompleted: Bool = false,
        notes: String = ""
    ) {
        self.workoutLog = workoutLog
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.restTime = restTime
        self.isCompleted = isCompleted
        self.notes = notes
        self.completedAt = nil
    }
    
    /// Marca la serie como completada
    func complete() {
        self.isCompleted = true
        self.completedAt = .now
    }
    
    /// Calcula el volumen de esta serie (peso × reps)
    var volume: Double {
        return weight * Double(reps)
    }
}

@Model
final class WorkoutLog {
    var date: Date
    var exerciseId: String // Store exercise persistentModelID as string
    var weightUsed: Double // Peso promedio o peso usado (para compatibilidad)
    var sets: Int // Número total de series (para compatibilidad)
    var reps: Int // Reps promedio o total (para compatibilidad)
    var notes: String
    @Relationship var exercise: Exercise?
    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.workoutLog) var individualSets: [WorkoutSet] // Series individuales
    
    init(date: Date, exercise: Exercise?, weightUsed: Double, sets: Int = 1, reps: Int = 1, notes: String = "") {
        self.date = date
        self.exercise = exercise
        self.exerciseId = exercise?.persistentModelID.storeIdentifier ?? ""
        self.weightUsed = weightUsed
        self.sets = sets
        self.reps = reps
        self.notes = notes
        self.individualSets = []
    }
    
    /// Calcula el volumen total del entrenamiento
    var totalVolume: Double {
        if !individualSets.isEmpty {
            return individualSets.reduce(0) { $0 + $1.volume }
        }
        // Fallback a cálculo simple para compatibilidad
        return weightUsed * Double(sets * reps)
    }
    
    /// Obtiene el peso máximo usado en las series
    var maxWeight: Double {
        if !individualSets.isEmpty {
            return individualSets.map { $0.weight }.max() ?? weightUsed
        }
        return weightUsed
    }
    
    /// Obtiene el número total de repeticiones
    var totalReps: Int {
        if !individualSets.isEmpty {
            return individualSets.reduce(0) { $0 + $1.reps }
        }
        return sets * reps
    }
    
    /// Verifica si tiene series individuales registradas
    var hasIndividualSets: Bool {
        return !individualSets.isEmpty
    }
}

@Model
final class DailyProgress {
    var date: Date
    var totalExercises: Int
    var totalWeight: Double
    var duration: TimeInterval // in minutes
    var notes: String
    
    init(date: Date, totalExercises: Int = 0, totalWeight: Double = 0, duration: TimeInterval = 0, notes: String = "") {
        self.date = date
        self.totalExercises = totalExercises
        self.totalWeight = totalWeight
        self.duration = duration
        self.notes = notes
    }
}
