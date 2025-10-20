import SwiftUI
import SwiftData

struct WeightEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let exercise: Exercise
    @Binding var customWeight: Double
    @StateObject private var weightFormatter = WeightFormatter.shared
    
    // Display weight in user's preferred unit
    @State private var displayWeight: Double = 0
    
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
                    Text("\(NSLocalizedString("weight.editor.current", comment: "Current weight")): \(weightFormatter.formatWeight(exercise.defaultWeightKg))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    VStack(spacing: 8) {
                        Text(NSLocalizedString("weight.editor.new", comment: "New weight"))
                            .font(.headline)
                        
                        HStack {
                            TextField(NSLocalizedString("weight.editor.weight", comment: "Weight"), value: $displayWeight, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .font(.title)
                                .bold()
                            
                            Text(weightFormatter.unitNameShort)
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
                            displayWeight = max(0, displayWeight - weightIncrement)
                        } label: {
                            VStack {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                Text("-\(weightIncrement, specifier: "%.1f")")
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            displayWeight = max(0, displayWeight - (weightIncrement / 2))
                        } label: {
                            VStack {
                                Image(systemName: "minus.circle")
                                    .font(.title2)
                                Text("-\(weightIncrement / 2, specifier: "%.1f")")
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Button {
                            displayWeight += (weightIncrement / 2)
                        } label: {
                            VStack {
                                Image(systemName: "plus.circle")
                                    .font(.title2)
                                Text("+\(weightIncrement / 2, specifier: "%.1f")")
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            displayWeight += weightIncrement
                        } label: {
                            VStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                Text("+\(weightIncrement, specifier: "%.1f")")
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
            .onAppear {
                // Initialize displayWeight with converted value
                displayWeight = weightFormatter.convertFromKilograms(customWeight)
            }
        }
    }
    
    // Weight increment based on unit (2.5 kg or 5 lb)
    private var weightIncrement: Double {
        weightFormatter.preferredUnit == .kilograms ? 2.5 : 5.0
    }
    
    private func saveWeight() {
        // Convert display weight back to kg for storage
        let weightInKg = weightFormatter.convertToKilograms(displayWeight)
        
        // Update the exercise default weight
        exercise.defaultWeightKg = weightInKg
        exercise.updatedAt = .now
        
        // Update the binding
        customWeight = weightInKg
        
        // Also save to workout log for statistics
        let workoutLog = WorkoutLog(
            date: Date(),
            exercise: exercise,
            weightUsed: weightInKg,
            sets: 1,
            reps: 1,
            notes: NSLocalizedString("home.exercise.weight.updated", comment: "Weight updated from Home")
        )
        context.insert(workoutLog)
    }
}
