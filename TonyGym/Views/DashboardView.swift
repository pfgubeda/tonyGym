import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutLog.date, order: .reverse) private var allWorkoutLogs: [WorkoutLog]
    @Query(sort: \PersonalRecord.date, order: .reverse) private var personalRecords: [PersonalRecord]
    @Query private var streaks: [WorkoutStreak]
    @Query private var dailyMarks: [DailyWorkoutMark]
    @Query private var exerciseMarks: [ExerciseMark]
    
    @State private var selectedTimeframe: Timeframe = .week
    @State private var showingPRDetails: PersonalRecord?
    
    private var workoutStreak: WorkoutStreak {
        if let existing = streaks.first {
            return existing
        } else {
            let newStreak = WorkoutStreak()
            context.insert(newStreak)
            return newStreak
        }
    }
    
    enum Timeframe: String, CaseIterable {
        case week = "Semana"
        case month = "Mes"
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header con streak
                streakHeader
                
                // Métricas principales
                metricsGrid
                
                // Gráfico de volumen
                volumeChartSection
                
                // Comparación de períodos
                periodComparisonSection
                
                // PRs recientes
                recentPRsSection
            }
            .padding()
        }
        .navigationTitle(NSLocalizedString("dashboard.title", comment: "Dashboard"))
        .onAppear {
            updateStreak()
            syncStreakToWidget()
        }
        .onChange(of: allWorkoutLogs.count) { _, _ in
            updateStreak()
            syncStreakToWidget()
        }
    }
    
    // MARK: - Streak Header
    
    private var streakHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("dashboard.streak.current", comment: "Current streak"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(workoutStreak.currentStreak)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(.orange)
                        
                        Text(NSLocalizedString("dashboard.streak.days", comment: "days"))
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(NSLocalizedString("dashboard.streak.best", comment: "Best streak"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("\(workoutStreak.longestStreak)")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
            }
            
            // Visualización del streak (inspirado en GitHub/Duolingo)
            streakVisualization
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var streakVisualization: some View {
        HStack(spacing: 4) {
            ForEach(0..<min(workoutStreak.currentStreak, 30), id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(streakColor(for: index))
                    .frame(height: 20)
            }
            
            if workoutStreak.currentStreak > 30 {
                Text("+\(workoutStreak.currentStreak - 30)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func streakColor(for index: Int) -> Color {
        let intensity = min(Double(index) / 7.0, 1.0)
        return Color.orange.opacity(0.3 + (intensity * 0.7))
    }
    
    // MARK: - Metrics Grid
    
    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            MetricCard(
                title: NSLocalizedString("dashboard.metric.workouts", comment: "Total workouts"),
                value: "\(ProgressCalculator.totalWorkouts(from: allWorkoutLogs))",
                icon: "dumbbell.fill",
                color: .blue
            )
            
            MetricCard(
                title: NSLocalizedString("dashboard.metric.weight", comment: "Total weight"),
                value: formatWeight(ProgressCalculator.totalWeightLifted(from: allWorkoutLogs)),
                icon: "scalemass.fill",
                color: .green
            )
            
            MetricCard(
                title: NSLocalizedString("dashboard.metric.days", comment: "Active days"),
                value: "\(ProgressCalculator.activeDays(from: allWorkoutLogs))",
                icon: "calendar",
                color: .purple
            )
            
            MetricCard(
                title: NSLocalizedString("dashboard.metric.prs", comment: "Personal Records"),
                value: "\(personalRecords.count)",
                icon: "trophy.fill",
                color: .yellow
            )
        }
    }
    
    // MARK: - Volume Chart
    
    private var volumeChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Timeframe", selection: $selectedTimeframe) {
                ForEach(Timeframe.allCases, id: \.self) { timeframe in
                    Text(timeframe.displayName).tag(timeframe)
                }
            }
            .pickerStyle(.segmented)
            
            if selectedTimeframe == .week {
                weekVolumeChart
            } else {
                monthVolumeChart
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var weekVolumeChart: some View {
        let data = ProgressCalculator.volumeByWeek(from: allWorkoutLogs)
        
        return VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("dashboard.volume.weekly", comment: "Weekly volume"))
                .font(.headline)
            
            if data.isEmpty {
                emptyChartView
            } else {
                Chart {
                    ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                        BarMark(
                            x: .value("Semana", formatWeek(item.weekStart)),
                            y: .value("Volumen", item.volume)
                        )
                        .foregroundStyle(.blue.gradient)
                    }
                }
                .frame(height: 200)
            }
        }
    }
    
    private var monthVolumeChart: some View {
        let data = ProgressCalculator.volumeByMonth(from: allWorkoutLogs)
        
        return VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("dashboard.volume.monthly", comment: "Monthly volume"))
                .font(.headline)
            
            if data.isEmpty {
                emptyChartView
            } else {
                Chart {
                    ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                        BarMark(
                            x: .value("Mes", formatMonth(item.monthStart)),
                            y: .value("Volumen", item.volume)
                        )
                        .foregroundStyle(.green.gradient)
                    }
                }
                .frame(height: 200)
            }
        }
    }
    
    private var emptyChartView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text(NSLocalizedString("dashboard.no.data", comment: "No data available"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Period Comparison
    
    private var periodComparisonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("dashboard.comparison.title", comment: "Period comparison"))
                .font(.headline)
            
            if selectedTimeframe == .week {
                weekComparison
            } else {
                monthComparison
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var weekComparison: some View {
        let current = ProgressCalculator.currentWeekLogs(from: allWorkoutLogs)
        let previous = ProgressCalculator.previousWeekLogs(from: allWorkoutLogs)
        let comparison = ProgressCalculator.comparePeriods(currentLogs: current, previousLogs: previous)
        
        return comparisonView(comparison: comparison)
    }
    
    private var monthComparison: some View {
        let current = ProgressCalculator.currentMonthLogs(from: allWorkoutLogs)
        let previous = ProgressCalculator.previousMonthLogs(from: allWorkoutLogs)
        let comparison = ProgressCalculator.comparePeriods(currentLogs: current, previousLogs: previous)
        
        return comparisonView(comparison: comparison)
    }
    
    private func comparisonView(comparison: ProgressCalculator.PeriodComparison) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("dashboard.comparison.current", comment: "Current period"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatWeight(comparison.currentPeriod.totalVolume))
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(NSLocalizedString("dashboard.comparison.previous", comment: "Previous period"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatWeight(comparison.previousPeriod.totalVolume))
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
            
            Divider()
            
            HStack {
                Image(systemName: comparison.changeType == .increase ? "arrow.up.right" : comparison.changeType == .decrease ? "arrow.down.right" : "minus")
                    .foregroundStyle(comparison.changeType == .increase ? .green : comparison.changeType == .decrease ? .red : .gray)
                
                Text(String(format: "%.1f%%", abs(comparison.change)))
                    .font(.headline)
                    .foregroundStyle(comparison.changeType == .increase ? .green : comparison.changeType == .decrease ? .red : .gray)
                
                Text(NSLocalizedString("dashboard.comparison.change", comment: "change"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Recent PRs
    
    private var recentPRsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("dashboard.prs.recent", comment: "Recent PRs"))
                .font(.headline)
            
            if personalRecords.isEmpty {
                Text(NSLocalizedString("dashboard.prs.none", comment: "No PRs yet"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(Array(personalRecords.prefix(5))) { pr in
                    PRRow(pr: pr)
                        .onTapGesture {
                            showingPRDetails = pr
                        }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .sheet(item: $showingPRDetails) { pr in
            PRDetailSheet(pr: pr)
        }
    }
    
    // MARK: - Helper Functions
    
    private func updateStreak() {
        // Obtener días de descanso de todas las rutinas
        let restDays = getRestDaysFromAllRoutines()
        
        // Combinar fechas de logs, marcas diarias y marcas de ejercicios
        var allWorkoutDates = Set(allWorkoutLogs.map { Calendar.current.startOfDay(for: $0.date) })
        let markDates = Set(dailyMarks.map { Calendar.current.startOfDay(for: $0.date) })
        let exerciseMarkDates = Set(exerciseMarks.map { Calendar.current.startOfDay(for: $0.date) })
        allWorkoutDates.formUnion(markDates)
        allWorkoutDates.formUnion(exerciseMarkDates)
        
        for date in allWorkoutDates.sorted() {
            workoutStreak.updateStreak(workoutDate: date, restDays: restDays, dailyMarks: Array(dailyMarks), exerciseMarks: Array(exerciseMarks))
        }
    }
    
    private func getRestDaysFromAllRoutines() -> Set<Int>? {
        let fetchDescriptor = FetchDescriptor<Routine>()
        guard let routines = try? context.fetch(fetchDescriptor) else { return nil }
        
        // Obtener todos los días de la semana que tienen ejercicios
        var allWorkoutWeekdays = Set<Int>()
        for routine in routines {
            let workoutWeekdays = Set(routine.entries.map { $0.weekday.rawValue })
            allWorkoutWeekdays.formUnion(workoutWeekdays)
        }
        
        // Los días de descanso son los que no tienen ejercicios
        let allWeekdays = Set(Weekday.allCases.map { $0.rawValue })
        let restWeekdays = allWeekdays.subtracting(allWorkoutWeekdays)
        
        return restWeekdays.isEmpty ? nil : restWeekdays
    }
    
    private func syncStreakToWidget() {
        WidgetSync.writeStreakSnapshot(streak: workoutStreak)
    }
    
    private func formatWeight(_ kg: Double) -> String {
        if kg >= 1000 {
            return String(format: "%.1f t", kg / 1000)
        } else {
            return String(format: "%.0f kg", kg)
        }
    }
    
    private func formatWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d/M"
        return formatter.string(from: date)
    }
    
    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct MetricCard: View {
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
                .font(.title2)
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

struct PRRow: View {
    let pr: PersonalRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(pr.exercise?.title ?? NSLocalizedString("exercise.deleted", comment: "Deleted"))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(pr.type.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatPRValue(pr))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.yellow)
                
                Text(pr.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
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

struct PRDetailSheet: View {
    let pr: PersonalRecord
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(NSLocalizedString("pr.detail.exercise", comment: "Exercise")) {
                    Text(pr.exercise?.title ?? NSLocalizedString("exercise.deleted", comment: "Deleted"))
                }
                
                Section(NSLocalizedString("pr.detail.type", comment: "Record type")) {
                    Text(pr.type.displayName)
                }
                
                Section(NSLocalizedString("pr.detail.values", comment: "Values")) {
                    HStack {
                        Text(NSLocalizedString("pr.detail.weight", comment: "Weight"))
                        Spacer()
                        Text(String(format: "%.1f kg", pr.weight))
                    }
                    
                    HStack {
                        Text(NSLocalizedString("pr.detail.reps", comment: "Reps"))
                        Spacer()
                        Text("\(pr.reps)")
                    }
                    
                    HStack {
                        Text(NSLocalizedString("pr.detail.sets", comment: "Sets"))
                        Spacer()
                        Text("\(pr.sets)")
                    }
                    
                    if pr.type == .maxVolume {
                        HStack {
                            Text(NSLocalizedString("pr.detail.volume", comment: "Volume"))
                            Spacer()
                            Text(String(format: "%.0f kg", pr.volume))
                        }
                    }
                }
                
                Section(NSLocalizedString("pr.detail.date", comment: "Date")) {
                    Text(pr.date, style: .date)
                }
                
                if let daysSince = pr.daysSincePreviousPR {
                    Section(NSLocalizedString("pr.detail.time.since", comment: "Time since previous PR")) {
                        Text(String(format: NSLocalizedString("pr.detail.days", comment: "%d days"), daysSince))
                    }
                }
                
                if !pr.notes.isEmpty {
                    Section(NSLocalizedString("pr.detail.notes", comment: "Notes")) {
                        Text(pr.notes)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("pr.detail.title", comment: "PR Details"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.close", comment: "Close")) {
                        dismiss()
                    }
                }
            }
        }
    }
}
