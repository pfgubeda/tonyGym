import SwiftUI
import SwiftData

struct WeightEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let exercise: Exercise
    @Binding var customWeight: Double
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text(exercise.title)
                        .font(.title2)
                        .bold()
                        .multilineTextAlignment(.center)
                    
                    Text(exercise.category.displayName)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(exercise.category.color.opacity(0.2))
                        )
                        .foregroundStyle(exercise.category.color)
                }
                
                VStack(spacing: 16) {
                    Text("\(NSLocalizedString("weight.editor.current", comment: "Current weight")): \(exercise.defaultWeightKg, specifier: "%.1f") \(NSLocalizedString("unit.kg", comment: "kg unit"))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    VStack(spacing: 8) {
                        Text(NSLocalizedString("weight.editor.new", comment: "New weight"))
                            .font(.headline)
                        
                        HStack {
                            TextField(NSLocalizedString("weight.editor.weight", comment: "Weight"), value: $customWeight, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .font(.title)
                                .bold()
                            
                            Text(NSLocalizedString("unit.kg", comment: "kg unit"))
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        )
                    }
                    
                    // Quick adjustment buttons
                    HStack(spacing: 16) {
                        Button {
                            customWeight = max(0, customWeight - 2.5)
                        } label: {
                            VStack {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                Text("-2.5")
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            customWeight = max(0, customWeight - 1.25)
                        } label: {
                            VStack {
                                Image(systemName: "minus.circle")
                                    .font(.title2)
                                Text("-1.25")
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Button {
                            customWeight += 1.25
                        } label: {
                            VStack {
                                Image(systemName: "plus.circle")
                                    .font(.title2)
                                Text("+1.25")
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            customWeight += 2.5
                        } label: {
                            VStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                Text("+2.5")
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle(NSLocalizedString("weight.editor.title", comment: "Edit weight"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.cancel", comment: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("common.save", comment: "Save")) {
                        saveWeight()
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
    
    private func saveWeight() {
        // Update the exercise default weight
        exercise.defaultWeightKg = customWeight
        exercise.updatedAt = .now
        
        // Also save to workout log for statistics
        let workoutLog = WorkoutLog(
            date: Date(),
            exercise: exercise,
            weightUsed: customWeight,
            sets: 1,
            reps: 1,
            notes: NSLocalizedString("home.exercise.weight.updated", comment: "Weight updated from Home")
        )
        context.insert(workoutLog)
    }
}
