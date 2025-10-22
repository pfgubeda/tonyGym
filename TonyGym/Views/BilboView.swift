import SwiftUI
import SwiftData

struct BilboView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \BilboExercise.createdAt, order: .reverse) private var bilboExercises: [BilboExercise]
    @Query(sort: \Exercise.title) private var exercises: [Exercise]
    
    @State private var showingExercisePicker = false
    @State private var selectedBilboExercise: BilboExercise?
    @State private var showingSessionLog = false
    @State private var showingInstructions = false
    @State private var selectedExerciseForOneRM: Exercise?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if bilboExercises.isEmpty {
                    emptyStateView
                } else {
                    contentView
                }
            }
            .navigationTitle(NSLocalizedString("bilbo.title", comment: "BILBO Method"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(NSLocalizedString("bilbo.add.exercise", comment: "Add exercise")) {
                            showingExercisePicker = true
                        }
                        Button(NSLocalizedString("bilbo.instructions", comment: "Instructions")) {
                            showingInstructions = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                BilboExercisePickerView(exercises: exercises) { exercise in
                    startOneRMFlow(exercise)
                }
            }
            .sheet(item: $selectedBilboExercise) { bilboExercise in
                BilboSessionLogView(bilboExercise: bilboExercise)
            }
            .sheet(isPresented: $showingInstructions) {
                BilboInstructionsView()
            }
            .sheet(item: $selectedExerciseForOneRM) { exercise in
                OneRMCalculatorView(exercise: exercise) { calculatedOneRM in
                    addBilboExerciseWithCalculatedOneRM(exercise, oneRM: calculatedOneRM)
                    selectedExerciseForOneRM = nil
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
                showingExercisePicker = true
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
            ForEach(bilboExercises) { bilboExercise in
                BilboExerciseCard(bilboExercise: bilboExercise) {
                    selectedBilboExercise = bilboExercise
                }
            }
            .onDelete(perform: deleteBilboExercise)
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
    
    private func addBilboExercise(_ exercise: Exercise) {
        let bilboExercise = BilboExercise(exercise: exercise, oneRepMax: exercise.defaultWeightKg * 2)
        context.insert(bilboExercise)
    }

    private func startOneRMFlow(_ exercise: Exercise) {
        // Set the item; parent will present the sheet once picker dismisses
        selectedExerciseForOneRM = exercise
    }
    
    // Crea un ejercicio BILBO usando un 1RM calculado
    private func addBilboExerciseWithCalculatedOneRM(_ exercise: Exercise, oneRM: Double) {
        let bilboExercise = BilboExercise(exercise: exercise, oneRepMax: oneRM, isAutoCalculated: true)
        context.insert(bilboExercise)
    }
    
    private func deleteBilboExercise(offsets: IndexSet) {
        for index in offsets {
            let bilboExercise = bilboExercises[index]
            context.delete(bilboExercise)
        }
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
                    OneRMCalculatorView(exercise: exercise) { calculatedOneRM in
                        addBilboExerciseWithCalculatedOneRM(exercise, oneRM: calculatedOneRM)
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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @State private var weightUsed: Double
    @State private var repsCompleted: Int = 15
    @State private var notes: String = ""
    @State private var showingOneRMEditor = false
    @State private var newOneRM: Double
    
    init(bilboExercise: BilboExercise) {
        self.bilboExercise = bilboExercise
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
                    }
                    HStack(spacing: 12) {
                        Button(action: { weightUsed = max(0, OneRMCalculator.roundToIncrement(weightUsed - 2.5)) }) {
                            Text("-2.5")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: { weightUsed = max(0, OneRMCalculator.roundToIncrement(weightUsed - 1.25)) }) {
                            Text("-1.25")
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        Button(action: { weightUsed = OneRMCalculator.roundToIncrement(weightUsed + 1.25) }) {
                            Text("+1.25")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: { weightUsed = OneRMCalculator.roundToIncrement(weightUsed + 2.5) }) {
                            Text("+2.5")
                        }
                        .buttonStyle(.bordered)
                    }
                    
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.cancel", comment: "Cancel")) { dismiss() }
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
        
        dismiss()
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
            ManualOneRMTestView { calculated in
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
    let onCalculate: (Double) -> Void
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
                        onCalculate(calculatedOneRM)
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
                ManualOneRMTestView { calculated in
                    onCalculate(calculated)
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
                Text(String(format: "%.2f kg", calculatedOneRM))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
                
                Text(NSLocalizedString("bilbo.calculator.bilbo.weight", comment: "BILBO training weight"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(String(format: "%.2f kg", OneRMCalculator.calculateBilboWeight(oneRM: calculatedOneRM)))
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
        
        calculatedOneRM = OneRMCalculator.findRecentReliableOneRM(from: workoutData, formula: selectedFormula)
    }
}

#Preview {
    BilboView()
        .modelContainer(for: [BilboExercise.self, BilboSession.self, Exercise.self])
}

// Manual 1RM test: user enters weight and reps to estimate 1RM
struct ManualOneRMTestView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var weight: Double = 0
    @State private var reps: Int = 10
    @State private var selectedFormula: OneRMCalculator.Formula = .epley
    @State private var averageAcrossFormulas: Bool = false
    @State private var showingFormulaInfo: Bool = false
    let onCalculate: (Double) -> Void

    private var calculatedOneRM: Double {
        guard weight > 0, reps > 0 else { return 0 }
        if averageAcrossFormulas {
            return OneRMCalculator.calculateAverageOneRM(weight: weight, reps: reps)
        } else {
            return OneRMCalculator.calculateOneRM(weight: weight, reps: reps, formula: selectedFormula)
        }
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
                            Text(String(format: "%.1f kg", calculatedOneRM))
                                .font(.headline)
                                .foregroundStyle(.blue)
                        }
                        HStack {
                            Text(NSLocalizedString("bilbo.calculator.bilbo.weight", comment: "BILBO training weight"))
                            Spacer()
                            Text(String(format: "%.1f kg", OneRMCalculator.calculateBilboWeight(oneRM: calculatedOneRM)))
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
                        onCalculate(calculatedOneRM)
                        dismiss()
                    }
                    .disabled(calculatedOneRM <= 0)
                }
            }
        }
    }
}
