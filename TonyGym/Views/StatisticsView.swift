import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutLog.date, order: .reverse) private var workoutLogs: [WorkoutLog]
    @Query private var exercises: [Exercise]
    
    @State private var selectedExercise: Exercise?
    @State private var selectedCategory: ExerciseCategory?
    
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                
                if selectedExercise != nil {
                    exerciseProgressionSection
                    weightProgressionChart
                    recentWorkoutsList
                } else {
                    categoryFilterSection
                    exerciseSelector
                }
            }
            .padding()
        }
        .navigationTitle(NSLocalizedString("stats.title", comment: "Progress tab title"))
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("stats.subtitle", comment: "Progress subtitle"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var categoryFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("stats.filter.category", comment: "Filter by category"))
                .font(.headline)
                .bold()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // All categories button
                    filterChip(
                        label: NSLocalizedString("exercise.filter.all", comment: "All filter"),
                        category: .otros, // Use a neutral color
                        isSelected: selectedCategory == nil
                    ) {
                        selectedCategory = nil
                    }
                    
                    ForEach(ExerciseCategory.allCases) { category in
                        filterChip(
                            label: category.displayName,
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = selectedCategory == category ? nil : category
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var exerciseSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("stats.select.exercise", comment: "Select an exercise"))
                .font(.headline)
                .bold()
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(filteredExercises) { exercise in
                    ExerciseCard(
                        exercise: exercise,
                        isSelected: selectedExercise?.id == exercise.id,
                        onTap: { selectedExercise = exercise }
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
    
    private var exerciseProgressionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedExercise?.title ?? "")
                        .font(.title2)
                        .bold()
                    
                    if let exercise = selectedExercise {
                        Text(exercise.category.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(exercise.category.color.opacity(0.2))
                            )
                            .foregroundStyle(exercise.category.color)
                    }
                }
                
                Spacer()
                
                Button("Cambiar") {
                    selectedExercise = nil
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    
    private var weightProgressionChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Historial de Progresión")
                .font(.headline)
                .bold()
            
            if chartData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text(NSLocalizedString("stats.no.data", comment: "No progression data"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(NSLocalizedString("stats.no.data.message", comment: "Start training message"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 200)
            } else {
                Chart {
                    ForEach(chartData) { data in
                        LineMark(
                            x: .value("Fecha", data.date),
                            y: .value("Peso", data.weight)
                        )
                        .foregroundStyle(selectedExercise?.category.color ?? .blue)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        
                        PointMark(
                            x: .value("Fecha", data.date),
                            y: .value("Peso", data.weight)
                        )
                        .foregroundStyle(selectedExercise?.category.color ?? .blue)
                        .symbolSize(50)
                        
                        AreaMark(
                            x: .value("Fecha", data.date),
                            y: .value("Peso", data.weight)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [(selectedExercise?.category.color ?? .blue).opacity(0.2), .clear],
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
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    
    private var recentWorkoutsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Historial de Pesos")
                .font(.headline)
                .bold()
            
            if chartData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text(NSLocalizedString("stats.no.data", comment: "No progression data"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(NSLocalizedString("stats.no.data.message", comment: "Start training message"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 120)
            } else {
                List {
                    ForEach(chartData.suffix(10).reversed()) { data in
                        WorkoutHistoryRow(data: data, exercise: selectedExercise)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteWorkoutLog(for: data)
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: "trash.fill")
                                            .font(.system(.title3, weight: .semibold))
                                        Text(NSLocalizedString("stats.delete.workout", comment: "Delete workout"))
                                            .font(.system(.caption2, weight: .medium))
                                    }
                                }
                                .tint(.red)
                            }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .frame(height: 240)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    
    private var filteredExercises: [Exercise] {
        if let selectedCategory = selectedCategory {
            return exercises.filter { $0.category == selectedCategory }
        } else {
            return exercises
        }
    }
    
    private var chartData: [ChartDataPoint] {
        guard let selectedExercise = selectedExercise else { return [] }
        
        // Show progression for specific exercise - all individual workout logs
        return workoutLogs
            .filter { $0.exercise?.title == selectedExercise.title }
            .sorted { $0.date < $1.date }
            .map { ChartDataPoint(date: $0.date, weight: $0.weightUsed) }
    }
    
    private func deleteWorkoutLog(for data: ChartDataPoint) {
        // Find the workout log that matches this data point
        if let logToDelete = workoutLogs.first(where: { 
            $0.exercise?.title == selectedExercise?.title &&
            $0.date == data.date &&
            $0.weightUsed == data.weight
        }) {
            context.delete(logToDelete)
        }
    }
    
    private func filterChip(label: String, category: ExerciseCategory, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? category.color.opacity(0.3) : category.color.opacity(0.1))
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? category.color : category.color.opacity(0.5), lineWidth: 1.5)
                )
                .foregroundStyle(isSelected ? category.color : category.color.opacity(0.8))
        }
        .buttonStyle(.plain)
    }
    
}

// MARK: - Supporting Views

struct ExerciseCard: View {
    let exercise: Exercise
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(exercise.title)
                        .font(.subheadline)
                        .bold()
                        .lineLimit(2)
                    Spacer()
                }
                
                Text(exercise.category.displayName)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(exercise.category.color.opacity(0.2))
                    )
                    .foregroundStyle(exercise.category.color)
                
                Spacer()
                
                Text("\(exercise.defaultWeightKg, specifier: "%.1f") kg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? exercise.category.color.opacity(0.2) : .gray.opacity(0.01))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? exercise.category.color : .clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Data Models

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
}

struct WorkoutHistoryRow: View {
    let data: ChartDataPoint
    let exercise: Exercise?
    
    var body: some View {
        HStack(spacing: 16) {
            // Date section with modern styling
            VStack(alignment: .leading, spacing: 6) {
                Text(data.date, style: .date)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text(data.date, style: .time)
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Weight with modern badge design
            HStack(spacing: 8) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(exercise?.category.color ?? .blue)
                
                Text("\(data.weight, specifier: "%.1f") kg")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(exercise?.category.color ?? .blue)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill((exercise?.category.color ?? .blue).opacity(0.12))
                    .overlay(
                        Capsule()
                            .stroke((exercise?.category.color ?? .blue).opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

