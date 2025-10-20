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
                        Text("Ejercicio")
                        Spacer()
                        Text(exercise.title)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Peso usado")
                        Spacer()
                        TextField("kg", value: $weightUsed, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Series")
                        Spacer()
                        Stepper("\(sets)", value: $sets, in: 1...20)
                    }
                    
                    HStack {
                        Text("Repeticiones")
                        Spacer()
                        Stepper("\(reps)", value: $reps, in: 1...100)
                    }
                }
                
                Section("Notas") {
                    TextField("Añadir notas sobre el entrenamiento...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Resumen") {
                    HStack {
                        Text("Peso total levantado")
                        Spacer()
                        Text("\(totalWeight, specifier: "%.1f") kg")
                            .bold()
                            .foregroundStyle(exercise.category.color)
                    }
                }
            }
            .navigationTitle("Registrar Entrenamiento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
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
