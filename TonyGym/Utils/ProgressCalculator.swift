import Foundation
import SwiftData

/// Utilidad para calcular métricas de progreso y estadísticas
struct ProgressCalculator {
    
    // MARK: - Métricas Generales
    
    /// Calcula el total de entrenamientos
    static func totalWorkouts(from logs: [WorkoutLog]) -> Int {
        return logs.count
    }
    
    /// Calcula el peso total levantado (suma de todos los pesos × reps × sets)
    static func totalWeightLifted(from logs: [WorkoutLog]) -> Double {
        return logs.reduce(0) { total, log in
            total + log.totalVolume
        }
    }
    
    /// Calcula el número de días activos (días únicos con entrenamientos)
    static func activeDays(from logs: [WorkoutLog]) -> Int {
        let calendar = Calendar.current
        let uniqueDays = Set(logs.map { calendar.startOfDay(for: $0.date) })
        return uniqueDays.count
    }
    
    // MARK: - Volumen
    
    /// Calcula el volumen total por semana
    static func volumeByWeek(from logs: [WorkoutLog]) -> [(weekStart: Date, volume: Double)] {
        let calendar = Calendar.current
        var weekVolumes: [Date: Double] = [:]
        
        for log in logs {
            guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: log.date)?.start else { continue }
            let volume = log.totalVolume
            weekVolumes[weekStart, default: 0] += volume
        }
        
