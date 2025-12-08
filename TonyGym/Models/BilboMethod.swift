import Foundation
import SwiftData

// MARK: - BilboCycle Model
/// Representa un ciclo completo del Método Bilbo para un ejercicio específico
@Model
final class BilboCycle {
    @Relationship var exercise: Exercise?
    @Relationship(deleteRule: .cascade, inverse: \BilboDay.cycle) var days: [BilboDay]
    
    var initialOneRM: Double // 1RM inicial del ciclo
    var finalOneRM: Double? // 1RM final del ciclo (calculado al finalizar)
    var increment: Double // Incremento de peso por día (por defecto 2.5 kg)
    var numberOfDays: Int // Número total de días del ciclo
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    var isCompleted: Bool // Si el ciclo está completado
    var completedAt: Date? // Fecha de finalización del ciclo
    var oneRMFormula: String // Fórmula usada para calcular el 1RM
    
    init(exercise: Exercise?, initialOneRM: Double, numberOfDays: Int, increment: Double = 2.5, notes: String = "") {
        self.exercise = exercise
        self.days = []
        // Redondear el 1RM inicial a discos típicos
        self.initialOneRM = OneRMCalculator.roundToTypicalPlate(initialOneRM)
        self.finalOneRM = nil
        // Redondear el incremento a valores típicos
        self.increment = OneRMCalculator.roundToTypicalPlate(increment)
        self.numberOfDays = numberOfDays
        self.notes = notes
        self.createdAt = .now
        self.updatedAt = .now
        self.isCompleted = false
        self.completedAt = nil
        self.oneRMFormula = OneRMCalculator.Formula.epley.rawValue
        
        // Generar los días del ciclo
        generateDays()
    }
    
    /// Genera todos los días del ciclo con sus pesos objetivo calculados
    private func generateDays() {
        for dayNumber in 1...numberOfDays {
            let targetWeight = calculateTargetWeight(for: dayNumber)
            let day = BilboDay(
                cycle: self,
                dayNumber: dayNumber,
                targetWeight: targetWeight
            )
            days.append(day)
        }
    }
    
    /// Calcula el peso objetivo para un día específico
    /// Fórmula: peso objetivo = 1RM inicial + (día - 1) * incremento
    func calculateTargetWeight(for dayNumber: Int) -> Double {
        guard dayNumber >= 1 && dayNumber <= numberOfDays else { return initialOneRM }
        let weight = initialOneRM + (Double(dayNumber - 1) * increment)
        return OneRMCalculator.roundToTypicalPlate(weight)
    }
    
    /// Obtiene el día actual (el primero sin completar)
    var currentDay: BilboDay? {
        days.sorted(by: { $0.dayNumber < $1.dayNumber })
            .first { !$0.isCompleted }
    }
    
    /// Obtiene el progreso del ciclo (días completados / total de días)
    var progress: Double {
        guard numberOfDays > 0 else { return 0 }
        let completedDays = days.filter { $0.isCompleted }.count
        return Double(completedDays) / Double(numberOfDays)
    }
    
    /// Verifica si el ciclo está completo
    func checkCompletion() {
        let allCompleted = days.allSatisfy { $0.isCompleted }
        if allCompleted && !isCompleted {
            isCompleted = true
            completedAt = .now
            calculateFinalOneRM()
        }
    }
    
    /// Calcula el 1RM final del ciclo basándose en los días completados
    func calculateFinalOneRM() {
        let completedDays = days.filter { $0.isCompleted && $0.isValidWork && $0.actualWeight > 0 && $0.repsCompleted > 0 }
        guard !completedDays.isEmpty else { return }
        
        // Usar el mejor rendimiento (mayor peso x reps) para calcular el 1RM final
        let bestDay = completedDays.max { day1, day2 in
            (day1.actualWeight * Double(day1.repsCompleted)) < (day2.actualWeight * Double(day2.repsCompleted))
        }
        
        guard let bestDay = bestDay else { return }
        
        let formula = OneRMCalculator.Formula(rawValue: oneRMFormula) ?? .epley
        finalOneRM = OneRMCalculator.calculateOneRM(
            weight: bestDay.actualWeight,
            reps: bestDay.repsCompleted,
            formula: formula
        )
    }
    
    /// Reinicia el ciclo (marca todos los días como no completados)
    func resetCycle() {
        for day in days {
            day.reset()
        }
        isCompleted = false
        completedAt = nil
        finalOneRM = nil
        updatedAt = .now
    }
}

// MARK: - BilboDay Model
/// Representa un día individual dentro de un ciclo del Método Bilbo
@Model
final class BilboDay {
    @Relationship var cycle: BilboCycle?
    
