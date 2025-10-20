import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import UIKit

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Routine.name) private var routines: [Routine]
    @Query(sort: \Exercise.title) private var exercises: [Exercise]
    @StateObject private var weightFormatter = WeightFormatter.shared

    @State private var selectedRoutine: Routine?
    @State private var selectedWeekday: Weekday = Self.todayWeekday()
    @State private var showingRoutineMenu: Bool = false
    @State private var showingExercisePicker: Bool = false
    @State private var showingEditRoutineName: Bool = false
    @State private var routineNameDraft: String = ""
    @State private var showingImport: Bool = false
    @State private var importData: Data?
    @State private var showingExport: Bool = false
    @State private var detailExercise: Exercise?
    @State private var editingDayTitle: Bool = false
    @State private var dayTitleDraft: String = ""
    @State private var showingWorkoutLog: Bool = false
    @State private var selectedEntryForLog: RoutineEntry?
    @State private var showingWeightEditor: Bool = false
    @State private var selectedExerciseForWeight: Exercise?
    @State private var customWeight: Double = 0
    @State private var weightChangeTimer: Timer?
    @State private var pendingWeightChange: (exercise: Exercise, weight: Double)?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                header
                weekCalendar
                Divider()
                dayEntriesList
                Spacer(minLength: 0)
            }
            .padding()
            .navigationTitle(NSLocalizedString("nav.today", comment: "Today tab title"))
            .onAppear(perform: selectDefaultRoutineIfNeeded)
            .fileImporter(isPresented: $showingImport, allowedContentTypes: [UTType.json]) { result in
                handleImport(result: result)
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView(exercises: exercises) { exercise in
                    addExerciseToSelectedDay(exercise)
                }
            }
            .sheet(isPresented: $showingEditRoutineName) {
                editRoutineNameSheet
            }
            .sheet(isPresented: $showingExport) { exportSheet }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Menu {
                Button(NSLocalizedString("home.routine.new", comment: "New routine")) { createRoutine() }
                Section(NSLocalizedString("home.routine.import.section", comment: "Import section")) {
                    Button(NSLocalizedString("home.routine.import.json", comment: "Import routine from JSON")) { showingImport = true }
                }
                if !routines.isEmpty {
                    Section(NSLocalizedString("home.routine.select.section", comment: "Select routine section")) {
                        ForEach(routines) { routine in
                            Button(routine.name) { selectedRoutine = routine }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedRoutine?.name ?? NSLocalizedString("home.routine.select", comment: "Select routine"))
                        .font(.title2).bold()
                    Image(systemName: "chevron.down")
                }
                .contentShape(Rectangle())
            }

            Spacer()

            Menu {
                Button(NSLocalizedString("home.routine.edit.name", comment: "Edit name")) {
                    routineNameDraft = selectedRoutine?.name ?? ""
                    showingEditRoutineName = true
                }
                Button(NSLocalizedString("home.routine.export", comment: "Export routine")) { showingExport = true }
                Button(role: .destructive, action: deleteSelectedRoutine) {
                    Text(NSLocalizedString("home.routine.delete", comment: "Delete routine"))
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .imageScale(.large)
            }
            .disabled(selectedRoutine == nil)
        }
    }

    private var weekCalendar: some View {
        HStack(spacing: 8) {
            ForEach(Weekday.allCases) { day in
                let isToday = day == Self.todayWeekday()
                let isSelected = day == selectedWeekday
                let isRest = isRestDay(day)
                let dayCategories = categoriesForDay(day)
                
                VStack(spacing: 4) {
                    Text(day.short)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(
                                    isSelected ? Color.accentColor.opacity(0.2) :
                                    (isRest ? Color.orange.opacity(0.15) : Color.clear)
                                )
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    isToday ? Color.accentColor :
                                    (isRest ? Color.orange.opacity(0.6) : Color.secondary.opacity(0.2)),
                                    lineWidth: isToday ? 2 : 1
                                )
                        )
                        .onTapGesture { selectedWeekday = day }
                    
                    // Always reserve space for category indicators
                    HStack(spacing: 2) {
                        if !dayCategories.isEmpty {
                            ForEach(dayCategories.prefix(3), id: \.self) { category in
                                Circle()
                                    .fill(category.color)
                                    .frame(width: 6, height: 6)
                            }
                            if dayCategories.count > 3 {
                                Text("+")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            // Reserve space with invisible circles to maintain alignment
                            ForEach(0..<3, id: \.self) { _ in
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 6, height: 6)
                            }
                        }
                    }
                    .frame(height: 8) // Fixed height to maintain consistency
                }
            }
        }
    }

    private var dayEntriesList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Button {
                    dayTitleDraft = currentDayTitle()
                    editingDayTitle = true
                } label: {
                    HStack(spacing: 6) {
                        Text(dayHeaderTitle())
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .disabled(selectedRoutine == nil)

                Spacer()

                Button {
                    showingExercisePicker = true
                } label: {
                    Label(NSLocalizedString("home.exercise.add", comment: "Add exercise"), systemImage: "plus")
                }
                .disabled(selectedRoutine == nil)
            }

            if isRestDay(selectedWeekday) {
                VStack(spacing: 12) {
                    Image(systemName: "bed.double.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Color.orange)
                    Text(NSLocalizedString("home.day.rest", comment: "Rest day"))
                        .font(.headline)
                        .foregroundStyle(Color.orange)
                    Text(NSLocalizedString("home.day.no.exercises", comment: "No exercises for this day"))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.08))
                )
            } else {
                List {
                    ForEach(Array(entriesForSelectedDay().enumerated()), id: \.element.persistentModelID) { _, entry in
                        let ex = entry.exercise
                        HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(ex?.title ?? "(Eliminado)")
                                    .font(.body)
                                if let ex {
                                    Text(ex.category.displayName)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(ex.category.color.opacity(0.2)))
                                        .foregroundStyle(ex.category.color)
                                }
                            }
                                if let ex, !ex.details.isEmpty {
                                    Text(ex.details)
                                        .font(.caption)
                                        .lineLimit(1)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            HStack(spacing: 8) {
                                Button {
                                    if let ex { adjustWeight(exercise: ex, delta: -2.5) }
                                } label: {
                                    Image(systemName: "minus.circle.fill").foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            Text(weightString(ex?.defaultWeightKg ?? 0))
                                .monospacedDigit()
                                .frame(minWidth: 72, alignment: .trailing)
                                .foregroundStyle(.secondary)
                                .onTapGesture {
                                    if let ex = ex {
                                        selectedExerciseForWeight = ex
                                        customWeight = ex.defaultWeightKg
                                        showingWeightEditor = true
                                    }
                                }
                                Button {
                                    if let ex { adjustWeight(exercise: ex, delta: 2.5) }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if let ex { detailExercise = ex }
                        }
                        .onLongPressGesture {
                            if let ex = ex {
                                selectedEntryForLog = entry
                                showingWorkoutLog = true
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) { deleteEntry(entry) } label: { Label("Eliminar", systemImage: "trash") }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .sheet(item: $detailExercise) { ex in
            ExerciseDetailSheet(exercise: ex)
        }
        .sheet(isPresented: $showingWorkoutLog) {
            if let entry = selectedEntryForLog, let exercise = entry.exercise {
                WorkoutLogSheet(exercise: exercise, entry: entry)
            }
        }
        .sheet(isPresented: $showingWeightEditor) {
            if let exercise = selectedExerciseForWeight {
                WeightEditorSheet(exercise: exercise, customWeight: $customWeight)
            }
        }
        .sheet(isPresented: $editingDayTitle) {
            NavigationStack {
                Form {
                    TextField(NSLocalizedString("home.day.title.placeholder", comment: "Day title placeholder"), text: $dayTitleDraft)
                }
                .navigationTitle(NSLocalizedString("home.day.edit.title", comment: "Edit day title"))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button(NSLocalizedString("common.cancel", comment: "Cancel")) { editingDayTitle = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(NSLocalizedString("common.save", comment: "Save")) {
                            saveDayTitle(dayTitleDraft)
                            editingDayTitle = false
                        }
                    }
                }
            }
        }
    }

    private func entriesForSelectedDay() -> [RoutineEntry] {
        guard let routine = selectedRoutine else { return [] }
        return routine.entries
            .filter { $0.weekday == selectedWeekday }
            .sorted { $0.order < $1.order }
    }

    private func isRestDay(_ day: Weekday) -> Bool {
        guard let routine = selectedRoutine else { return false }
        // A day is REST only if there are zero exercises scheduled for that weekday
        return !routine.entries.contains { $0.weekday == day }
    }
    
    private func categoriesForDay(_ day: Weekday) -> [ExerciseCategory] {
        guard let routine = selectedRoutine else { return [] }
        let dayEntries = routine.entries.filter { $0.weekday == day }
        let categories = dayEntries.compactMap { $0.exercise?.category }
        return Array(Set(categories)).sorted { $0.rawValue < $1.rawValue }
    }

    private func dayPlanForSelectedDay() -> DayPlan? {
        guard let routine = selectedRoutine else { return nil }
        return routine.dayPlans.first(where: { $0.weekday == selectedWeekday })
    }

    private func dayHeaderTitle() -> String {
        if let plan = dayPlanForSelectedDay(), !plan.title.isEmpty {
            return plan.title
        }
        return String(format: NSLocalizedString("home.day.routine", comment: "Day routine"), weekdayTitle(selectedWeekday))
    }

    private func currentDayTitle() -> String {
        return dayPlanForSelectedDay()?.title ?? ""
    }

    private func saveDayTitle(_ title: String) {
        guard let routine = selectedRoutine else { return }
        if let plan = dayPlanForSelectedDay() {
            plan.title = title
        } else {
            let plan = DayPlan(weekday: selectedWeekday, title: title, routine: routine)
            routine.dayPlans.append(plan)
        }
        routine.updatedAt = .now
    }

    

    private func addExerciseToSelectedDay(_ exercise: Exercise) {
        guard let routine = selectedRoutine else { return }
        let newOrder = entriesForSelectedDay().count
        let entry = RoutineEntry(weekday: selectedWeekday, exercise: exercise, order: newOrder)
        entry.routine = routine
        routine.entries.append(entry)
        routine.updatedAt = .now
    }

    private func deleteEntry(_ entry: RoutineEntry) {
        guard let routine = selectedRoutine else { return }
        if let idx = routine.entries.firstIndex(where: { $0 === entry }) {
            routine.entries.remove(at: idx)
        }
        context.delete(entry)
        routine.updatedAt = .now
    }

    private func createRoutine() {
        let routine = Routine(name: NSLocalizedString("home.routine.new.default", comment: "New Routine"))
        context.insert(routine)
        selectedRoutine = routine
    }

    private func deleteSelectedRoutine() {
        guard let routine = selectedRoutine else { return }
        selectedRoutine = nil
        context.delete(routine)
    }

    private func selectDefaultRoutineIfNeeded() {
        if selectedRoutine == nil { selectedRoutine = routines.first }
    }

    private func weekdayTitle(_ day: Weekday) -> String {
        return day.fullName
    }

    private static func todayWeekday() -> Weekday {
        let cal = Calendar.current
        let weekdayIndex = cal.component(.weekday, from: Date())
        // Map Calendar weekday (1=Sunday) to our Weekday (1=Monday)
        let map: [Int: Weekday] = [
            2: .monday, 3: .tuesday, 4: .wednesday, 5: .thursday,
            6: .friday, 7: .saturday, 1: .sunday
        ]
        return map[weekdayIndex] ?? .monday
    }

    private func weightString(_ kg: Double) -> String {
        let value = kg
        if value == 0 { return "—" }
        return String(format: "%.1f kg", value)
    }

    private func adjustWeight(exercise: Exercise, delta: Double) {
        var newValue = exercise.defaultWeightKg + delta
        if newValue < 0 { newValue = 0 }
        exercise.defaultWeightKg = newValue
        exercise.updatedAt = .now
        
        // Cancel previous timer if exists
        weightChangeTimer?.invalidate()
        
        // Store pending change
        pendingWeightChange = (exercise: exercise, weight: newValue)
        
        // Set timer to save after 2 seconds of no changes
        weightChangeTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            savePendingWeightChange()
        }
    }
    
    private func savePendingWeightChange() {
        guard let pending = pendingWeightChange else { return }
        
        let workoutLog = WorkoutLog(
            date: Date(),
            exercise: pending.exercise,
            weightUsed: pending.weight,
            sets: 1,
            reps: 1,
            notes: "Ajuste rápido desde Home"
        )
        context.insert(workoutLog)
        
        // Clear pending change
        pendingWeightChange = nil
    }

    private var editRoutineNameSheet: some View {
        NavigationStack {
            Form {
                TextField(NSLocalizedString("exercise.name", comment: "Exercise name"), text: $routineNameDraft)
            }
                .navigationTitle(NSLocalizedString("home.routine.edit", comment: "Edit routine"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.cancel", comment: "Cancel")) { showingEditRoutineName = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("common.save", comment: "Save")) {
                        if let r = selectedRoutine { r.name = routineNameDraft; r.updatedAt = .now }
                        showingEditRoutineName = false
                    }
                }
            }
        }
    }

    private var exportSheet: some View {
        Group {
            if let routine = selectedRoutine, let data = ExportImportManager.exportRoutine(routine: routine) {
                ActivityView(activityItems: [data.temporaryFileURL(filename: "\(routine.name).json")])
            } else {
                Text("No se pudo exportar")
            }
        }
    }

    private func handleImport(result: Result<URL, any Error>) {
        switch result {
        case .success(let url):
            do {
                let data = try Data(contentsOf: url)
                let routine = try ExportImportManager.importRoutine(data: data, context: context)
                selectedRoutine = routine
            } catch {
                print("Import failed: \(error)")
            }
        case .failure(let err):
            print("Importer error: \(err)")
        }
    }
}

