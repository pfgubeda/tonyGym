import SwiftUI
import SwiftData

struct WorkoutLogSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var dailyMarks: [DailyWorkoutMark]
    @Query private var exerciseMarks: [ExerciseMark]
    
    let exercise: Exercise
    let entry: RoutineEntry
    
    @State private var useIndividualSets: Bool = false
    @State private var weightUsed: Double
    @State private var sets: Int = 1
    @State private var reps: Int = 1
    @State private var notes: String = ""
    
    // Series individuales
    @State private var individualSets: [SetData] = []
    
    // Timer de descanso
    @State private var showRestTimer: Bool = false
    @State private var restTimerDuration: TimeInterval = 90 // 90 segundos por defecto
    @State private var currentSetIndex: Int? = nil
    
    struct SetData: Identifiable {
        let id = UUID()
        var setNumber: Int
        var weight: Double
        var reps: Int
        var rpe: Int? = nil
        var restTime: TimeInterval? = nil
        var isCompleted: Bool = false
    }
    
    init(exercise: Exercise, entry: RoutineEntry) {
        self.exercise = exercise
        self.entry = entry
        self._weightUsed = State(initialValue: exercise.defaultWeightKg)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Información del ejercicio
                    exerciseInfoSection
                    
                    // Selector de modo
                    modeSelector
                    
                    if useIndividualSets {
                        individualSetsSection
                    } else {
                        simpleModeSection
                    }
                    
                    // Timer de descanso (si está activo)
                    if showRestTimer, let setIndex = currentSetIndex {
                        RestTimer(
                            duration: restTimerDuration,
                            onComplete: {
                                showRestTimer = false
                                currentSetIndex = nil
                            },
                            onCancel: {
                                showRestTimer = false
                                currentSetIndex = nil
                            }
                        )
                    }
                    
                    // Notas
                    notesSection
                    
                    // Resumen
                    summarySection
                }
                .padding()
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
        .onAppear {
            initializeIndividualSets()
        }
    }
    
    // MARK: - Sections
    
    private var exerciseInfoSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(exercise.category.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var modeSelector: some View {
        Picker("Modo", selection: $useIndividualSets) {
            Text(NSLocalizedString("workout.log.mode.simple", comment: "Simple")).tag(false)
            Text(NSLocalizedString("workout.log.mode.detailed", comment: "Detailed")).tag(true)
        }
        .pickerStyle(.segmented)
        .onChange(of: useIndividualSets) { _, newValue in
            if newValue && individualSets.isEmpty {
                initializeIndividualSets()
            }
        }
    }
    
    private var simpleModeSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text(NSLocalizedString("workout.log.weight", comment: "Weight used"))
                Spacer()
                TextField(NSLocalizedString("unit.kg", comment: "kg unit"), value: $weightUsed, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
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
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var individualSetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(NSLocalizedString("workout.log.sets.detailed", comment: "Individual Sets"))
                    .font(.headline)
                Spacer()
                Button(action: addSet) {
                    Label(NSLocalizedString("workout.log.add.set", comment: "Add Set"), systemImage: "plus.circle.fill")
                        .font(.subheadline)
                }
            }
            
            ForEach(Array(individualSets.enumerated()), id: \.element.id) { index, setData in
                IndividualSetRow(
                    setData: Binding(
                        get: { individualSets[index] },
                        set: { individualSets[index] = $0 }
                    ),
                    setNumber: index + 1,
                    onStartRestTimer: {
                        startRestTimer(for: index)
                    },
                    onDelete: {
                        deleteSet(at: index)
                    }
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("workout.log.notes", comment: "Notes"))
                .font(.headline)
            TextField(NSLocalizedString("workout.log.notes.placeholder", comment: "Notes placeholder"), text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var summarySection: some View {
        VStack(spacing: 12) {
            Text(NSLocalizedString("workout.log.summary", comment: "Summary"))
                .font(.headline)
            
            HStack {
                Text(NSLocalizedString("workout.log.total.weight", comment: "Total weight lifted"))
                Spacer()
                Text("\(calculatedTotalWeight, specifier: "%.1f") \(NSLocalizedString("unit.kg", comment: "kg unit"))")
                    .bold()
                    .foregroundStyle(exercise.category.color)
            }
            
            if useIndividualSets {
                HStack {
                    Text(NSLocalizedString("workout.log.total.reps", comment: "Total reps"))
                    Spacer()
                    Text("\(calculatedTotalReps)")
                        .bold()
                }
                
                HStack {
                    Text(NSLocalizedString("workout.log.total.volume", comment: "Total volume"))
                    Spacer()
                    Text("\(calculatedTotalVolume, specifier: "%.0f") kg")
                        .bold()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Computed Properties
    
    private var calculatedTotalWeight: Double {
        if useIndividualSets && !individualSets.isEmpty {
            return individualSets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
        }
        return weightUsed * Double(sets * reps)
    }
    
    private var calculatedTotalReps: Int {
        if useIndividualSets && !individualSets.isEmpty {
            return individualSets.reduce(0) { $0 + $1.reps }
        }
        return sets * reps
    }
    
    private var calculatedTotalVolume: Double {
        if useIndividualSets && !individualSets.isEmpty {
            return individualSets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
        }
        return weightUsed * Double(sets * reps)
    }
    
    // MARK: - Functions
    
    private func initializeIndividualSets() {
        if individualSets.isEmpty {
            individualSets = (1...sets).map { setNumber in
                SetData(
                    setNumber: setNumber,
                    weight: weightUsed,
                    reps: reps
                )
            }
        }
    }
    
    private func addSet() {
        let newSetNumber = individualSets.count + 1
        let lastSet = individualSets.last
        individualSets.append(SetData(
            setNumber: newSetNumber,
            weight: lastSet?.weight ?? weightUsed,
            reps: lastSet?.reps ?? reps
        ))
    }
    
    private func deleteSet(at index: Int) {
        individualSets.remove(at: index)
        // Renumerar sets
        for i in 0..<individualSets.count {
            individualSets[i].setNumber = i + 1
        }
    }
    
    private func startRestTimer(for setIndex: Int) {
        currentSetIndex = setIndex
        showRestTimer = true
    }
    
    private func saveWorkoutLog() {
        let workoutLog = WorkoutLog(
            date: Date(),
            exercise: exercise,
            weightUsed: useIndividualSets ? (individualSets.first?.weight ?? weightUsed) : weightUsed,
            sets: useIndividualSets ? individualSets.count : sets,
            reps: useIndividualSets ? (individualSets.first?.reps ?? reps) : reps,
            notes: notes
        )
        context.insert(workoutLog)
        
        // Guardar series individuales si están habilitadas
        if useIndividualSets && !individualSets.isEmpty {
            for (index, setData) in individualSets.enumerated() {
                let workoutSet = WorkoutSet(
                    workoutLog: workoutLog,
                    setNumber: index + 1,
                    weight: setData.weight,
                    reps: setData.reps,
                    rpe: setData.rpe,
                    restTime: setData.restTime,
                    isCompleted: setData.isCompleted,
                    notes: ""
                )
                if setData.isCompleted {
                    workoutSet.complete()
                }
                context.insert(workoutSet)
            }
            
            // Actualizar peso máximo y promedio
            let maxWeight = individualSets.map { $0.weight }.max() ?? weightUsed
            workoutLog.weightUsed = maxWeight
        }
        
        // Actualizar peso por defecto del ejercicio si es mayor
        let maxWeight = useIndividualSets ? (individualSets.map { $0.weight }.max() ?? weightUsed) : weightUsed
        if maxWeight > exercise.defaultWeightKg {
            exercise.defaultWeightKg = maxWeight
            exercise.updatedAt = .now
        }
        
        // Detectar y crear PRs
        detectAndCreatePRs(from: workoutLog)
        
        // Actualizar streak (con días de descanso de la rutina)
        updateStreak(for: workoutLog.date)
        
        // Verificar milestones
        checkMilestones()
        
        // Sincronizar streak al widget
        syncStreakToWidget()
    }
    
    private func syncStreakToWidget() {
        let fetchDescriptor = FetchDescriptor<WorkoutStreak>()
        if let streak = try? context.fetch(fetchDescriptor).first {
            WidgetSync.writeStreakSnapshot(streak: streak)
        }
    }
    
    private func detectAndCreatePRs(from log: WorkoutLog) {
        let fetchDescriptor = FetchDescriptor<PersonalRecord>()
        let existingPRs = (try? context.fetch(fetchDescriptor)) ?? []
        
        let logsDescriptor = FetchDescriptor<WorkoutLog>()
        let allLogs = (try? context.fetch(logsDescriptor)) ?? []
        
        let newPRTypes = ProgressCalculator.detectNewPR(
            log: log,
            existingPRs: existingPRs,
            allLogs: allLogs
        )
        
        for prType in newPRTypes {
            let pr = ProgressCalculator.createPR(
                from: log,
                type: prType,
                existingPRs: existingPRs,
                context: context
            )
            
            let value: String
            switch prType {
            case .maxWeight:
                value = String(format: "%.1f kg", log.maxWeight)
            case .maxReps:
                value = "\(log.totalReps) reps"
            case .maxVolume:
                value = String(format: "%.0f kg", log.totalVolume)
            }
            
            NotificationManager.shared.celebrateNewPR(
                exerciseName: exercise.title,
                recordType: prType,
                value: value
            )
        }
    }
    
    private func updateStreak(for date: Date) {
        let fetchDescriptor = FetchDescriptor<WorkoutStreak>()
        let streak: WorkoutStreak
        if let existing = try? context.fetch(fetchDescriptor).first {
            streak = existing
        } else {
            streak = WorkoutStreak()
            context.insert(streak)
        }
        
        // Obtener días de descanso de la rutina
        let restDays = getRestDaysFromRoutine()
        streak.updateStreak(workoutDate: date, restDays: restDays, dailyMarks: Array(dailyMarks), exerciseMarks: Array(exerciseMarks))
    }
    
    private func getRestDaysFromRoutine() -> Set<Int>? {
        guard let routine = entry.routine else { return nil }
        let allWeekdays = Set(Weekday.allCases.map { $0.rawValue })
        let workoutWeekdays = Set(routine.entries.map { $0.weekday.rawValue })
        let restWeekdays = allWeekdays.subtracting(workoutWeekdays)
        return restWeekdays.isEmpty ? nil : restWeekdays
    }
    
    private func checkMilestones() {
        let fetchDescriptor = FetchDescriptor<WorkoutLog>()
        guard let allLogs = try? context.fetch(fetchDescriptor) else { return }
        
        let totalWorkouts = allLogs.count
        
        if totalWorkouts == 100 {
            NotificationManager.shared.celebrateMilestone(milestone: .workout100)
        } else if totalWorkouts == 250 {
            NotificationManager.shared.celebrateMilestone(milestone: .workout250)
        } else if totalWorkouts == 500 {
            NotificationManager.shared.celebrateMilestone(milestone: .workout500)
        }
        
        let streakDescriptor = FetchDescriptor<WorkoutStreak>()
        if let streak = try? context.fetch(streakDescriptor).first {
            if streak.currentStreak == 7 {
                NotificationManager.shared.celebrateMilestone(milestone: .streak7)
            } else if streak.currentStreak == 30 {
                NotificationManager.shared.celebrateMilestone(milestone: .streak30)
            } else if streak.currentStreak == 100 {
                NotificationManager.shared.celebrateMilestone(milestone: .streak100)
            }
        }
    }
}

// MARK: - Individual Set Row

struct IndividualSetRow: View {
    @Binding var setData: WorkoutLogSheet.SetData
    let setNumber: Int
    let onStartRestTimer: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(NSLocalizedString("workout.log.set", comment: "Set")) \(setNumber)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Toggle("", isOn: $setData.isCompleted)
                    .labelsHidden()
            }
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("workout.log.weight", comment: "Weight"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("kg", value: $setData.weight, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("workout.log.reps", comment: "Reps"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("reps", value: $setData.reps, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("RPE")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("?", value: Binding(
                        get: { setData.rpe.map { Double($0) } },
                        set: { setData.rpe = $0.map { Int($0) } }
                    ), format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 50)
                }
                
                Button(action: onStartRestTimer) {
                    Image(systemName: "timer")
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
                
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(setData.isCompleted ? Color.green.opacity(0.1) : Color.secondary.opacity(0.05))
        )
    }
}