    var dayNumber: Int // Número del día (1, 2, 3, ...)
    var targetWeight: Double // Peso objetivo calculado
    var actualWeight: Double // Peso real usado (0 si no se ha completado)
    var repsCompleted: Int // Repeticiones logradas (0 si no se ha completado)
    var isValidWork: Bool // Si el trabajo fue válido (trabajo = 1 en Excel)
    var estimatedOneRM: Double? // 1RM estimado calculado a partir de peso y reps
    var date: Date? // Fecha en que se completó el día
    var notes: String // Notas adicionales
    
    var isCompleted: Bool {
        actualWeight > 0 && repsCompleted > 0 && date != nil
    }
    
    init(cycle: BilboCycle?, dayNumber: Int, targetWeight: Double) {
        self.cycle = cycle
        self.dayNumber = dayNumber
        self.targetWeight = targetWeight
        self.actualWeight = 0
        self.repsCompleted = 0
        self.isValidWork = false
        self.estimatedOneRM = nil
        self.date = nil
        self.notes = ""
    }
    
    /// Completa el día con los datos proporcionados
    func complete(actualWeight: Double, repsCompleted: Int, isValidWork: Bool, date: Date = .now, notes: String = "", formula: OneRMCalculator.Formula = .epley) {
        self.actualWeight = actualWeight
        self.repsCompleted = repsCompleted
        self.isValidWork = isValidWork
        self.date = date
        self.notes = notes
        
        // Calcular 1RM estimado si hay datos válidos
        if actualWeight > 0 && repsCompleted > 0 {
            self.estimatedOneRM = OneRMCalculator.calculateOneRM(
                weight: actualWeight,
                reps: repsCompleted,
                formula: formula
            )
        }
        
        // Notificar al ciclo para verificar si está completo
        cycle?.checkCompletion()
        cycle?.updatedAt = .now
    }
    
    /// Resetea el día (lo marca como no completado)
    func reset() {
        actualWeight = 0
        repsCompleted = 0
        isValidWork = false
        estimatedOneRM = nil
        date = nil
        notes = ""
        cycle?.isCompleted = false
        cycle?.completedAt = nil
        cycle?.finalOneRM = nil
        cycle?.updatedAt = .now
    }
}

// MARK: - Legacy Models (mantenidos para compatibilidad durante la migración)
/// Modelo legacy - mantener temporalmente para migración de datos
@Model
final class BilboExercise {
    @Relationship var exercise: Exercise?
    @Relationship(deleteRule: .cascade, inverse: \BilboSession.bilboExercise) var sessions: [BilboSession]
    var oneRepMax: Double
    var currentWeight: Double
    var targetReps: Int
    var lastSessionDate: Date?
    var lastRepsCompleted: Int?
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    var isOneRMAutoCalculated: Bool
    var oneRMCalculationDate: Date?
    var oneRMFormula: String
    
    init(exercise: Exercise?, oneRepMax: Double, notes: String = "", isAutoCalculated: Bool = false) {
        self.exercise = exercise
        self.sessions = []
        self.oneRepMax = oneRepMax
        self.currentWeight = oneRepMax * 0.5
        self.targetReps = 15
        self.notes = notes
        self.createdAt = .now
        self.updatedAt = .now
        self.isOneRMAutoCalculated = isAutoCalculated
        self.oneRMCalculationDate = isAutoCalculated ? .now : nil
        self.oneRMFormula = OneRMCalculator.Formula.epley.rawValue
    }
    
    func suggestedNextWeight() -> Double {
        guard let lastReps = lastRepsCompleted else { return currentWeight }
        if lastReps > 15 {
            return OneRMCalculator.roundToIncrement(currentWeight + 2.5)
        }
        return currentWeight
    }
    
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

// MARK: - BilboCycle Extensions
extension BilboCycle {
    /// Obtiene estadísticas del ciclo
    func getCycleStats() -> (completedDays: Int, totalDays: Int, avgWeight: Double, maxWeight: Double, avgReps: Double, maxReps: Int, totalVolume: Double) {
        let completedDays = days.filter { $0.isCompleted }
        let totalDays = days.count
        
        guard !completedDays.isEmpty else {
            return (0, totalDays, 0, 0, 0, 0, 0)
        }
        
        let totalWeight = completedDays.reduce(0) { $0 + $1.actualWeight }
        let avgWeight = totalWeight / Double(completedDays.count)
        let maxWeight = completedDays.map { $0.actualWeight }.max() ?? 0
        
        let totalReps = completedDays.reduce(0) { $0 + $1.repsCompleted }
        let avgReps = Double(totalReps) / Double(completedDays.count)
        let maxReps = completedDays.map { $0.repsCompleted }.max() ?? 0
        
        let totalVolume = completedDays.reduce(0) { $0 + ($1.actualWeight * Double($1.repsCompleted)) }
        
        return (completedDays.count, totalDays, avgWeight, maxWeight, avgReps, maxReps, totalVolume)
    }
    
