import SwiftUI
import SwiftData
import Charts

struct ExerciseDetailSheet: View {
    let exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ExerciseDetailSheetContent(exercise: exercise, isNavigationView: false)
                .navigationTitle(exercise.title)
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(NSLocalizedString("common.close", comment: "Close")) { dismiss() }
                    }
                }
        }
    }
}

struct ExerciseDetailSheetContent: View {
    let exercise: Exercise
    let isNavigationView: Bool
    @Environment(\.modelContext) private var context
    
    @Query(sort: \WorkoutLog.date, order: .reverse) private var allWorkoutLogs: [WorkoutLog]
    @Query(sort: \PersonalRecord.date, order: .reverse) private var allPersonalRecords: [PersonalRecord]
    @Query private var exerciseMarks: [ExerciseMark]
    
    @State private var showingEdit: Bool = false
    
    private var exerciseLogs: [WorkoutLog] {
        allWorkoutLogs.filter { $0.exercise?.id == exercise.id }
    }
    
    private var exerciseMarksForThis: [ExerciseMark] {
        exerciseMarks.filter { $0.exercise?.id == exercise.id }
    }
    
    private var hasMarkForToday: Bool {
        ExerciseMark.hasMark(for: exercise, date: Date(), in: exerciseMarks)
    }
    
    private var exercisePRs: [PersonalRecord] {
        allPersonalRecords.filter { $0.exercise?.id == exercise.id }
    }
    
    private var chartData: [ExerciseChartDataPoint] {
        exerciseLogs
            .sorted { $0.date < $1.date }
            .map { ExerciseChartDataPoint(date: $0.date, weight: $0.maxWeight) }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header con información básica
                exerciseHeaderSection
                
            // Botón destacado para marcar como entrenado (toggle)
            quickMarkButton
            
            // Estadísticas rápidas
            quickStatsSection
                
                // PRs del ejercicio
                if !exercisePRs.isEmpty {
                    prsSection
                }
                
                // Gráfico de progresión
                if !chartData.isEmpty {
                    progressionChartSection
                }
                
                // Historial reciente
                if !exerciseLogs.isEmpty {
                    recentWorkoutsSection
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(NSLocalizedString("common.edit", comment: "Edit")) {
                    showingEdit = true
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            ExerciseEditorView(exercise: exercise)
        }
    }
    
    // MARK: - Sections
    
    private var quickMarkButton: some View {
        Button(action: { toggleExerciseMark() }) {
            HStack {
                Image(systemName: hasMarkForToday ? "checkmark.circle.fill" : "checkmark.circle")
                    .font(.title2)
                Text(hasMarkForToday ? NSLocalizedString("quick.mark.exercise.marked", comment: "Marked as trained") : NSLocalizedString("quick.mark.exercise.button", comment: "Mark as trained"))
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: hasMarkForToday ? 
                        [exercise.category.color.opacity(0.3), exercise.category.color.opacity(0.2)] :
                        [exercise.category.color.opacity(0.2), exercise.category.color.opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(exercise.category.color)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(exercise.category.color.opacity(hasMarkForToday ? 0.5 : 0.3), lineWidth: hasMarkForToday ? 2.5 : 2)
            )
        }
    }
    
    private func toggleExerciseMark() {
        let today = Date()
        let isMarked = ExerciseMark.hasMark(for: exercise, date: today, in: Array(exerciseMarks))
        
        if isMarked {
            // Eliminar marca
            if let mark = exerciseMarks.first(where: { 
                $0.exercise?.id == exercise.id && 
                Calendar.current.isDate($0.date, inSameDayAs: today)
            }) {
                context.delete(mark)
            }
        } else {
            // Crear marca
            let mark = ExerciseMark(date: today, exercise: exercise, notes: "")
            context.insert(mark)
        }
        
        // Actualizar streak
        updateStreakForToday()
        
        // Sincronizar al widget
        syncStreakToWidget()
    }
    
    private func updateStreakForToday() {
        let fetchDescriptor = FetchDescriptor<WorkoutStreak>()
        let streak: WorkoutStreak
        if let existing = try? context.fetch(fetchDescriptor).first {
            streak = existing
        } else {
            streak = WorkoutStreak()
            context.insert(streak)
        }
        
        // Obtener días de descanso de todas las rutinas
        let routineDescriptor = FetchDescriptor<Routine>()
        guard let routines = try? context.fetch(routineDescriptor) else { return }
        
        var allWorkoutWeekdays = Set<Int>()
        for routine in routines {
            let workoutWeekdays = Set(routine.entries.map { $0.weekday.rawValue })
            allWorkoutWeekdays.formUnion(workoutWeekdays)
        }
        
        let allWeekdays = Set(Weekday.allCases.map { $0.rawValue })
        let restWeekdays = allWeekdays.subtracting(allWorkoutWeekdays)
        let restDays = restWeekdays.isEmpty ? nil : restWeekdays
        
        // Obtener marcas diarias y de ejercicios
        let dailyMarkDescriptor = FetchDescriptor<DailyWorkoutMark>()
        let dailyMarks = (try? context.fetch(dailyMarkDescriptor)) ?? []
        
        streak.updateStreak(workoutDate: Date(), restDays: restDays, dailyMarks: dailyMarks, exerciseMarks: Array(exerciseMarks))
    }
    
    private func syncStreakToWidget() {
        let fetchDescriptor = FetchDescriptor<WorkoutStreak>()
        if let streak = try? context.fetch(fetchDescriptor).first {
            WidgetSync.writeStreakSnapshot(streak: streak)
        }
    }
    
    private var exerciseHeaderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Imágenes
            if !exercise.images.isEmpty {
                TabView {
                    ForEach(Array(exercise.images.enumerated()), id: \.offset) { _, att in
                        if let ui = UIImage(data: att.data) {
                            Image(uiImage: ui)
                                .resizable()
                                .scaledToFit()
                        }
                    }
                }
                .frame(height: 260)
                .tabViewStyle(.page)
            }
            
            // Información básica
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(exercise.category.displayName)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(exercise.category.color.opacity(0.2)))
                        .foregroundStyle(exercise.category.color)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "scalemass")
                        Text(String(format: "%.1f kg", exercise.defaultWeightKg))
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                
                if !exercise.details.isEmpty {
                    Text(exercise.details)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("exercise.detail.stats", comment: "Statistics"))
                .font(.headline)
            