private struct ExerciseDetailSheet: View {
    let exercise: Exercise
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
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
                    Text(exercise.title).font(.title2).bold()
                    HStack {
                        Image(systemName: "scalemass")
                        Text(String(format: "%.1f kg", exercise.defaultWeightKg))
                    }
                    .foregroundStyle(.secondary)
                    if !exercise.details.isEmpty {
                        Text(exercise.details).font(.body)
                    }
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("exercise.detail.title", comment: "Detail"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.close", comment: "Close")) { dismiss() }
                }
            }
        }
    }
}

private struct ExercisePickerView: View {
    let exercises: [Exercise]
    var onPick: (Exercise) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var selectedFilter: ExerciseCategory? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                categoryFilterBar
                List(filteredExercises()) { exercise in
                Button {
                    onPick(exercise)
                    dismiss()
                } label: {
                    HStack {
                        Text(exercise.title)
                        Spacer()
                            Text(exercise.category.displayName)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(exercise.category.color.opacity(0.2)))
                                .foregroundStyle(exercise.category.color)
                            Text(String(format: "%.1f kg", exercise.defaultWeightKg))
                            .foregroundStyle(.secondary)
                    }
                }
                }
            }
            .navigationTitle(NSLocalizedString("exercise.select.title", comment: "Select exercise"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.close", comment: "Close")) { dismiss() }
                }
            }
        }
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

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [URL]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private enum ExportImportManager {
    struct ExportRoutinePayload: Codable {
        struct ExportExercise: Codable, Identifiable, Hashable {
            var id: UUID
            var title: String
            var details: String
            var defaultWeightKg: Double
                var categoryRaw: Int
        }
        struct ExportEntry: Codable {
            var weekday: Int
            var exerciseId: UUID?
            var note: String
            var order: Int
        }
        var name: String
        var exercises: [ExportExercise]
        var entries: [ExportEntry]
    }

    static func exportRoutine(routine: Routine) -> Data? {
        var exerciseSet: Set<UUID> = []
        var exportExercises: [ExportRoutinePayload.ExportExercise] = []
        for entry in routine.entries {
            if let ex = entry.exercise {
                // Use synthetic IDs in export; persistent IDs are not portable
                let uuid = UUID()
                if !exerciseSet.contains(uuid) {
                    exerciseSet.insert(uuid)
                    exportExercises.append(.init(
                        id: uuid,
                        title: ex.title,
                        details: ex.details,
                        defaultWeightKg: ex.defaultWeightKg,
                        categoryRaw: ex.categoryRaw
                    ))
                }
            }
        }
        let entries: [ExportRoutinePayload.ExportEntry] = routine.entries.map { e in
            return .init(weekday: e.weekday.rawValue, exerciseId: nil, note: e.note, order: e.order)
        }
        let payload = ExportRoutinePayload(name: routine.name, exercises: exportExercises, entries: entries)
        return try? JSONEncoder().encode(payload)
    }

    static func importRoutine(data: Data, context: ModelContext) throws -> Routine {
        let payload = try JSONDecoder().decode(ExportRoutinePayload.self, from: data)
        var importedExercisesById: [UUID: Exercise] = [:]
        for ex in payload.exercises {
            let exercise = Exercise(title: ex.title, details: ex.details, defaultWeightKg: ex.defaultWeightKg, category: ExerciseCategory(rawValue: ex.categoryRaw) ?? .otros, images: [])
            context.insert(exercise)
            importedExercisesById[ex.id] = exercise
        }
        let routine = Routine(name: payload.name)
        // Map entries to exercises by index if possible (fallback), since IDs are synthetic
        let sortedExercises = payload.exercises
        for entry in payload.entries.sorted(by: { $0.order < $1.order }) {
            let exercise = entry.exerciseId.flatMap { importedExercisesById[$0] }
                ?? (sortedExercises.indices.contains(entry.order) ? importedExercisesById[sortedExercises[entry.order].id] : nil)
            let newEntry = RoutineEntry(weekday: Weekday(rawValue: entry.weekday) ?? .monday, exercise: exercise, note: entry.note, order: entry.order)
            newEntry.routine = routine
            routine.entries.append(newEntry)
        }
        context.insert(routine)
        return routine
    }
}

private extension Data {
    func temporaryFileURL(filename: String) -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? self.write(to: url)
        return url
    }
}