    /// Obtiene datos para gráficos de progresión
    func getProgressData() -> (weightData: [(Date, Double)], repsData: [(Date, Int)], volumeData: [(Date, Double)]) {
        let sortedDays = days.filter { $0.isCompleted && $0.date != nil }
            .sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
        
        let weightData = sortedDays.compactMap { day -> (Date, Double)? in
            guard let date = day.date else { return nil }
            return (date, day.actualWeight)
        }
        
        let repsData = sortedDays.compactMap { day -> (Date, Int)? in
            guard let date = day.date else { return nil }
            return (date, day.repsCompleted)
        }
        
        let volumeData = sortedDays.compactMap { day -> (Date, Double)? in
            guard let date = day.date else { return nil }
            return (date, day.actualWeight * Double(day.repsCompleted))
        }
        
        return (weightData, repsData, volumeData)
    }
}

// MARK: - Legacy Extensions (mantenidos para compatibilidad)
extension BilboExercise {
    var currentPercentage: Double {
        guard oneRepMax > 0 else { return 0 }
        return (currentWeight / oneRepMax) * 100
    }
    
    var isInCorrectRange: Bool {
        let percentage = currentPercentage
        return percentage >= 45 && percentage <= 55
    }
    
    func estimatedRepsInReserve() -> Int {
        guard let lastReps = lastRepsCompleted else { return 0 }
        if lastReps >= 15 {
            return min(3, max(1, 20 - lastReps))
        }
        return 0
    }
    
    func calculateOneRMFromHistory(workoutLogs: [WorkoutLog], formula: OneRMCalculator.Formula = .epley) -> Double? {
        guard !workoutLogs.isEmpty else { return nil }
        
        let workoutData = workoutLogs.compactMap { log -> OneRMCalculator.WorkoutData? in
            guard log.weightUsed > 0, log.reps > 0 else { return nil }
            return OneRMCalculator.WorkoutData(
                weight: log.weightUsed,
                reps: log.reps,
                date: log.date
            )
        }
        
        guard !workoutData.isEmpty else { return nil }
        
        let calculatedOneRM = OneRMCalculator.findRecentReliableOneRM(from: workoutData, formula: formula)
        let difference = abs(calculatedOneRM - oneRepMax) / oneRepMax
        if difference > 0.05 {
            return calculatedOneRM
        }
        
        return nil
    }
    
    func updateOneRM(_ newOneRM: Double, formula: OneRMCalculator.Formula = .epley, isAutoCalculated: Bool = false) {
        self.oneRepMax = newOneRM
        self.currentWeight = OneRMCalculator.calculateBilboWeight(oneRM: newOneRM)
        self.oneRMFormula = formula.rawValue
        self.isOneRMAutoCalculated = isAutoCalculated
        self.oneRMCalculationDate = isAutoCalculated ? .now : nil
        self.updatedAt = .now
    }
    
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
    
    func shouldRecalculateOneRM() -> Bool {
        guard isOneRMAutoCalculated, let calculationDate = oneRMCalculationDate else { return false }
        let daysSinceCalculation = Calendar.current.dateComponents([.day], from: calculationDate, to: .now).day ?? 0
        return daysSinceCalculation >= 7
    }
    
    func progressPercentage() -> Double {
        guard !sessions.isEmpty else { return 0 }
        guard let firstSession = sessions.sorted(by: { $0.date < $1.date }).first else { return 0 }
        
        let initialWeight = firstSession.weightUsed
        let weightIncrease = currentWeight - initialWeight
        let targetIncrease: Double = 10.0
        let progress = min(100, max(0, (weightIncrease / targetIncrease) * 100))
        return progress
    }
    
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
        
        var sessionsByWeek: [Date: Int] = [:]
        let calendar = Calendar.current
        for session in sortedSessions {
            if let weekStart = calendar.dateInterval(of: .weekOfYear, for: session.date)?.start {
                sessionsByWeek[weekStart, default: 0] += 1
            }
        }
        
        return (totalSessions, avgWeight, maxWeight, avgReps, maxReps, totalVolume, sessionsByWeek)
    }
    
    func getProgressData() -> (weightData: [(Date, Double)], repsData: [(Date, Int)], volumeData: [(Date, Double)]) {
        let sortedSessions = sessions.sorted { $0.date < $1.date }
        
        let weightData = sortedSessions.map { ($0.date, $0.weightUsed) }
        let repsData = sortedSessions.map { ($0.date, $0.repsCompleted) }
        let volumeData = sortedSessions.map { ($0.date, $0.weightUsed * Double($0.repsCompleted)) }
        
        return (weightData, repsData, volumeData)
    }
    
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
