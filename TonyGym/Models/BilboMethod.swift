import Foundation
import SwiftData

@Model
final class BilboExercise {
    @Relationship var exercise: Exercise?
    @Relationship(deleteRule: .cascade, inverse: \BilboSession.bilboExercise) var sessions: [BilboSession]
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
        self.sessions = []
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
    
    // MARK: - Progress Tracking Methods
    
    // Calcula el progreso basado en el peso actual vs peso inicial (baseline)
    func progressPercentage() -> Double {
        guard !sessions.isEmpty else { return 0 }
        guard let firstSession = sessions.sorted(by: { $0.date < $1.date }).first else { return 0 }
        
        let initialWeight = firstSession.weightUsed
        let weightIncrease = currentWeight - initialWeight
        // Consideramos un progreso del 100% cuando aumentamos 10kg desde el inicio
        let targetIncrease: Double = 10.0
        let progress = min(100, max(0, (weightIncrease / targetIncrease) * 100))
        return progress
    }
    
    // Obtiene estadísticas de las sesiones BILBO
    func getBilboStats() -> (totalSessions: Int, avgWeight: Double, maxWeight: Double, avgReps: Double, maxReps: Int, totalVolume: Double, sessionsByWeek: [Date: Int]) {
        guard !sessions.isEmpty else {
            return (0, 0, 0, 0, 0, 0, [:])
        }
        
        let sortedSessions = sessions.sorted { $0.date < $1.date }
        let totalSessions = sortedSessions.count
        let totalWeight = sortedSessions.reduce(0) { $0 + $1.weightUsed }
        let avgWeight = totalWeight / Double(totalSessions)
        let maxWeight = sortedSessions.map { $0.weightUsed }.max() ?? 0
        let totalReps = sortedSessions.reduce(0) { $0 + $1.repsCompleted }
        let avgReps = Double(totalReps) / Double(totalSessions)
        let maxReps = sortedSessions.map { $0.repsCompleted }.max() ?? 0
        let totalVolume = sortedSessions.reduce(0) { $0 + ($1.weightUsed * Double($1.repsCompleted)) }
        
        // Agrupar sesiones por semana
        var sessionsByWeek: [Date: Int] = [:]
        let calendar = Calendar.current
        for session in sortedSessions {
            if let weekStart = calendar.dateInterval(of: .weekOfYear, for: session.date)?.start {
                sessionsByWeek[weekStart, default: 0] += 1
            }
        }
        
        return (totalSessions, avgWeight, maxWeight, avgReps, maxReps, totalVolume, sessionsByWeek)
    }
    
    // Obtiene datos para gráficos de progresión
    func getProgressData() -> (weightData: [(Date, Double)], repsData: [(Date, Int)], volumeData: [(Date, Double)]) {
        let sortedSessions = sessions.sorted { $0.date < $1.date }
        
        let weightData = sortedSessions.map { ($0.date, $0.weightUsed) }
        let repsData = sortedSessions.map { ($0.date, $0.repsCompleted) }
        let volumeData = sortedSessions.map { ($0.date, $0.weightUsed * Double($0.repsCompleted)) }
        
        return (weightData, repsData, volumeData)
    }
    
    // Calcula la mejora desde la primera sesión
    func getImprovement() -> (weightIncrease: Double, repsIncrease: Int, volumeIncrease: Double, percentageImprovement: Double) {
        guard !sessions.isEmpty,
              let firstSession = sessions.sorted(by: { $0.date < $1.date }).first,
              let lastSession = sessions.sorted(by: { $0.date < $1.date }).last else {
            return (0, 0, 0, 0)
        }
        
        let weightIncrease = lastSession.weightUsed - firstSession.weightUsed
        let repsIncrease = lastSession.repsCompleted - firstSession.repsCompleted
        let firstVolume = firstSession.weightUsed * Double(firstSession.repsCompleted)
        let lastVolume = lastSession.weightUsed * Double(lastSession.repsCompleted)
        let volumeIncrease = lastVolume - firstVolume
        let percentageImprovement = firstVolume > 0 ? ((lastVolume - firstVolume) / firstVolume) * 100 : 0
        
        return (weightIncrease, repsIncrease, volumeIncrease, percentageImprovement)
    }
}