            if exerciseLogs.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text(NSLocalizedString("exercise.detail.no.data", comment: "No workout data"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ExerciseStatCard(
                        title: NSLocalizedString("exercise.detail.total.workouts", comment: "Total workouts"),
                        value: "\(exerciseLogs.count)",
                        icon: "dumbbell.fill",
                        color: .blue
                    )
                    
                    ExerciseStatCard(
                        title: NSLocalizedString("exercise.detail.max.weight", comment: "Max weight"),
                        value: String(format: "%.1f kg", maxWeight),
                        icon: "scalemass.fill",
                        color: .green
                    )
                    
                    ExerciseStatCard(
                        title: NSLocalizedString("exercise.detail.total.volume", comment: "Total volume"),
                        value: formatVolume(totalVolume),
                        icon: "chart.bar.fill",
                        color: .purple
                    )
                    
                    ExerciseStatCard(
                        title: NSLocalizedString("exercise.detail.last.workout", comment: "Last workout"),
                        value: lastWorkoutDateString,
                        icon: "calendar",
                        color: .orange
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var prsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("exercise.detail.prs", comment: "Personal Records"))
                .font(.headline)
            
            ForEach(Array(exercisePRs.prefix(3))) { pr in
                PRCard(pr: pr)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var progressionChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("exercise.detail.progression", comment: "Weight Progression"))
                .font(.headline)
            
            Chart {
                ForEach(chartData) { data in
                    LineMark(
                        x: .value("Fecha", data.date),
                        y: .value("Peso", data.weight)
                    )
                    .foregroundStyle(exercise.category.color)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    PointMark(
                        x: .value("Fecha", data.date),
                        y: .value("Peso", data.weight)
                    )
                    .foregroundStyle(exercise.category.color)
                    .symbolSize(50)
                    
                    AreaMark(
                        x: .value("Fecha", data.date),
                        y: .value("Peso", data.weight)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [exercise.category.color.opacity(0.2), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
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
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("exercise.detail.recent.workouts", comment: "Recent Workouts"))
                .font(.headline)
            
            ForEach(Array(exerciseLogs.prefix(5))) { log in
                WorkoutHistoryRowCompact(log: log)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Computed Properties
    
    private var maxWeight: Double {
        exerciseLogs.map { $0.maxWeight }.max() ?? exercise.defaultWeightKg
    }
    
    private var totalVolume: Double {
        exerciseLogs.reduce(0) { $0 + $1.totalVolume }
    }
    
    private var lastWorkoutDateString: String {
        guard let lastLog = exerciseLogs.first else { return "—" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastLog.date, relativeTo: Date())
    }
    
    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1f t", volume / 1000)
        } else {
            return String(format: "%.0f kg", volume)
        }
    }
}

// MARK: - Supporting Views

private struct ExerciseStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

struct PRCard: View {
    let pr: PersonalRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(pr.type.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(pr.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(formatPRValue(pr))
                .font(.headline)
                .foregroundStyle(.yellow)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
        )
    }
    
    private func formatPRValue(_ pr: PersonalRecord) -> String {
        switch pr.type {
        case .maxWeight:
            return String(format: "%.1f kg", pr.weight)
        case .maxReps:
            return "\(pr.reps) reps"
        case .maxVolume:
            return String(format: "%.0f kg", pr.volume)
        }
    }
}

struct WorkoutHistoryRowCompact: View {
    let log: WorkoutLog
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(log.date, style: .date)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if log.hasIndividualSets {
                    Text(String(format: NSLocalizedString("exercise.detail.sets.reps", comment: "%d sets, %d reps"), log.sets, log.totalReps))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(String(format: NSLocalizedString("exercise.detail.sets.reps", comment: "%d sets, %d reps"), log.sets, log.reps))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1f kg", log.maxWeight))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(String(format: "%.0f kg", log.totalVolume))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Data Models

private struct ExerciseChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
}
