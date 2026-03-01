import SwiftUI
import SwiftData
import Charts

struct NutritionView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \FoodEntry.date, order: .reverse) private var allFoodEntries: [FoodEntry]
    @Query(sort: \FavoriteFood.usageCount, order: .reverse) private var favoriteFoods: [FavoriteFood]
    @Query private var nutritionGoals: [NutritionGoal]

    @State private var selectedDate: Date = .now
    @State private var showingAddFood: Bool = false
    @State private var editingEntry: FoodEntry?
    @State private var preselectedFavorite: FavoriteFood?
    @State private var showingGoalsSheet: Bool = false
    @State private var selectedTimeframe: Timeframe = .week

    private var nutritionGoal: NutritionGoal {
        if let existing = nutritionGoals.first {
            return existing
        } else {
            let newGoal = NutritionGoal()
            context.insert(newGoal)
            return newGoal
        }
    }

    private var entriesForSelectedDate: [FoodEntry] {
        let calendar = Calendar.current
        return allFoodEntries.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }

    private var totalCalories: Double {
        entriesForSelectedDate.reduce(0) { $0 + $1.calories }
    }

    private var totalProtein: Double {
        entriesForSelectedDate.reduce(0) { $0 + $1.protein }
    }

    private var entriesByMealType: [(MealType, [FoodEntry])] {
        let grouped = Dictionary(grouping: entriesForSelectedDate) { $0.mealType }
        return MealType.allCases.map { ($0, grouped[$0] ?? []) }
    }

    enum Timeframe: String, CaseIterable {
        case week = "Semana"
        case month = "Mes"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                dailySummaryHeader
                dateSelector
                if !favoriteFoods.isEmpty {
                    favoritesSection
                }
                mealListSection
                trendChartsSection
            }
            .padding()
        }
        .navigationTitle(NSLocalizedString("nav.nutrition", comment: "Nutrition"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingGoalsSheet = true
                } label: {
                    Image(systemName: "target")
                }
            }
        }
        .sheet(isPresented: $showingAddFood) {
            AddFoodSheet(selectedDate: selectedDate, selectedMealType: .lunch, preselectedFavorite: preselectedFavorite)
                .onDisappear { preselectedFavorite = nil }
        }
        .sheet(isPresented: $showingGoalsSheet) {
            NutritionGoalsSheet(goal: nutritionGoal)
        }
        .sheet(item: $editingEntry) { entry in
            EditFoodSheet(entry: entry)
                .onDisappear { editingEntry = nil }
        }
    }

    // MARK: - Daily Summary Header

    private var dailySummaryHeader: some View {
        VStack(spacing: 20) {
            HStack(spacing: 24) {
                // Calories ring
                NutritionRingView(
                    value: totalCalories,
                    goal: nutritionGoal.dailyCalories,
                    label: NSLocalizedString("nutrition.calories", comment: "Calories"),
                    unit: "kcal",
                    color: .orange
                )

                // Protein ring
                NutritionRingView(
                    value: totalProtein,
                    goal: nutritionGoal.dailyProtein,
                    label: NSLocalizedString("nutrition.protein", comment: "Protein"),
                    unit: "g",
                    color: .blue
                )
            }
            .padding(.vertical, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Date Selector

    private var dateSelector: some View {
        HStack(spacing: 12) {
            Button {
                if let newDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
                    selectedDate = newDate
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            DatePicker(
                "",
                selection: $selectedDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .labelsHidden()
            .datePickerStyle(.compact)

            Button {
                if let newDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate),
                   newDate <= Date() {
                    selectedDate = newDate
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(Calendar.current.isDateInToday(selectedDate) ? .gray.opacity(0.3) : .secondary)
            }
            .disabled(Calendar.current.isDateInToday(selectedDate))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Favorites

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("nutrition.favorites", comment: "Favorites"))
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(favoriteFoods.prefix(10)) { favorite in
                        FavoriteFoodChip(favorite: favorite) {
                            preselectedFavorite = favorite
                            showingAddFood = true
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

    // MARK: - Meal List

    private var mealListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(NSLocalizedString("nutrition.meals.today", comment: "Today's meals"))
                    .font(.headline)
                Spacer()
                Button {
                    showingAddFood = true
                } label: {
                    Label(NSLocalizedString("nutrition.add.food", comment: "Add food"), systemImage: "plus.circle.fill")
                        .font(.subheadline)
                }
            }

            if entriesForSelectedDate.isEmpty {
                emptyMealsView
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(entriesByMealType, id: \.0.rawValue) { mealType, entries in
                        if !entries.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 6) {
                                    Image(systemName: mealType.iconName)
                                        .font(.caption)
                                    Text(mealType.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }

                                VStack(spacing: 8) {
                                    ForEach(entries) { entry in
                                        FoodEntryRow(entry: entry)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                editingEntry = entry
                                            }
                                            .contextMenu {
                                                Button {
                                                    editingEntry = entry
                                                } label: {
                                                    Label(NSLocalizedString("common.edit", comment: "Edit"), systemImage: "pencil")
                                                }
                                                Button(role: .destructive) {
                                                    context.delete(entry)
                                                } label: {
                                                    Label(NSLocalizedString("common.delete", comment: "Delete"), systemImage: "trash")
                                                }
                                            }
                                    }
                                }
                            }
                        }
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

    private var emptyMealsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(NSLocalizedString("nutrition.no.meals", comment: "No meals"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button(NSLocalizedString("nutrition.add.first", comment: "Add first meal")) {
                showingAddFood = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Trend Charts

    private var trendChartsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Timeframe", selection: $selectedTimeframe) {
                ForEach(Timeframe.allCases, id: \.self) { timeframe in
                    Text(timeframe.rawValue).tag(timeframe)
                }
            }
            .pickerStyle(.segmented)

            Text(NSLocalizedString("nutrition.trend.title", comment: "Tendency"))
                .font(.headline)

            if selectedTimeframe == .week {
                weekTrendChart
            } else {
                monthTrendChart
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    private var weekTrendChart: some View {
        let data = nutritionTrendData(days: 7)
        return chartView(data: data)
    }

    private var monthTrendChart: some View {
        let data = nutritionTrendData(days: 30)
        return chartView(data: data)
    }

    private func nutritionTrendData(days: Int) -> [(date: Date, calories: Double, protein: Double)] {
        let calendar = Calendar.current
        let endDate = selectedDate
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else { return [] }

        var result: [(date: Date, calories: Double, protein: Double)] = []
        var current = startDate

        while current <= endDate {
            let dayStart = calendar.startOfDay(for: current)
            let dayEntries = allFoodEntries.filter { calendar.isDate($0.date, inSameDayAs: dayStart) }
            let calories = dayEntries.reduce(0) { $0 + $1.calories }
            let protein = dayEntries.reduce(0) { $0 + $1.protein }
            result.append((date: dayStart, calories: calories, protein: protein))
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
        }
        return result
    }

    private func chartView(data: [(date: Date, calories: Double, protein: Double)]) -> some View {
        Group {
            if data.isEmpty || data.allSatisfy({ $0.calories == 0 && $0.protein == 0 }) {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text(NSLocalizedString("dashboard.no.data", comment: "No data"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 16) {
                    Chart {
                        ForEach(data, id: \.date) { item in
                            BarMark(
                                x: .value("Fecha", item.date, unit: .day),
                                y: .value("Calorías", item.calories)
                            )
                            .foregroundStyle(.orange.gradient)
                        }
                    }
                    .frame(height: 160)

                    Chart {
                        ForEach(data, id: \.date) { item in
                            BarMark(
                                x: .value("Fecha", item.date, unit: .day),
                                y: .value("Proteína", item.protein)
                            )
                            .foregroundStyle(.blue.gradient)
                        }
                    }
                    .frame(height: 160)
                }
            }
        }
    }
}

struct FavoriteFoodChip: View {
    let favorite: FavoriteFood
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                Text(favorite.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text("\(Int(favorite.calories)) kcal • \(Int(favorite.protein))g")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: 120, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.blue.opacity(0.15))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Supporting Views

struct NutritionRingView: View {
    let value: Double
    let goal: Double
    let label: String
    let unit: String
    let color: Color

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(value / goal, 1.5) // Cap at 150% for display
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 10)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: min(progress, 1))
                    .stroke(color.gradient, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                if progress > 1 {
                    Circle()
                        .trim(from: 1, to: min(progress, 1.5))
                        .stroke(color.opacity(0.5), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                }

                VStack(spacing: 0) {
                    Text("\(Int(value))")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("\(Int(value)) / \(Int(goal)) \(unit)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FoodEntryRow: View {
    let entry: FoodEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text("\(Int(entry.calories))")
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                HStack(spacing: 4) {
                    Image(systemName: "leaf.fill")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    Text("\(Int(entry.protein))g")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
        )
    }
}

struct NutritionGoalsSheet: View {
    @Bindable var goal: NutritionGoal
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(NSLocalizedString("nutrition.goals.title", comment: "Daily goals")) {
                    HStack {
                        Text(NSLocalizedString("nutrition.calories", comment: "Calories"))
                        TextField("kcal", value: $goal.dailyCalories, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text(NSLocalizedString("nutrition.protein", comment: "Protein"))
                        TextField("g", value: $goal.dailyProtein, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("nutrition.goals.title", comment: "Goals"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("common.save", comment: "Save")) {
                        goal.updatedAt = .now
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.close", comment: "Close")) {
                        dismiss()
                    }
                }
            }
        }
    }
}
