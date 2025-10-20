import SwiftUI
import SwiftData

struct WorkoutLogSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    let exercise: Exercise
    let entry: RoutineEntry
    
    @State private var weightUsed: Double
    @State private var sets: Int = 1
    @State private var reps: Int = 1
    @State private var notes: String = ""
    
    init(exercise: Exercise, entry: RoutineEntry) {
        self.exercise = exercise
        self.entry = entry
        self._weightUsed = State(initialValue: exercise.defaultWeightKg)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(NSLocalizedString("workout.log.exercise", comment: "Exercise"))
                        Spacer()
                        Text(exercise.title)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text(NSLocalizedString("workout.log.weight", comment: "Weight used"))
                        Spacer()
                        TextField(NSLocalizedString("unit.kg", comment: "kg unit"), value: $weightUsed, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text(NSLocalizedString("workout.log.sets", comment: "Sets"))
                        Spacer()
                        Stepper("\(sets)", value: $sets, in: 1...20)
                    }
                    
                    HStack {
                        Text(NSLocalizedString("workout.log.reps", comment: "Reps"))
                        Spacer()
                        Stepper("\(reps)", value: $reps, in: 1...100)
                    }
                }
                
                Section(NSLocalizedString("workout.log.notes", comment: "Notes")) {
                    TextField(NSLocalizedString("workout.log.notes.placeholder", comment: "Notes placeholder"), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(NSLocalizedString("workout.log.summary", comment: "Summary")) {
                    HStack {
                        Text(NSLocalizedString("workout.log.total.weight", comment: "Total weight lifted"))
                        Spacer()
                        Text("\(totalWeight, specifier: "%.1f") \(NSLocalizedString("unit.kg", comment: "kg unit"))")
                            .bold()
                            .foregroundStyle(exercise.category.color)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("workout.log.title", comment: "Log workout"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.cancel", comment: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("common.save", comment: "Save")) {
                        saveWorkoutLog()
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
    
    private var totalWeight: Double {
        weightUsed * Double(sets * reps)
    }
    
    private func saveWorkoutLog() {
        let workoutLog = WorkoutLog(
            date: Date(),
            exercise: exercise,
            weightUsed: weightUsed,
            sets: sets,
            reps: reps,
            notes: notes
        )
        context.insert(workoutLog)
        
        // Only update the exercise default weight if this is the highest weight ever used
        // This preserves the user's personal record as the new default
        if weightUsed > exercise.defaultWeightKg {
            exercise.defaultWeightKg = weightUsed
            exercise.updatedAt = .now
        }
    }
}