        return weekVolumes.map { (weekStart: $0.key, volume: $0.value) }
            .sorted { $0.weekStart < $1.weekStart }
    }
    
    /// Calcula el volumen total por mes
    static func volumeByMonth(from logs: [WorkoutLog]) -> [(monthStart: Date, volume: Double)] {
        let calendar = Calendar.current
        var monthVolumes: [Date: Double] = [:]
        
        for log in logs {
            let components = calendar.dateComponents([.year, .month], from: log.date)
            guard let monthStart = calendar.date(from: components) else { continue }
            let volume = log.totalVolume
            monthVolumes[monthStart, default: 0] += volume
        }
        
        return monthVolumes.map { (monthStart: $0.key, volume: $0.value) }
            .sorted { $0.monthStart < $1.monthStart }
    }
    
    // MARK: - Comparación de Períodos
    
    struct PeriodComparison {
        let currentPeriod: PeriodStats
        let previousPeriod: PeriodStats
        let change: Double // Porcentaje de cambio
        let changeType: ChangeType
        
        enum ChangeType {
            case increase
            case decrease
            case noChange
        }
    }
    
    struct PeriodStats {
        let totalWorkouts: Int
        let totalVolume: Double
        let activeDays: Int
        let averageVolumePerWorkout: Double
    }
    
    /// Compara dos períodos de tiempo
    static func comparePeriods(
        currentLogs: [WorkoutLog],
        previousLogs: [WorkoutLog]
    ) -> PeriodComparison {
        let currentStats = PeriodStats(
            totalWorkouts: totalWorkouts(from: currentLogs),
            totalVolume: totalWeightLifted(from: currentLogs),
            activeDays: activeDays(from: currentLogs),
            averageVolumePerWorkout: {
                let workouts = totalWorkouts(from: currentLogs)
                return workouts > 0 ? totalWeightLifted(from: currentLogs) / Double(workouts) : 0
            }()
        )
        
        let previousStats = PeriodStats(
            totalWorkouts: totalWorkouts(from: previousLogs),
            totalVolume: totalWeightLifted(from: previousLogs),
            activeDays: activeDays(from: previousLogs),
            averageVolumePerWorkout: {
                let workouts = totalWorkouts(from: previousLogs)
                return workouts > 0 ? totalWeightLifted(from: previousLogs) / Double(workouts) : 0
            }()
        )
        
        let change: Double
        let changeType: PeriodComparison.ChangeType
        
        if previousStats.totalVolume > 0 {
            change = ((currentStats.totalVolume - previousStats.totalVolume) / previousStats.totalVolume) * 100
            if change > 0.1 {
                changeType = .increase
            } else if change < -0.1 {
                changeType = .decrease
            } else {
                changeType = .noChange
            }
        } else {
            change = currentStats.totalVolume > 0 ? 100 : 0
            changeType = currentStats.totalVolume > 0 ? .increase : .noChange
        }
        
        return PeriodComparison(
            currentPeriod: currentStats,
            previousPeriod: previousStats,
            change: change,
            changeType: changeType
        )
    }
    
    /// Obtiene logs de la semana actual
    static func currentWeekLogs(from logs: [WorkoutLog]) -> [WorkoutLog] {
        let calendar = Calendar.current
        let now = Date()
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else { return [] }
        return logs.filter { weekInterval.contains($0.date) }
    }
    
    /// Obtiene logs de la semana pasada
    static func previousWeekLogs(from logs: [WorkoutLog]) -> [WorkoutLog] {
        let calendar = Calendar.current
        let now = Date()
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now),
              let previousWeekStart = calendar.date(byAdding: .day, value: -7, to: weekInterval.start),
              let previousWeekInterval = calendar.dateInterval(of: .weekOfYear, for: previousWeekStart) else {
            return []
        }
        return logs.filter { previousWeekInterval.contains($0.date) }
    }
    
    /// Obtiene logs del mes actual
    static func currentMonthLogs(from logs: [WorkoutLog]) -> [WorkoutLog] {
        let calendar = Calendar.current
        let now = Date()
        guard let monthInterval = calendar.dateInterval(of: .month, for: now) else { return [] }
        return logs.filter { monthInterval.contains($0.date) }
    }
    
    /// Obtiene logs del mes pasado
    static func previousMonthLogs(from logs: [WorkoutLog]) -> [WorkoutLog] {
        let calendar = Calendar.current
        let now = Date()
        guard let monthInterval = calendar.dateInterval(of: .month, for: now),
              let previousMonthStart = calendar.date(byAdding: .month, value: -1, to: monthInterval.start),
              let previousMonthInterval = calendar.dateInterval(of: .month, for: previousMonthStart) else {
            return []
        }
        return logs.filter { previousMonthInterval.contains($0.date) }
    }
    
    // MARK: - Personal Records
    
    /// Detecta si un workout log es un nuevo PR
    static func detectNewPR(
        log: WorkoutLog,
        existingPRs: [PersonalRecord],
        allLogs: [WorkoutLog]
    ) -> [PersonalRecord.RecordType] {
        guard let exercise = log.exercise else { return [] }
        
        var newPRs: [PersonalRecord.RecordType] = []
        
        // Filtrar PRs y logs del mismo ejercicio
        let exercisePRs = existingPRs.filter { $0.exercise?.id == exercise.id }
        let exerciseLogs = allLogs.filter { $0.exercise?.id == exercise.id }
        
        let currentVolume = log.totalVolume
        let currentMaxWeight = log.maxWeight
        let currentTotalReps = log.totalReps
        
        // Verificar PR de peso máximo
        let maxWeightPR = exercisePRs.first { $0.type == .maxWeight }
        let maxWeight = maxWeightPR?.weight ?? 0
        if currentMaxWeight > maxWeight {
            newPRs.append(.maxWeight)
        }
        
        // Verificar PR de reps máximo
        let maxRepsPR = exercisePRs.first { $0.type == .maxReps }
        let maxReps = maxRepsPR?.reps ?? 0
        if currentTotalReps > maxReps {
            newPRs.append(.maxReps)
        }
        
        // Verificar PR de volumen máximo
        let maxVolumePR = exercisePRs.first { $0.type == .maxVolume }
        let maxVolume = maxVolumePR?.volume ?? 0
        if currentVolume > maxVolume {
            newPRs.append(.maxVolume)
        }
        
        return newPRs
    }
    
    /// Crea un nuevo PR basado en un workout log
    static func createPR(
        from log: WorkoutLog,
        type: PersonalRecord.RecordType,
        existingPRs: [PersonalRecord],
        context: ModelContext
    ) -> PersonalRecord {
        guard let exercise = log.exercise else {
            fatalError("Cannot create PR without exercise")
        }
        
        // Encontrar el PR anterior del mismo tipo
        let previousPR = existingPRs
            .filter { $0.exercise?.id == exercise.id && $0.type == type }
            .sorted { $0.date > $1.date }
            .first
        
        let volume = log.totalVolume
        
        let pr = PersonalRecord(
            exercise: exercise,
            recordType: type,
            weight: log.maxWeight,
            reps: log.totalReps,
            sets: log.sets,
            date: log.date,
            previousRecordDate: previousPR?.date,
            notes: log.notes
        )
        
        context.insert(pr)
        return pr
    }
    
    /// Obtiene el mejor PR de un ejercicio
    static func bestPR(for exercise: Exercise, from PRs: [PersonalRecord], type: PersonalRecord.RecordType) -> PersonalRecord? {
        return PRs
            .filter { $0.exercise?.id == exercise.id && $0.type == type }
            .sorted { pr1, pr2 in
                switch type {
                case .maxWeight:
                    return pr1.weight > pr2.weight
                case .maxReps:
                    return pr1.reps > pr2.reps
                case .maxVolume:
                    return pr1.volume > pr2.volume
                }
            }
            .first
    }
}
