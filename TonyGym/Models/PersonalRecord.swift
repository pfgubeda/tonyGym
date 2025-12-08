import Foundation
import SwiftData

/// Representa un récord personal (PR) para un ejercicio
@Model
final class PersonalRecord {
    @Relationship var exercise: Exercise?
    var recordType: Int // 0 = peso máximo, 1 = reps máximo, 2 = volumen máximo (peso × reps × sets)
    var weight: Double
    var reps: Int
    var sets: Int
    var volume: Double // peso × reps × sets
    var date: Date
    var previousRecordDate: Date? // Fecha del PR anterior (para calcular tiempo entre PRs)
    var daysSincePreviousPR: Int? // Días transcurridos desde el PR anterior
    var notes: String
    
    init(exercise: Exercise?, recordType: RecordType, weight: Double, reps: Int, sets: Int, date: Date = .now, previousRecordDate: Date? = nil, notes: String = "") {
        self.exercise = exercise
        self.recordType = recordType.rawValue
        self.weight = weight
        self.reps = reps
        self.sets = sets
        self.volume = weight * Double(reps * sets)
        self.date = date
        self.previousRecordDate = previousRecordDate
        if let previousDate = previousRecordDate {
            let days = Calendar.current.dateComponents([.day], from: previousDate, to: date).day ?? 0
            self.daysSincePreviousPR = days
        } else {
            self.daysSincePreviousPR = nil
        }
        self.notes = notes
    }
    
    enum RecordType: Int, CaseIterable {
        case maxWeight = 0
        case maxReps = 1
        case maxVolume = 2
        
        var displayName: String {
            switch self {
            case .maxWeight: return NSLocalizedString("pr.type.weight", comment: "Max weight")
            case .maxReps: return NSLocalizedString("pr.type.reps", comment: "Max reps")
            case .maxVolume: return NSLocalizedString("pr.type.volume", comment: "Max volume")
            }
        }
    }
    
    var type: RecordType {
        get { RecordType(rawValue: recordType) ?? .maxWeight }
        set { recordType = newValue.rawValue }
    }
}
