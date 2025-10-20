import Foundation
import SwiftData

@Model
final class WorkoutLog {
    var date: Date
    var exerciseId: String // Store exercise persistentModelID as string
    var weightUsed: Double
    var sets: Int
    var reps: Int
    var notes: String
    @Relationship var exercise: Exercise?
    
    init(date: Date, exercise: Exercise?, weightUsed: Double, sets: Int = 1, reps: Int = 1, notes: String = "") {
        self.date = date
        self.exercise = exercise
        self.exerciseId = exercise?.persistentModelID.storeIdentifier ?? ""
        self.weightUsed = weightUsed
        self.sets = sets
        self.reps = reps
        self.notes = notes
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
