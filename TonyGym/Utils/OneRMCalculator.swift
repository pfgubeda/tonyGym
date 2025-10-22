import Foundation

struct OneRMCalculator {
    
    // Fórmulas disponibles para calcular 1RM
    enum Formula: String, CaseIterable {
        case epley = "Epley"
        case brzycki = "Brzycki"
        case lombardi = "Lombardi"
        case oConnor = "O'Connor"
        case wathan = "Wathan"
        
        var displayName: String {
            switch self {
            case .epley: return "Epley"
            case .brzycki: return "Brzycki"
            case .lombardi: return "Lombardi"
            case .oConnor: return "O'Connor"
            case .wathan: return "Wathan"
            }
        }
        
        var description: String {
            switch self {
            case .epley: return "Fórmula más común y precisa para la mayoría de ejercicios"
            case .brzycki: return "Buena para ejercicios de fuerza máxima"
            case .lombardi: return "Precisa para ejercicios de potencia"
            case .oConnor: return "Conservadora, subestima el 1RM"
            case .wathan: return "Buena para ejercicios de resistencia"
            }
        }
    }
    
    // Estructura para representar un entrenamiento
    struct WorkoutData {
        let weight: Double
        let reps: Int
        let date: Date
        
        init(weight: Double, reps: Int, date: Date = Date()) {
            self.weight = weight
            self.reps = reps
            self.date = date
        }
    }
    
    // Calcula el 1RM usando una fórmula específica
    static func calculateOneRM(weight: Double, reps: Int, formula: Formula = .epley) -> Double {
        guard reps > 0, weight > 0 else { return 0 }
        
        switch formula {
        case .epley:
            return weight * (1 + (Double(reps) / 30.0))
        case .brzycki:
            return weight * (36.0 / (37.0 - Double(reps)))
        case .lombardi:
            return weight * pow(Double(reps), 0.10)
        case .oConnor:
            return weight * (1 + (Double(reps) / 40.0))
        case .wathan:
            return weight * (100.0 / (101.3 - 2.67123 * Double(reps)))
        }
    }
    
    // Calcula el 1RM promedio usando múltiples fórmulas
    static func calculateAverageOneRM(weight: Double, reps: Int) -> Double {
        let formulas = Formula.allCases
        let results = formulas.map { calculateOneRM(weight: weight, reps: reps, formula: $0) }
        return results.reduce(0, +) / Double(results.count)
    }
    
    // Encuentra el mejor 1RM basándose en el historial de entrenamientos
    static func findBestOneRM(from workouts: [WorkoutData], formula: Formula = .epley) -> Double {
        guard !workouts.isEmpty else { return 0 }
        
        // Ordenar por fecha (más reciente primero)
        let sortedWorkouts = workouts.sorted { $0.date > $1.date }
        
        // Buscar el mejor rendimiento (mayor peso x reps)
        var bestOneRM: Double = 0
        
        for workout in sortedWorkouts {
            let oneRM = calculateOneRM(weight: workout.weight, reps: workout.reps, formula: formula)
            if oneRM > bestOneRM {
                bestOneRM = oneRM
            }
        }
        
        return bestOneRM
    }
    
    // Calcula el 1RM más reciente y confiable
    static func findRecentReliableOneRM(from workouts: [WorkoutData], formula: Formula = .epley, maxDaysBack: Int = 30) -> Double {
        guard !workouts.isEmpty else { return 0 }
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -maxDaysBack, to: Date()) ?? Date()
        let recentWorkouts = workouts.filter { $0.date >= cutoffDate }
        
        guard !recentWorkouts.isEmpty else { return findBestOneRM(from: workouts, formula: formula) }
        
        // Ordenar por rendimiento (peso x reps) descendente
        let sortedByPerformance = recentWorkouts.sorted { 
            ($0.weight * Double($0.reps)) > ($1.weight * Double($1.reps))
        }
        
        // Tomar el mejor rendimiento reciente
        if let bestRecent = sortedByPerformance.first {
            return calculateOneRM(weight: bestRecent.weight, reps: bestRecent.reps, formula: formula)
        }
        
        return 0
    }
    
    // Calcula el peso de entrenamiento para el método BILBO (50% del 1RM)
    static func calculateBilboWeight(oneRM: Double) -> Double {
        return roundToIncrement(oneRM * 0.5, increment: 1.25)
    }
    
    // Verifica si un peso es apropiado para el método BILBO
    static func isAppropriateBilboWeight(weight: Double, oneRM: Double) -> Bool {
        let bilboWeight = calculateBilboWeight(oneRM: oneRM)
        let tolerance = bilboWeight * 0.1 // 10% de tolerancia
        return abs(weight - bilboWeight) <= tolerance
    }
    
    // Calcula el porcentaje del 1RM
    static func calculatePercentage(weight: Double, oneRM: Double) -> Double {
        guard oneRM > 0 else { return 0 }
        return (weight / oneRM) * 100
    }
    
    // Estima las repeticiones máximas para un peso dado
    static func estimateMaxReps(weight: Double, oneRM: Double, formula: Formula = .epley) -> Int {
        guard oneRM > 0, weight > 0 else { return 0 }
        
        // Usar la fórmula inversa para estimar reps
        switch formula {
        case .epley:
            return Int((oneRM / weight - 1) * 30)
        case .brzycki:
            return Int(37 - (36 * weight / oneRM))
        case .lombardi:
            return Int(pow(oneRM / weight, 10))
        case .oConnor:
            return Int((oneRM / weight - 1) * 40)
        case .wathan:
            return Int((101.3 - 100 * weight / oneRM) / 2.67123)
        }
    }
    
    // Redondea a un incremento típico de discos (por defecto 1.25 kg)
    static func roundToIncrement(_ value: Double, increment: Double = 1.25) -> Double {
        guard increment > 0 else { return value }
        return (value / increment).rounded() * increment
    }
    
    // Valida si los datos de entrenamiento son realistas
    static func validateWorkoutData(weight: Double, reps: Int) -> Bool {
        // Validaciones básicas
        guard weight > 0, reps > 0, reps <= 50 else { return false }
        
        // Validar que el peso no sea excesivamente alto para las repeticiones
        // Esto es una validación básica - en la práctica, esto dependería del ejercicio
        let maxReasonableWeight = 200.0 // kg
        return weight <= maxReasonableWeight
    }
    
    // Obtiene estadísticas del historial de entrenamientos
    static func getWorkoutStats(from workouts: [WorkoutData]) -> (maxWeight: Double, maxReps: Int, totalSessions: Int, lastWorkout: Date?) {
        guard !workouts.isEmpty else { return (0, 0, 0, nil) }
        
        let maxWeight = workouts.map { $0.weight }.max() ?? 0
        let maxReps = workouts.map { $0.reps }.max() ?? 0
        let totalSessions = workouts.count
        let lastWorkout = workouts.map { $0.date }.max()
        
        return (maxWeight, maxReps, totalSessions, lastWorkout)
    }
}
