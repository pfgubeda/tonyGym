import SwiftUI
import SwiftData
import Charts

struct BilboView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \BilboCycle.createdAt, order: .reverse) private var bilboCycles: [BilboCycle]
    @Query(sort: \Exercise.title) private var exercises: [Exercise]
    
    @State private var showingCycleCreator = false
    @State private var selectedCycle: BilboCycle?
    @State private var showingInstructions = false
    @State private var selectedExerciseForCycle: Exercise?
    @State private var selectedExerciseForSetup: ExerciseSetupData?
    
    // Helper struct para pasar datos del ejercicio al setup
    struct ExerciseSetupData: Identifiable {
        let id = UUID()
        let exercise: Exercise
        let oneRM: Double
        let formula: OneRMCalculator.Formula
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if bilboCycles.isEmpty {
                    emptyStateView
                } else {
                    contentView
                }
            }
            .navigationTitle(NSLocalizedString("bilbo.title", comment: "BILBO Method"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(NSLocalizedString("bilbo.add.cycle", comment: "Add cycle")) {
                            showingCycleCreator = true
                        }
                        Button(NSLocalizedString("bilbo.instructions", comment: "Instructions")) {
                            showingInstructions = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingCycleCreator) {
                BilboCycleCreatorView(
                    exercises: exercises,
                    onSelect: { exercise in
                        selectedExerciseForCycle = exercise
                        showingCycleCreator = false
                    },
                    onCycleCreated: {
                        showingCycleCreator = false
                    }
                )
            }
            .sheet(item: $selectedCycle) { cycle in
                BilboCycleDetailView(cycle: cycle)
            }
            .sheet(isPresented: $showingInstructions) {
                BilboInstructionsView()
            }
            .sheet(item: $selectedExerciseForCycle) { exercise in
                BilboOneRMDiscoveryView(exercise: exercise) { oneRM, formula in
                    // Una vez que se descubre el 1RM, mostrar la configuración del ciclo
                    selectedExerciseForCycle = nil
                    selectedExerciseForSetup = ExerciseSetupData(exercise: exercise, oneRM: oneRM, formula: formula)
                }
            }
            .sheet(item: $selectedExerciseForSetup) { exerciseData in
                BilboCycleSetupView(
                    exercise: exerciseData.exercise,
                    initialOneRM: exerciseData.oneRM,
                    initialFormula: exerciseData.formula
                ) { cycle in
                    context.insert(cycle)
                    selectedExerciseForSetup = nil
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icono del método BILBO
            VStack(spacing: 16) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                
                VStack(spacing: 8) {
                    Text(NSLocalizedString("bilbo.empty.title", comment: "No BILBO exercises"))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(NSLocalizedString("bilbo.empty.subtitle", comment: "Start with BILBO method"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Descripción del método
            VStack(alignment: .leading, spacing: 16) {
                Text(NSLocalizedString("bilbo.method.description", comment: "Method description"))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 12) {
                    methodStep(
                        number: "1",
                        title: NSLocalizedString("bilbo.step.1.title", comment: "Step 1 title"),
                        description: NSLocalizedString("bilbo.step.1.description", comment: "Step 1 description")
                    )
                    
                    methodStep(
                        number: "2",
                        title: NSLocalizedString("bilbo.step.2.title", comment: "Step 2 title"),
                        description: NSLocalizedString("bilbo.step.2.description", comment: "Step 2 description")
                    )
                    
                    methodStep(
                        number: "3",
                        title: NSLocalizedString("bilbo.step.3.title", comment: "Step 3 title"),
                        description: NSLocalizedString("bilbo.step.3.description", comment: "Step 3 description")
                    )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
            )
            
            // Botón para comenzar
            Button {
                showingCycleCreator = true
            } label: {
                Text(NSLocalizedString("bilbo.start.method", comment: "Start BILBO method"))
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var contentView: some View {
        List {
            ForEach(bilboCycles) { cycle in
                BilboCycleCard(cycle: cycle) {
                    selectedCycle = cycle
                }
            }
            .onDelete(perform: deleteCycle)
        }
        .listStyle(.plain)
    }
    
    private func methodStep(number: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(.blue))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func deleteCycle(offsets: IndexSet) {
        for index in offsets {
            let cycle = bilboCycles[index]
            context.delete(cycle)
        }
    }
}

// MARK: - BilboCycleCard
struct BilboCycleCard: View {
    let cycle: BilboCycle
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(cycle.exercise?.title ?? NSLocalizedString("bilbo.exercise.deleted", comment: "Deleted exercise"))
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        if let exercise = cycle.exercise {
                            Text(exercise.category.displayName)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(exercise.category.color.opacity(0.2)))
                                .foregroundStyle(exercise.category.color)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        if cycle.isCompleted, let finalOneRM = cycle.finalOneRM {
                            Text(formatWeightDisplay(finalOneRM))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.green)
                            Text(NSLocalizedString("bilbo.final.1rm", comment: "Final 1RM"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else if let currentDay = cycle.currentDay {
                            Text(formatWeightDisplay(currentDay.targetWeight))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.blue)
                            Text(NSLocalizedString("bilbo.day", comment: "Day") + " \(currentDay.dayNumber)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(formatWeightDisplay(cycle.initialOneRM))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.blue)
                            Text(NSLocalizedString("bilbo.initial.1rm", comment: "Initial 1RM"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("bilbo.initial.1rm", comment: "Initial 1RM"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(formatWeightDisplay(cycle.initialOneRM))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 2) {
                        Text(NSLocalizedString("bilbo.progress", comment: "Progress"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.0f%%", cycle.progress * 100))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.blue)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(NSLocalizedString("bilbo.days", comment: "Days"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(cycle.days.filter { $0.isCompleted }.count)/\(cycle.numberOfDays)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: cycle.isCompleted ? [.green, .mint] : [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * min(1.0, max(0.0, cycle.progress)), height: 8)
                    }
                }
                .frame(height: 8)
                
                if cycle.isCompleted {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(NSLocalizedString("bilbo.cycle.completed", comment: "Cycle completed"))
                            .font(.caption)
                            .foregroundStyle(.green)
                            .fontWeight(.medium)
                        if let completedAt = cycle.completedAt {
                            Text(" • \(completedAt, style: .date)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct BilboExerciseCard: View {
    let bilboExercise: BilboExercise
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bilboExercise.exercise?.title ?? NSLocalizedString("bilbo.exercise.deleted", comment: "Deleted exercise"))
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        if let exercise = bilboExercise.exercise {
                            Text(exercise.category.displayName)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(exercise.category.color.opacity(0.2)))
                                .foregroundStyle(exercise.category.color)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(String(format: "%.2f kg", bilboExercise.currentWeight))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                        
                        Text(NSLocalizedString("bilbo.current.weight", comment: "Current weight"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("bilbo.one.rm", comment: "1RM"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.2f kg", bilboExercise.oneRepMax))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 2) {
                        Text(NSLocalizedString("bilbo.percentage", comment: "Percentage"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.0f%%", bilboExercise.currentPercentage))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(bilboExercise.isInCorrectRange ? .green : .orange)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(NSLocalizedString("bilbo.target.reps", comment: "Target reps"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("15-50")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                
                if let lastSession = bilboExercise.lastSessionDate {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundStyle(.secondary)
                        Text(NSLocalizedString("bilbo.last.session", comment: "Last session"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(lastSession, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if bilboExercise.shouldProgress() {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundStyle(.green)
                        Text(NSLocalizedString("bilbo.ready.progress", comment: "Ready to progress"))
                            .font(.caption)
                            .foregroundStyle(.green)
                            .fontWeight(.medium)
                    }
                }
                
                if bilboExercise.isOneRMAutoCalculated {
                    HStack {
                        Image(systemName: "calculator")
                            .foregroundStyle(.blue)
                        Text(NSLocalizedString("bilbo.auto.calculated", comment: "Auto calculated 1RM"))
                            .font(.caption)
                            .foregroundStyle(.blue)
                            .fontWeight(.medium)
                    }
                }
                
                // Progress Bar
                if !bilboExercise.sessions.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(NSLocalizedString("bilbo.progress", comment: "Progress"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(bilboExercise.sessions.count) \(NSLocalizedString("bilbo.sessions", comment: "sessions"))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .cyan],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * min(1.0, max(0.0, bilboExercise.progressPercentage() / 100)), height: 8)
                            }
                        }
                        .frame(height: 8)
                        
                        Text(String(format: "%.0f%%", bilboExercise.progressPercentage()))
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct BilboExercisePickerView: View {
    let exercises: [Exercise]
    let onSelect: (Exercise) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutLog.date, order: .reverse) private var workoutLogs: [WorkoutLog]
    @State private var selectedFilter: ExerciseCategory? = nil
    @State private var showingOneRMCalculator = false
    @State private var selectedExercise: Exercise?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                categoryFilterBar
                List(filteredExercises()) { exercise in
                    HStack {
                        Button {
                            onSelect(exercise)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.title)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    
                                    Text(exercise.details)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(exercise.category.displayName)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Capsule().fill(exercise.category.color.opacity(0.2)))
                                        .foregroundStyle(exercise.category.color)
                                    
                                    Text(String(format: "%.1f kg", exercise.defaultWeightKg))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        
                        // Botón para calcular 1RM automáticamente
                        if hasWorkoutHistory(for: exercise) {
                            Button {
                                selectedExercise = exercise
                                showingOneRMCalculator = true
                            } label: {
                                Image(systemName: "calculator")
                                    .foregroundStyle(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("bilbo.select.exercise", comment: "Select exercise for BILBO"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.cancel", comment: "Cancel")) { dismiss() }
                }
            }
            .sheet(isPresented: $showingOneRMCalculator) {
                if let exercise = selectedExercise {
                    OneRMCalculatorView(exercise: exercise) { calculatedOneRM, formula in
                        // Asegurar que el 1RM esté redondeado a discos típicos
                        let roundedOneRM = OneRMCalculator.roundToTypicalPlate(calculatedOneRM)
                        addBilboExerciseWithCalculatedOneRM(exercise, oneRM: roundedOneRM)
                        dismiss()
                    }
                }
            }
        }
    }
    
    // Verifica si un ejercicio tiene historial de entrenamientos
    private func hasWorkoutHistory(for exercise: Exercise) -> Bool {
        return workoutLogs.contains { $0.exercise?.persistentModelID == exercise.persistentModelID }
    }
    
    // Añade un ejercicio BILBO con 1RM calculado automáticamente
    private func addBilboExerciseWithCalculatedOneRM(_ exercise: Exercise, oneRM: Double) {
        let bilboExercise = BilboExercise(exercise: exercise, oneRepMax: oneRM, isAutoCalculated: true)
        context.insert(bilboExercise)
    }
    
    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: NSLocalizedString("exercise.filter.all", comment: "All filter"), isSelected: selectedFilter == nil) { selectedFilter = nil }
                ForEach(ExerciseCategory.allCases) { cat in
                    filterChip(label: cat.displayName, category: cat, isSelected: selectedFilter == cat) { selectedFilter = cat }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func filterChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.12)))
                .overlay(Capsule().stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
    
    private func filterChip(label: String, category: ExerciseCategory, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(isSelected ? category.color.opacity(0.3) : category.color.opacity(0.1)))
                .overlay(Capsule().stroke(isSelected ? category.color : category.color.opacity(0.5), lineWidth: 1))
                .foregroundStyle(isSelected ? category.color : category.color.opacity(0.8))
        }
        .buttonStyle(.plain)
    }
    
    private func filteredExercises() -> [Exercise] {
        guard let selectedFilter else { return exercises }
        return exercises.filter { $0.category == selectedFilter }
    }
}

struct BilboSessionLogView: View {
    let bilboExercise: BilboExercise
    let onSave: (() -> Void)?
    @Environment(\.modelContext) private var context
    
    @State private var weightUsed: Double
    @State private var repsCompleted: Int = 15
    @State private var notes: String = ""
    @State private var showingOneRMEditor = false
    @State private var newOneRM: Double
    @State private var showingHistory = false
    
    init(bilboExercise: BilboExercise, onSave: (() -> Void)? = nil) {
        self.bilboExercise = bilboExercise
        self.onSave = onSave
        self._weightUsed = State(initialValue: OneRMCalculator.roundToIncrement(bilboExercise.currentWeight))
        self._newOneRM = State(initialValue: bilboExercise.oneRepMax)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(NSLocalizedString("bilbo.exercise", comment: "Exercise"))
                        Spacer()
                        Text(bilboExercise.exercise?.title ?? NSLocalizedString("bilbo.exercise.deleted", comment: "Deleted exercise"))
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text(NSLocalizedString("bilbo.current.1rm", comment: "Current 1RM"))
                        Spacer()
                        Button(String(format: "%.1f kg", bilboExercise.oneRepMax)) {
                            showingOneRMEditor = true
                        }
                        .foregroundStyle(.blue)
                    }
                }
                
                Section(NSLocalizedString("bilbo.session.data", comment: "Session data")) {
                    HStack {
                        Text(NSLocalizedString("bilbo.weight.used", comment: "Weight used"))
                        Spacer()
                        TextField("kg", value: $weightUsed, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onSubmit {
                                weightUsed = OneRMCalculator.roundToTypicalPlate(weightUsed)
                            }
                    }
                    WeightAdjustmentButtons(weight: $weightUsed)
                    
                    HStack {
                        Text(NSLocalizedString("bilbo.reps.completed", comment: "Reps completed"))
                        Spacer()
                        Stepper("\(repsCompleted)", value: $repsCompleted, in: 1...100)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("bilbo.notes", comment: "Notes"))
                        TextField(NSLocalizedString("bilbo.notes.placeholder", comment: "Session notes"), text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }
                
                Section(NSLocalizedString("bilbo.method.reminder", comment: "Method reminder")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("bilbo.reminder.title", comment: "Remember"))
                            .font(.headline)
                        
                        Text(NSLocalizedString("bilbo.reminder.text", comment: "Reminder text"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if repsCompleted > 15 {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.circle")
                                    .foregroundStyle(.green)
                                Text(String(format: NSLocalizedString("bilbo.reminder.next.session", comment: "Next session suggestion"), String(format: "%.1f", bilboExercise.suggestedNextWeight())))
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("bilbo.log.session", comment: "Log session"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !bilboExercise.sessions.isEmpty {
                        Button {
                            showingHistory = true
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("bilbo.save.session", comment: "Save session")) {
                        saveSession()
                    }
                }
            }
            .sheet(isPresented: $showingOneRMEditor) {
                OneRMEditorView(bilboExercise: bilboExercise, newOneRM: $newOneRM)
            }
            .sheet(isPresented: $showingHistory) {
                BilboSessionHistoryView(bilboExercise: bilboExercise)
            }
        }
    }
    
    private func saveSession() {
        // Crear nueva sesión
        let session = BilboSession(
            bilboExercise: bilboExercise,
            weightUsed: weightUsed,
            repsCompleted: repsCompleted,
            notes: notes
        )
        context.insert(session)
        
        // Actualizar el ejercicio BILBO
        bilboExercise.lastSessionDate = .now
        bilboExercise.lastRepsCompleted = repsCompleted
        bilboExercise.currentWeight = weightUsed
        bilboExercise.updatedAt = .now
        
        // Si completó más de 15 reps, sugerir progresión
        if repsCompleted > 15 {
            bilboExercise.currentWeight = bilboExercise.suggestedNextWeight()
        }
        
        // Navigate back to stats view
        onSave?()
    }
}

struct OneRMEditorView: View {
    let bilboExercise: BilboExercise
    @Binding var newOneRM: Double
    @Environment(\.dismiss) private var dismiss
    @State private var showingManualTest = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(NSLocalizedString("bilbo.edit.1rm", comment: "Edit 1RM")) {
                    HStack {
                        Text(NSLocalizedString("bilbo.current.1rm", comment: "Current 1RM"))
                        Spacer()
                        Text(String(format: "%.2f kg", bilboExercise.oneRepMax))
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text(NSLocalizedString("bilbo.new.1rm", comment: "New 1RM"))
                        Spacer()
                        TextField("kg", value: $newOneRM, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onSubmit {
                                newOneRM = OneRMCalculator.roundToTypicalPlate(newOneRM)
                            }
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("bilbo.new.weight", comment: "New weight"))
                            .font(.headline)
                        Text(String(format: "%.2f kg", newOneRM * 0.5))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                        Text(NSLocalizedString("bilbo.new.weight.description", comment: "New weight description"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("bilbo.edit.1rm.title", comment: "Edit 1RM"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.cancel", comment: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("common.save", comment: "Save")) {
                        bilboExercise.oneRepMax = newOneRM
                        bilboExercise.currentWeight = newOneRM * 0.5
                        bilboExercise.updatedAt = .now
                        dismiss()
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button(NSLocalizedString("bilbo.discover.1rm", comment: "Discover my 1RM")) {
                        showingManualTest = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingManualTest) {
            ManualOneRMTestView { calculated, formula in
                newOneRM = calculated
            }
        }
    }
}

struct BilboInstructionsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 50))
                            .foregroundStyle(.blue)
                        
                        Text(NSLocalizedString("bilbo.method.title", comment: "BILBO Method"))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(NSLocalizedString("bilbo.method.subtitle", comment: "Method subtitle"))
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Descripción del método
                    instructionSection(
                        title: NSLocalizedString("bilbo.instructions.what.title", comment: "What is BILBO"),
                        content: NSLocalizedString("bilbo.instructions.what.content", comment: "What is BILBO content")
                    )
                    
                    // Cómo funciona
                    instructionSection(
                        title: NSLocalizedString("bilbo.instructions.how.title", comment: "How it works"),
                        content: NSLocalizedString("bilbo.instructions.how.content", comment: "How it works content")
                    )
                    
                    // Pasos
                    instructionSection(
                        title: NSLocalizedString("bilbo.instructions.steps.title", comment: "Steps"),
                        content: NSLocalizedString("bilbo.instructions.steps.content", comment: "Steps content")
                    )
                    
                    // Beneficios
                    instructionSection(
                        title: NSLocalizedString("bilbo.instructions.benefits.title", comment: "Benefits"),
                        content: NSLocalizedString("bilbo.instructions.benefits.content", comment: "Benefits content")
                    )
                    
                    // Consejos
                    instructionSection(
                        title: NSLocalizedString("bilbo.instructions.tips.title", comment: "Tips"),
                        content: NSLocalizedString("bilbo.instructions.tips.content", comment: "Tips content")
                    )
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("bilbo.instructions.title", comment: "Instructions"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.close", comment: "Close")) { dismiss() }
                }
            }
        }
    }
    
    private func instructionSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(content)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct OneRMCalculatorView: View {
    let exercise: Exercise
    let onCalculate: (Double, OneRMCalculator.Formula) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutLog.date, order: .reverse) private var workoutLogs: [WorkoutLog]
    
    @State private var selectedFormula: OneRMCalculator.Formula = .epley
    @State private var calculatedOneRM: Double = 0
    @State private var showingFormulaInfo = false
    @State private var showingManualTest = false
    
    private var exerciseWorkoutLogs: [WorkoutLog] {
        workoutLogs.filter { $0.exercise?.persistentModelID == exercise.persistentModelID }
    }
    
    private var workoutStats: (maxWeight: Double, maxReps: Int, totalSessions: Int, lastWorkout: Date?) {
        let workoutData = exerciseWorkoutLogs.compactMap { log -> OneRMCalculator.WorkoutData? in
            guard log.weightUsed > 0, log.reps > 0 else { return nil }
            return OneRMCalculator.WorkoutData(
                weight: log.weightUsed,
                reps: log.reps,
                date: log.date
            )
        }
        return OneRMCalculator.getWorkoutStats(from: workoutData)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text(exercise.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(NSLocalizedString("bilbo.calculator.subtitle", comment: "Calculate 1RM from workout history"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // Estadísticas del historial
                    if !exerciseWorkoutLogs.isEmpty {
                        workoutHistoryCard
                    } else {
                        noHistoryCard
                    }
                    
                    // Selector de fórmula
                    formulaSelector
                    
                    // Resultado del cálculo
                    if calculatedOneRM > 0 {
                        calculationResult
                    }
                    
                    // Información sobre fórmulas
                    formulaInfo
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("bilbo.calculator.title", comment: "1RM Calculator"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.cancel", comment: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("bilbo.calculator.use", comment: "Use this 1RM")) {
                        // Asegurar que el 1RM esté redondeado a discos típicos
                        let roundedOneRM = OneRMCalculator.roundToTypicalPlate(calculatedOneRM)
                        onCalculate(roundedOneRM, selectedFormula)
                    }
                    .disabled(calculatedOneRM <= 0)
                }
            }
            .onAppear {
                calculateOneRM()
            }
            .onChange(of: selectedFormula) { _, _ in
                calculateOneRM()
            }
            .sheet(isPresented: $showingManualTest) {
                ManualOneRMTestView { calculated, formula in
                    onCalculate(calculated, formula)
                }
            }
        }
    }
    
    private var workoutHistoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("bilbo.calculator.history", comment: "Workout History"))
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("bilbo.calculator.total.sessions", comment: "Total sessions"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(workoutStats.totalSessions)")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 4) {
                    Text(NSLocalizedString("bilbo.calculator.max.weight", comment: "Max weight"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f kg", workoutStats.maxWeight))
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(NSLocalizedString("bilbo.calculator.max.reps", comment: "Max reps"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(workoutStats.maxReps)")
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }
            
            if let lastWorkout = workoutStats.lastWorkout {
                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                    Text(NSLocalizedString("bilbo.calculator.last.workout", comment: "Last workout"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(lastWorkout, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private var noHistoryCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            
            Text(NSLocalizedString("bilbo.calculator.no.history", comment: "No workout history"))
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(NSLocalizedString("bilbo.calculator.no.history.message", comment: "No history message"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingManualTest = true
            } label: {
                Text(NSLocalizedString("bilbo.calculator.enter.manual", comment: "Enter manually"))
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
    }
    
    private var formulaSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("bilbo.calculator.formula", comment: "Calculation Formula"))
                .font(.headline)
                .fontWeight(.semibold)
            
            Picker(NSLocalizedString("bilbo.calculator.formula", comment: "Formula"), selection: $selectedFormula) {
                ForEach(OneRMCalculator.Formula.allCases, id: \.self) { formula in
                    Text(formula.displayName).tag(formula)
                }
            }
            .pickerStyle(.menu)
            
            Text(selectedFormula.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private var calculationResult: some View {
        VStack(spacing: 16) {
            Text(NSLocalizedString("bilbo.calculator.result", comment: "Calculated 1RM"))
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                Text(formatWeightDisplay(calculatedOneRM))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
                
                Text(NSLocalizedString("bilbo.calculator.bilbo.weight", comment: "BILBO training weight"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(formatWeightDisplay(OneRMCalculator.calculateBilboWeight(oneRM: calculatedOneRM)))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
            }
            
            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(.blue)
                Text(NSLocalizedString("bilbo.calculator.bilbo.explanation", comment: "BILBO explanation"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
    }
    
    private var formulaInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(NSLocalizedString("bilbo.calculator.formula.info", comment: "Formula Information"))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    showingFormulaInfo.toggle()
                } label: {
                    Image(systemName: showingFormulaInfo ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.blue)
                }
            }
            
            if showingFormulaInfo {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(OneRMCalculator.Formula.allCases, id: \.self) { formula in
                        HStack(alignment: .top, spacing: 8) {
                            Text(formula.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(formula == selectedFormula ? .blue : .primary)
                            
                            Spacer()
                            
                            Text(formula.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private func calculateOneRM() {
        guard !exerciseWorkoutLogs.isEmpty else {
            calculatedOneRM = 0
            return
        }
        
        let workoutData = exerciseWorkoutLogs.compactMap { log -> OneRMCalculator.WorkoutData? in
            guard log.weightUsed > 0, log.reps > 0 else { return nil }
            return OneRMCalculator.WorkoutData(
                weight: log.weightUsed,
                reps: log.reps,
                date: log.date
            )
        }
        
        guard !workoutData.isEmpty else {
            calculatedOneRM = 0
            return
        }
        
        let rawOneRM = OneRMCalculator.findRecentReliableOneRM(from: workoutData, formula: selectedFormula)
        // Redondear a discos típicos del gimnasio
        calculatedOneRM = OneRMCalculator.roundToTypicalPlate(rawOneRM)
    }
}

// MARK: - Bilbo Session History View
struct BilboSessionHistoryView: View {
    let bilboExercise: BilboExercise
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    private var sortedSessions: [BilboSession] {
        bilboExercise.sessions.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if sortedSessions.isEmpty {
                    ContentUnavailableView(
                        NSLocalizedString("bilbo.history.empty.title", comment: "No sessions yet"),
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text(NSLocalizedString("bilbo.history.empty.description", comment: "Start logging sessions to see your history here"))
                    )
                } else {
                    ForEach(sortedSessions) { session in
                        SessionHistoryRow(session: session)
                    }
                    .onDelete(perform: deleteSessions)
                }
            }
            .navigationTitle(bilboExercise.exercise?.title ?? NSLocalizedString("bilbo.history.title", comment: "Session History"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.done", comment: "Done")) { dismiss() }
                }
            }
        }
    }
    
    private func deleteSessions(offsets: IndexSet) {
        for index in offsets {
            let session = sortedSessions[index]
            context.delete(session)
        }
    }
}

struct SessionHistoryRow: View {
    let session: BilboSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.date, style: .date)
                    .font(.headline)
                Spacer()
                Text(session.date, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(NSLocalizedString("bilbo.weight.used", comment: "Weight used"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f kg", session.weightUsed))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(NSLocalizedString("bilbo.reps.completed", comment: "Reps completed"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(session.repsCompleted)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(NSLocalizedString("bilbo.volume", comment: "Volume"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.0f kg", session.weightUsed * Double(session.repsCompleted)))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                }
            }
            
            if !session.notes.isEmpty {
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "note.text")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(session.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Bilbo Exercise Detail View (main container)
struct BilboExerciseDetailView: View {
    let bilboExercise: BilboExercise
    @Environment(\.dismiss) private var dismiss
    @State private var showingSessionLog = false
    
    var body: some View {
        NavigationStack {
            BilboStatsView(bilboExercise: bilboExercise, onLogSession: {
                showingSessionLog = true
            })
            .navigationDestination(isPresented: $showingSessionLog) {
                BilboSessionLogViewContainer(bilboExercise: bilboExercise, onSave: {
                    showingSessionLog = false
                })
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.done", comment: "Done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Container for session log that handles dismissal properly
struct BilboSessionLogViewContainer: View {
    let bilboExercise: BilboExercise
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        BilboSessionLogView(bilboExercise: bilboExercise, onSave: onSave)
    }
}

// MARK: - Bilbo Stats View
struct BilboStatsView: View {
    let bilboExercise: BilboExercise
    var onLogSession: (() -> Void)?
    
    @State private var showingHistory = false
    
    private var stats: (totalSessions: Int, avgWeight: Double, maxWeight: Double, avgReps: Double, maxReps: Int, totalVolume: Double, sessionsByWeek: [Date: Int]) {
        bilboExercise.getBilboStats()
    }
    
    private var improvement: (weightIncrease: Double, repsIncrease: Int, volumeIncrease: Double, percentageImprovement: Double) {
        bilboExercise.getImprovement()
    }
    
    private var progressData: (weightData: [(Date, Double)], repsData: [(Date, Int)], volumeData: [(Date, Double)]) {
        bilboExercise.getProgressData()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text(bilboExercise.exercise?.title ?? NSLocalizedString("bilbo.exercise.deleted", comment: "Deleted exercise"))
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(NSLocalizedString("bilbo.stats.subtitle", comment: "Performance Statistics"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)
                    
                    // Log Session Button
                    if let onLogSession = onLogSession {
                        Button(action: onLogSession) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                Text(NSLocalizedString("bilbo.log.session", comment: "Log session"))
                                    .font(.headline)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    
                    // Summary Stats Cards
                    summaryStatsSection
                    
                    // Improvement Card
                    if !bilboExercise.sessions.isEmpty {
                        improvementCard
                    }
                    
                    // Charts
                    if !bilboExercise.sessions.isEmpty {
                        weightProgressChart
                        repsProgressChart
                        volumeProgressChart
                    }
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("bilbo.stats.title", comment: "Statistics"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if !bilboExercise.sessions.isEmpty {
                        Button {
                            showingHistory = true
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingHistory) {
                BilboSessionHistoryView(bilboExercise: bilboExercise)
            }
        }
    }
    
    private var summaryStatsSection: some View {
        VStack(spacing: 16) {
            Text(NSLocalizedString("bilbo.stats.summary", comment: "Summary"))
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: NSLocalizedString("bilbo.stats.total.sessions", comment: "Total Sessions"),
                    value: "\(stats.totalSessions)",
                    icon: "calendar",
                    color: .blue
                )
                
                StatCard(
                    title: NSLocalizedString("bilbo.stats.avg.weight", comment: "Avg Weight"),
                    value: String(format: "%.1f kg", stats.avgWeight),
                    icon: "scalemass",
                    color: .green
                )
                
                StatCard(
                    title: NSLocalizedString("bilbo.stats.max.weight", comment: "Max Weight"),
                    value: String(format: "%.1f kg", stats.maxWeight),
                    icon: "arrow.up.circle.fill",
                    color: .red
                )
                
                StatCard(
                    title: NSLocalizedString("bilbo.stats.total.volume", comment: "Total Volume"),
                    value: String(format: "%.0f kg", stats.totalVolume),
                    icon: "chart.bar.fill",
                    color: .purple
                )
            }
        }
    }
    
    private var improvementCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("bilbo.stats.improvement", comment: "Improvement"))
                .font(.headline)
            
            HStack(spacing: 20) {
                ImprovementItem(
                    icon: "scalemass.fill",
                    title: NSLocalizedString("bilbo.stats.weight.increase", comment: "Weight"),
                    value: String(format: "%+.1f kg", improvement.weightIncrease),
                    color: .blue
                )
                
                ImprovementItem(
                    icon: "arrow.up.circle.fill",
                    title: NSLocalizedString("bilbo.stats.reps.increase", comment: "Reps"),
                    value: String(format: "%+d", improvement.repsIncrease),
                    color: .green
                )
                
                ImprovementItem(
                    icon: "chart.line.uptrend.xyaxis",
                    title: NSLocalizedString("bilbo.stats.volume", comment: "Volume"),
                    value: String(format: "%+.0f kg", improvement.volumeIncrease),
                    color: .purple
                )
            }
            
            if improvement.percentageImprovement > 0 {
                HStack {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .foregroundStyle(.green)
                    Text(String(format: NSLocalizedString("bilbo.stats.percentage.improvement", comment: "%.1f%% total improvement"), improvement.percentageImprovement))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private var weightProgressChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("bilbo.stats.weight.progression", comment: "Weight Progression"))
                .font(.headline)
            
            if progressData.weightData.isEmpty {
                Text(NSLocalizedString("bilbo.stats.no.data", comment: "No data available"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ChartView(data: progressData.weightData.map { ($0.0.timeIntervalSince1970, $0.1) }, color: .blue)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    private var repsProgressChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("bilbo.stats.reps.progression", comment: "Reps Progression"))
                .font(.headline)
            
            if progressData.repsData.isEmpty {
                Text(NSLocalizedString("bilbo.stats.no.data", comment: "No data available"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ChartView(data: progressData.repsData.map { ($0.0.timeIntervalSince1970, Double($0.1)) }, color: .green)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    private var volumeProgressChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("bilbo.stats.volume.progression", comment: "Volume Progression"))
                .font(.headline)
            
            if progressData.volumeData.isEmpty {
                Text(NSLocalizedString("bilbo.stats.no.data", comment: "No data available"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ChartView(data: progressData.volumeData.map { ($0.0.timeIntervalSince1970, $0.1) }, color: .purple)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct ImprovementItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// Simple Line Chart View
struct ChartView: View {
    let data: [(Double, Double)] // (time, value)
    let color: Color
    
    private var minValue: Double {
        data.map { $0.1 }.min() ?? 0
    }
    
    private var maxValue: Double {
        data.map { $0.1 }.max() ?? 1
    }
    
    private var minTime: Double {
        data.map { $0.0 }.min() ?? 0
    }
    
    private var maxTime: Double {
        data.map { $0.0 }.max() ?? 1
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background grid
                Path { path in
                    for i in 0...4 {
                        let y = geometry.size.height * CGFloat(i) / 4
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                }
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                
                // Chart line
                if data.count > 1 {
                    Path { path in
                        let range = maxValue - minValue
                        let timeRange = maxTime - minTime
                        
                        for (index, point) in data.enumerated() {
                            let x = timeRange > 0 ? CGFloat((point.0 - minTime) / timeRange) * geometry.size.width : CGFloat(index) / CGFloat(data.count - 1) * geometry.size.width
                            let y = range > 0 ? geometry.size.height - (CGFloat((point.1 - minValue) / range) * geometry.size.height) : geometry.size.height / 2
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    
                    // Data points
                    ForEach(Array(data.enumerated()), id: \.offset) { index, point in
                        let range = maxValue - minValue
                        let timeRange = maxTime - minTime
                        let x = timeRange > 0 ? CGFloat((point.0 - minTime) / timeRange) * geometry.size.width : CGFloat(index) / CGFloat(data.count - 1) * geometry.size.width
                        let y = range > 0 ? geometry.size.height - (CGFloat((point.1 - minValue) / range) * geometry.size.height) : geometry.size.height / 2
                        
                        Circle()
                            .fill(color)
                            .frame(width: 8, height: 8)
                            .position(x: x, y: y)
                    }
                } else if data.count == 1 {
                    let point = data[0]
                    let range = maxValue - minValue
                    let x = geometry.size.width / 2
                    let y = range > 0 ? geometry.size.height - (CGFloat((point.1 - minValue) / range) * geometry.size.height) : geometry.size.height / 2
                    
                    Circle()
                        .fill(color)
                        .frame(width: 12, height: 12)
                        .position(x: x, y: y)
                }
                
                // Y-axis labels
                VStack {
                    Text(String(format: "%.1f", maxValue))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.1f", minValue))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 4)
            }
        }
    }
}

// MARK: - BilboCycleCreatorView
struct BilboCycleCreatorView: View {
    let exercises: [Exercise]
    let onSelect: (Exercise) -> Void
    let onCycleCreated: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutLog.date, order: .reverse) private var workoutLogs: [WorkoutLog]
    @State private var selectedFilter: ExerciseCategory? = nil
    @State private var showingOneRMCalculator = false
    @State private var selectedExercise: Exercise?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                categoryFilterBar
                List(filteredExercises()) { exercise in
                    HStack {
                        Button {
                            onSelect(exercise)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.title)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    
                                    Text(exercise.details)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(exercise.category.displayName)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Capsule().fill(exercise.category.color.opacity(0.2)))
                                        .foregroundStyle(exercise.category.color)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        
                        // Botón para calcular 1RM automáticamente
                        if hasWorkoutHistory(for: exercise) {
                            Button {
                                selectedExercise = exercise
                                showingOneRMCalculator = true
                            } label: {
                                Image(systemName: "calculator")
                                    .foregroundStyle(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("bilbo.select.exercise", comment: "Select exercise for BILBO"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.cancel", comment: "Cancel")) { dismiss() }
                }
            }
            .sheet(isPresented: $showingOneRMCalculator) {
                if let exercise = selectedExercise {
                    OneRMCalculatorView(exercise: exercise) { calculatedOneRM, formula in
                        // Cuando se calcula el 1RM, crear el ciclo directamente
                        // Asegurar que el 1RM esté redondeado a discos típicos
                        let roundedOneRM = OneRMCalculator.roundToTypicalPlate(calculatedOneRM)
                        let cycle = BilboCycle(
                            exercise: exercise,
                            initialOneRM: roundedOneRM,
                            numberOfDays: 30,
                            increment: 2.5, // Incremento por defecto: 2.5 kg (disco típico)
                            notes: ""
                        )
                        cycle.oneRMFormula = formula.rawValue
                        context.insert(cycle)
                        selectedExercise = nil
                        showingOneRMCalculator = false
                        onCycleCreated()
                        dismiss()
                    }
                }
            }
        }
    }
    
    // Verifica si un ejercicio tiene historial de entrenamientos
    private func hasWorkoutHistory(for exercise: Exercise) -> Bool {
        return workoutLogs.contains { $0.exercise?.persistentModelID == exercise.persistentModelID }
    }
    
    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: NSLocalizedString("exercise.filter.all", comment: "All filter"), isSelected: selectedFilter == nil) { selectedFilter = nil }
                ForEach(ExerciseCategory.allCases) { cat in
                    filterChip(label: cat.displayName, category: cat, isSelected: selectedFilter == cat) { selectedFilter = cat }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func filterChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.12)))
                .overlay(Capsule().stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
    
    private func filterChip(label: String, category: ExerciseCategory, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(isSelected ? category.color.opacity(0.3) : category.color.opacity(0.1)))
                .overlay(Capsule().stroke(isSelected ? category.color : category.color.opacity(0.5), lineWidth: 1))
                .foregroundStyle(isSelected ? category.color : category.color.opacity(0.8))
        }
        .buttonStyle(.plain)
    }
    
    private func filteredExercises() -> [Exercise] {
        guard let selectedFilter else { return exercises }
        return exercises.filter { $0.category == selectedFilter }
    }
}

// MARK: - BilboOneRMDiscoveryView
struct BilboOneRMDiscoveryView: View {
    let exercise: Exercise
    let onComplete: (Double, OneRMCalculator.Formula) -> Void
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutLog.date, order: .reverse) private var workoutLogs: [WorkoutLog]
    
    @State private var showingOneRMCalculator = false
    @State private var showingManualTest = false
    @State private var showingManualEntry = false
    @State private var manualOneRM: Double = 0
    
    private var exerciseWorkoutLogs: [WorkoutLog] {
        workoutLogs.filter { $0.exercise?.persistentModelID == exercise.persistentModelID }
    }
    
    private var hasWorkoutHistory: Bool {
        !exerciseWorkoutLogs.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 50))
                            .foregroundStyle(.blue)
                        
                        Text(exercise.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(NSLocalizedString("bilbo.discover.1rm.subtitle", comment: "Discover your 1RM to start"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Opciones para descubrir el 1RM
                    VStack(spacing: 16) {
                        // Opción 1: Calcular desde historial
                        if hasWorkoutHistory {
                            discoveryOptionCard(
                                icon: "chart.line.uptrend.xyaxis",
                                title: NSLocalizedString("bilbo.discover.from.history", comment: "Calculate from history"),
                                description: NSLocalizedString("bilbo.discover.from.history.description", comment: "Use your workout history to estimate 1RM"),
                                color: .blue
                            ) {
                                showingOneRMCalculator = true
                            }
                        }
                        
                        // Opción 2: Test manual
                        discoveryOptionCard(
                            icon: "dumbbell.fill",
                            title: NSLocalizedString("bilbo.discover.manual.test", comment: "Manual test"),
                            description: NSLocalizedString("bilbo.discover.manual.test.description", comment: "Enter weight and reps to calculate 1RM"),
                            color: .green
                        ) {
                            showingManualTest = true
                        }
                        
                        // Opción 3: Introducir manualmente
                        discoveryOptionCard(
                            icon: "pencil",
                            title: NSLocalizedString("bilbo.discover.manual.entry", comment: "Enter manually"),
                            description: NSLocalizedString("bilbo.discover.manual.entry.description", comment: "If you already know your 1RM"),
                            color: .orange
                        ) {
                            showingManualEntry = true
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("bilbo.discover.1rm.title", comment: "Discover Your 1RM"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.cancel", comment: "Cancel")) { dismiss() }
                }
            }
            .sheet(isPresented: $showingOneRMCalculator) {
                OneRMCalculatorView(exercise: exercise) { calculatedOneRM, formula in
                    // Asegurar que el 1RM esté redondeado a discos típicos
                    let roundedOneRM = OneRMCalculator.roundToTypicalPlate(calculatedOneRM)
                    onComplete(roundedOneRM, formula)
                    dismiss()
                }
            }
            .sheet(isPresented: $showingManualTest) {
                ManualOneRMTestView { calculatedOneRM, formula in
                    // Asegurar que el 1RM esté redondeado a discos típicos
                    let roundedOneRM = OneRMCalculator.roundToTypicalPlate(calculatedOneRM)
                    onComplete(roundedOneRM, formula)
                    dismiss()
                }
            }
            .sheet(isPresented: $showingManualEntry) {
                ManualOneRMEntryView(exercise: exercise) { oneRM in
                    onComplete(oneRM, .epley)
                    dismiss()
                }
            }
        }
    }
    
    private func discoveryOptionCard(
        icon: String,
        title: String,
        description: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 50, height: 50)
                    .background(Circle().fill(color.opacity(0.1)))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ManualOneRMEntryView
struct ManualOneRMEntryView: View {
    let exercise: Exercise
    let onComplete: (Double) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var oneRM: Double = 0
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(exercise.title)
                            .font(.headline)
                        Spacer()
                    }
                }
                
                Section(NSLocalizedString("bilbo.enter.1rm", comment: "Enter 1RM")) {
                    HStack {
                        Text(NSLocalizedString("bilbo.initial.1rm", comment: "Initial 1RM"))
                        Spacer()
                        TextField("kg", value: $oneRM, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onSubmit {
                                oneRM = OneRMCalculator.roundToTypicalPlate(oneRM)
                            }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("bilbo.enter.1rm.title", comment: "Enter 1RM"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.cancel", comment: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("common.continue", comment: "Continue")) {
                        if oneRM > 0 {
                            onComplete(oneRM)
                        }
                    }
                    .disabled(oneRM <= 0)
                }
            }
        }
    }
}

// MARK: - BilboCycleSetupView
struct BilboCycleSetupView: View {
    let exercise: Exercise
    let initialOneRM: Double?
    let initialFormula: OneRMCalculator.Formula?
    let onComplete: (BilboCycle) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @State private var oneRM: Double = 0
    @State private var numberOfDays: Int = 30
    @State private var increment: Double = 2.5
    @State private var notes: String = ""
    @State private var selectedFormula: OneRMCalculator.Formula = .epley
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(NSLocalizedString("bilbo.exercise", comment: "Exercise"))
                        Spacer()
                        Text(exercise.title)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section(NSLocalizedString("bilbo.cycle.settings", comment: "Cycle Settings")) {
                    HStack {
                        Text(NSLocalizedString("bilbo.initial.1rm", comment: "Initial 1RM"))
                        Spacer()
                        TextField("kg", value: $oneRM, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text(NSLocalizedString("bilbo.number.of.days", comment: "Number of days"))
                        Spacer()
                        Stepper("\(numberOfDays)", value: $numberOfDays, in: 1...100)
                    }
                    
                    HStack {
                        Text(NSLocalizedString("bilbo.increment", comment: "Increment per day"))
                        Spacer()
                        TextField("kg", value: $increment, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onSubmit {
                                // Redondear a valores típicos de incremento (1.25, 2.5, 5)
                                if increment > 0 {
                                    increment = OneRMCalculator.roundToTypicalPlate(increment)
                                }
                            }
                    }
                    
                    // Selector rápido de incrementos comunes
                    HStack {
                        Text(NSLocalizedString("bilbo.quick.increment", comment: "Quick select"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        ForEach([1.25, 2.5, 5.0], id: \.self) { value in
                            Button(value.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", value) : String(format: "%.2f", value)) {
                                increment = value
                            }
                            .font(.caption)
                            .buttonStyle(.bordered)
                            .tint(increment == value ? .blue : .secondary)
                        }
                    }
                }
                
                Section(NSLocalizedString("bilbo.notes", comment: "Notes")) {
                    TextField(NSLocalizedString("bilbo.notes.placeholder", comment: "Optional notes"), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("bilbo.cycle.preview", comment: "Cycle Preview"))
                            .font(.headline)
                        
                        if oneRM > 0 {
                            VStack(alignment: .leading, spacing: 4) {
                                let day1Weight = OneRMCalculator.roundToTypicalPlate(oneRM)
                                let lastDayWeight = OneRMCalculator.roundToTypicalPlate(oneRM + (Double(numberOfDays - 1) * increment))
                                Text(NSLocalizedString("bilbo.day", comment: "Day") + " 1: \(formatWeightDisplay(day1Weight))")
                                Text(NSLocalizedString("bilbo.day", comment: "Day") + " \(numberOfDays): \(formatWeightDisplay(lastDayWeight))")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("bilbo.create.cycle", comment: "Create Cycle"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.cancel", comment: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("common.create", comment: "Create")) {
                        createCycle()
                    }
                    .disabled(oneRM <= 0 || numberOfDays <= 0 || increment <= 0)
                }
            }
            .onAppear {
                if let initialOneRM = initialOneRM {
                    oneRM = initialOneRM
                } else {
                    oneRM = exercise.defaultWeightKg * 2
                }
                if let initialFormula = initialFormula {
                    selectedFormula = initialFormula
                }
            }
        }
    }
    
    private func createCycle() {
        let cycle = BilboCycle(
            exercise: exercise,
            initialOneRM: oneRM,
            numberOfDays: numberOfDays,
            increment: increment,
            notes: notes
        )
        cycle.oneRMFormula = selectedFormula.rawValue
        onComplete(cycle)
        dismiss()
    }
}

// MARK: - BilboCycleDetailView
struct BilboCycleDetailView: View {
    let cycle: BilboCycle
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDay: BilboDay?
    @State private var showingDayEditor = false
    
    private var sortedDays: [BilboDay] {
        cycle.days.sorted { $0.dayNumber < $1.dayNumber }
    }

    private var cycleStats: (completedDays: Int, totalDays: Int, avgWeight: Double, maxWeight: Double, avgReps: Double, maxReps: Int, totalVolume: Double) {
        cycle.getCycleStats()
    }

    private var progressPoints: [ProgressPoint] {
        cycle.days
            .filter { $0.isCompleted && $0.date != nil }
            .sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
            .map { day in
                ProgressPoint(
                    date: day.date ?? .now,
                    targetWeight: day.targetWeight,
                    actualWeight: day.actualWeight,
                    reps: day.repsCompleted,
                    volume: day.actualWeight * Double(day.repsCompleted),
                    estimatedOneRM: day.estimatedOneRM
                )
            }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    cycleHeader

                    // Quick stats
                    insightsSection

                    // Progression chart
                    progressSection
                    
                    // Days List
                    daysList
                }
                .padding()
            }
            .navigationTitle(cycle.exercise?.title ?? NSLocalizedString("bilbo.cycle", comment: "Cycle"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.done", comment: "Done")) { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(NSLocalizedString("bilbo.reset.cycle", comment: "Reset cycle"), role: .destructive) {
                            cycle.resetCycle()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(item: $selectedDay) { day in
                BilboDayEditorView(day: day) {
                    selectedDay = nil
                }
            }
        }
    }
    
    private var cycleHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("bilbo.initial.1rm", comment: "Initial 1RM"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatWeightDisplay(cycle.initialOneRM))
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                if cycle.isCompleted, let finalOneRM = cycle.finalOneRM {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(NSLocalizedString("bilbo.final.1rm", comment: "Final 1RM"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(formatWeightDisplay(finalOneRM))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }
                }
            }
            
            // Progress Bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(NSLocalizedString("bilbo.progress", comment: "Progress"))
                        .font(.headline)
                    Spacer()
                    Text("\(cycle.days.filter { $0.isCompleted }.count)/\(cycle.numberOfDays)")
                        .font(.headline)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: cycle.isCompleted ? [.green, .mint] : [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * min(1.0, max(0.0, cycle.progress)), height: 12)
                    }
                }
                .frame(height: 12)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private var daysList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("bilbo.days", comment: "Days"))
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(sortedDays) { day in
                BilboDayRow(day: day) {
                    selectedDay = day
                }
            }
        }
    }

    private var insightsSection: some View {
        let stats = cycleStats

        return VStack(alignment: .leading, spacing: 12) {
            Text("Resumen rápido")
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                insightCard(
                    icon: "checkmark.circle.fill",
                    title: "Días completados",
                    value: "\(stats.completedDays)/\(stats.totalDays)",
                    subtitle: "Progreso del ciclo",
                    color: .green
                )

                insightCard(
                    icon: "speedometer",
                    title: "Peso medio",
                    value: stats.avgWeight > 0 ? formatWeightDisplay(stats.avgWeight) : "--",
                    subtitle: "Mejor: \(formatWeightDisplay(stats.maxWeight))",
                    color: .blue
                )

                insightCard(
                    icon: "dumbbell",
                    title: "Reps promedio",
                    value: stats.avgReps > 0 ? String(format: "%.1f", stats.avgReps) : "--",
                    subtitle: "Máximo: \(stats.maxReps)",
                    color: .orange
                )

                insightCard(
                    icon: "chart.bar.xaxis",
                    title: "Volumen total",
                    value: stats.totalVolume > 0 ? String(format: "%.0f kg", stats.totalVolume) : "--",
                    subtitle: "kg levantados",
                    color: .purple
                )
            }
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Evolución")
                .font(.headline)

            if progressPoints.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("Cuando completes sesiones verás la progresión aquí.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            } else {
                Chart {
                    ForEach(progressPoints) { point in
                        LineMark(
                            x: .value("Fecha", point.date),
                            y: .value("Peso trabajado", point.actualWeight)
                        )
                        .foregroundStyle(.blue)
                        .interpolationMethod(.monotone)

                        PointMark(
                            x: .value("Fecha", point.date),
                            y: .value("Peso trabajado", point.actualWeight)
                        )
                        .foregroundStyle(.blue)
                        .symbolSize(60)
                    }

                    ForEach(progressPoints.compactMap { point -> ProgressPoint? in
                        guard let estimated = point.estimatedOneRM else { return nil }
                        var copy = point
                        copy.estimatedOneRM = estimated
                        return copy
                    }) { point in
                        LineMark(
                            x: .value("Fecha", point.date),
                            y: .value("1RM estimado", point.estimatedOneRM ?? 0)
                        )
                        .foregroundStyle(.green)
                        .interpolationMethod(.monotone)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    }
                }
                .frame(height: 220)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
        }
    }

    private func insightCard(icon: String, title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }

    private struct ProgressPoint: Identifiable {
        let id = UUID()
        var date: Date
        let targetWeight: Double
        let actualWeight: Double
        let reps: Int
        let volume: Double
        var estimatedOneRM: Double?
    }
}

// MARK: - BilboDayRow
struct BilboDayRow: View {
    let day: BilboDay
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("bilbo.day", comment: "Day") + " \(day.dayNumber)")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if day.isCompleted, let date = day.date {
                        Text(date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(NSLocalizedString("bilbo.not.completed", comment: "Not completed"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if day.isCompleted {
                        Text("\(formatWeightDisplay(day.actualWeight)) × \(day.repsCompleted)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.green)
                        
                        if let estimatedOneRM = day.estimatedOneRM {
                            Text("1RM: \(formatWeightDisplay(estimatedOneRM))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text(formatWeightDisplay(day.targetWeight))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.blue)
                        Text(NSLocalizedString("bilbo.target", comment: "Target"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Image(systemName: day.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(day.isCompleted ? .green : .gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(day.isCompleted ? Color.green.opacity(0.1) : Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - BilboDayEditorView
struct BilboDayEditorView: View {
    let day: BilboDay
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @State private var actualWeight: Double
    @State private var repsCompleted: Int = 0
    @State private var isValidWork: Bool = true
    @State private var date: Date = .now
    @State private var notes: String = ""
    
    init(day: BilboDay, onSave: @escaping () -> Void) {
        self.day = day
        self.onSave = onSave
        self._actualWeight = State(initialValue: day.actualWeight > 0 ? day.actualWeight : day.targetWeight)
        self._repsCompleted = State(initialValue: day.repsCompleted > 0 ? day.repsCompleted : 0)
        self._isValidWork = State(initialValue: day.isValidWork)
        self._date = State(initialValue: day.date ?? .now)
        self._notes = State(initialValue: day.notes)
    }
    
    private var estimatedOneRM: Double? {
        guard actualWeight > 0, repsCompleted > 0 else { return nil }
        let formula = OneRMCalculator.Formula(rawValue: day.cycle?.oneRMFormula ?? OneRMCalculator.Formula.epley.rawValue) ?? .epley
        return OneRMCalculator.calculateOneRM(weight: actualWeight, reps: repsCompleted, formula: formula)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(NSLocalizedString("bilbo.day", comment: "Day"))
                        Spacer()
                        Text("\(day.dayNumber)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text(NSLocalizedString("bilbo.target.weight", comment: "Target weight"))
                        Spacer()
                        Text(formatWeightDisplay(day.targetWeight))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section(NSLocalizedString("bilbo.session.data", comment: "Session data")) {
                    HStack {
                        Text(NSLocalizedString("bilbo.weight.used", comment: "Weight used"))
                        Spacer()
                        TextField("kg", value: $actualWeight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onSubmit {
                                actualWeight = OneRMCalculator.roundToTypicalPlate(actualWeight)
                            }
                    }
                    
                    WeightAdjustmentButtons(weight: $actualWeight)
                    
                    HStack {
                        Text(NSLocalizedString("bilbo.reps.completed", comment: "Reps completed"))
                        Spacer()
                        Stepper("\(repsCompleted)", value: $repsCompleted, in: 0...100)
                    }
                    
                    Toggle(NSLocalizedString("bilbo.valid.work", comment: "Valid work"), isOn: $isValidWork)
                    
                    DatePicker(NSLocalizedString("bilbo.date", comment: "Date"), selection: $date, displayedComponents: .date)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("bilbo.notes", comment: "Notes"))
                        TextField(NSLocalizedString("bilbo.notes.placeholder", comment: "Session notes"), text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }
                
                if let estimatedOneRM = estimatedOneRM {
                    Section(NSLocalizedString("bilbo.estimated.1rm", comment: "Estimated 1RM")) {
                        HStack {
                            Text(NSLocalizedString("bilbo.estimated.1rm", comment: "Estimated 1RM"))
                            Spacer()
                            Text(formatWeightDisplay(estimatedOneRM))
                                .font(.headline)
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("bilbo.edit.day", comment: "Edit Day"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.cancel", comment: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("common.save", comment: "Save")) {
                        saveDay()
                    }
                    .disabled(actualWeight <= 0 || repsCompleted <= 0)
                }
            }
        }
    }
    
    private func saveDay() {
        let formula = OneRMCalculator.Formula(rawValue: day.cycle?.oneRMFormula ?? OneRMCalculator.Formula.epley.rawValue) ?? .epley
        day.complete(
            actualWeight: actualWeight,
            repsCompleted: repsCompleted,
            isValidWork: isValidWork,
            date: date,
            notes: notes,
            formula: formula
        )
        onSave()
        dismiss()
    }
}

// MARK: - WeightAdjustmentButtons
struct WeightAdjustmentButtons: View {
    @Binding var weight: Double
    
    // Discos típicos de gimnasio (kg) - incrementos comunes
    // Nota: Los incrementos representan el cambio total (ambos lados de la barra)
    // Por ejemplo, +2.5 kg significa +1.25 kg por lado
    private let increments: [Double] = [1.25, 2.5, 5, 10]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Botones de decremento
                ForEach(increments.reversed(), id: \.self) { increment in
                    Button(action: {
                        let newWeight = weight - increment
                        weight = max(0, OneRMCalculator.roundToTypicalPlate(newWeight))
                    }) {
                        Text("-\(formatIncrement(increment))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(minWidth: 50)
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                // Botones de incremento
                ForEach(increments, id: \.self) { increment in
                    Button(action: {
                        weight = OneRMCalculator.roundToTypicalPlate(weight + increment)
                    }) {
                        Text("+\(formatIncrement(increment))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(minWidth: 50)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    private func formatIncrement(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
}

// MARK: - Helper Functions
func formatWeightDisplay(_ weight: Double) -> String {
    let rounded = OneRMCalculator.roundToTypicalPlate(weight)
    if rounded.truncatingRemainder(dividingBy: 1) == 0 {
        return String(format: "%.0f kg", rounded)
    } else {
        return String(format: "%.2f kg", rounded)
    }
}

#Preview {
    BilboView()
        .modelContainer(for: [BilboCycle.self, BilboDay.self, BilboExercise.self, BilboSession.self, Exercise.self])
}

// Manual 1RM test: user enters weight and reps to estimate 1RM
struct ManualOneRMTestView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var weight: Double = 0
    @State private var reps: Int = 10
    @State private var selectedFormula: OneRMCalculator.Formula = .epley
    @State private var averageAcrossFormulas: Bool = false
    @State private var showingFormulaInfo: Bool = false
    let onCalculate: (Double, OneRMCalculator.Formula) -> Void

    private var calculatedOneRM: Double {
        guard weight > 0, reps > 0 else { return 0 }
        let rawOneRM: Double
        if averageAcrossFormulas {
            rawOneRM = OneRMCalculator.calculateAverageOneRM(weight: weight, reps: reps)
        } else {
            rawOneRM = OneRMCalculator.calculateOneRM(weight: weight, reps: reps, formula: selectedFormula)
        }
        // Redondear a discos típicos del gimnasio
        return OneRMCalculator.roundToTypicalPlate(rawOneRM)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(NSLocalizedString("bilbo.manual.1rm.inputs", comment: "Inputs")) {
                    HStack {
                        Text(NSLocalizedString("bilbo.manual.weight", comment: "Weight"))
                        Spacer()
                        TextField("kg", value: $weight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onSubmit {
                                // Redondear solo cuando el usuario termine de escribir
                                weight = OneRMCalculator.roundToTypicalPlate(weight)
                            }
                    }
                    HStack {
                        Text(NSLocalizedString("bilbo.manual.reps", comment: "Reps"))
                        Spacer()
                        Stepper("\(reps)", value: $reps, in: 1...50)
                    }
                }

                Section(NSLocalizedString("bilbo.manual.method", comment: "Method")) {
                    Toggle(NSLocalizedString("bilbo.manual.average", comment: "Average of formulas"), isOn: $averageAcrossFormulas)
                    if !averageAcrossFormulas {
                        Picker(NSLocalizedString("bilbo.calculator.formula", comment: "Formula"), selection: $selectedFormula) {
                            ForEach(OneRMCalculator.Formula.allCases, id: \.self) { formula in
                                Text(formula.displayName).tag(formula)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                if calculatedOneRM > 0 {
                    Section(NSLocalizedString("bilbo.manual.result", comment: "Result")) {
                        HStack {
                            Text(NSLocalizedString("bilbo.calculator.result", comment: "Calculated 1RM"))
                            Spacer()
                            Text(formatWeightDisplay(calculatedOneRM))
                                .font(.headline)
                                .foregroundStyle(.blue)
                        }
                        HStack {
                            Text(NSLocalizedString("bilbo.calculator.bilbo.weight", comment: "BILBO training weight"))
                            Spacer()
                            Text(formatWeightDisplay(OneRMCalculator.calculateBilboWeight(oneRM: calculatedOneRM)))
                                .font(.headline)
                                .foregroundStyle(.green)
                        }
                    }
                }
            
            // Información de fórmulas (igual que en el calculador principal)
            Section {
                HStack {
                    Text(NSLocalizedString("bilbo.calculator.formula.info", comment: "Formula Information"))
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Button {
                        showingFormulaInfo.toggle()
                    } label: {
                        Image(systemName: showingFormulaInfo ? "chevron.up" : "chevron.down")
                            .foregroundStyle(.blue)
                    }
                }
                if showingFormulaInfo {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(OneRMCalculator.Formula.allCases, id: \.self) { formula in
                            HStack(alignment: .top, spacing: 8) {
                                Text(formula.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(formula == selectedFormula ? .blue : .primary)
                                Spacer()
                                Text(formula.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.trailing)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            }
            .navigationTitle(NSLocalizedString("bilbo.manual.1rm.title", comment: "Manual 1RM Test"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.cancel", comment: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("bilbo.manual.use", comment: "Use 1RM")) {
                        // Redondear el peso antes de calcular
                        let roundedWeight = OneRMCalculator.roundToTypicalPlate(weight)
                        weight = roundedWeight
                        
                        // El calculatedOneRM ya está redondeado en la propiedad calculada
                        // Si usa promedio, usar epley como fórmula por defecto
                        let formula = averageAcrossFormulas ? .epley : selectedFormula
                        onCalculate(calculatedOneRM, formula)
                        dismiss()
                    }
                    .disabled(calculatedOneRM <= 0)
                }
            }
        }
    }
}
