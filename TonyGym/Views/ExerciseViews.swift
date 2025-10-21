import SwiftUI
import _PhotosUI_SwiftUI
import SwiftData

struct ExerciseListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Exercise.title) private var exercises: [Exercise]
    @State private var showingAdd: Bool = false
    @State private var selectedFilter: ExerciseCategory? = nil

    var body: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(label: NSLocalizedString("exercise.filter.all", comment: "All filter"), isSelected: selectedFilter == nil) { selectedFilter = nil }
                    ForEach(ExerciseCategory.allCases) { cat in
                        filterChip(label: cat.displayName, category: cat, isSelected: selectedFilter == cat) { selectedFilter = cat }
                    }
                }
                .padding(.horizontal)
            }
            if filteredExercises().isEmpty {
                // Empty state when no exercises
                VStack(spacing: 24) {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        
                        VStack(spacing: 8) {
                            Text(NSLocalizedString("exercise.no.exercises.title", comment: "No exercises title"))
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text(NSLocalizedString("exercise.no.exercises.message", comment: "No exercises message"))
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    
                    Button(action: { showingAdd = true }) {
                        Text(NSLocalizedString("exercise.no.exercises.add.first", comment: "Add first exercise button"))
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Spacer()
                }
            } else {
                List {
                    ForEach(filteredExercises()) { ex in
                        NavigationLink(destination: ExerciseEditorView(exercise: ex)) {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(ex.title).font(.headline)
                                    Spacer()
                                    Text(ex.category.displayName)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Capsule().fill(ex.category.color.opacity(0.2)))
                                        .foregroundStyle(ex.category.color)
                                }
                                if !ex.details.isEmpty {
                                    Text(ex.details).font(.subheadline).lineLimit(1).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
            }
        }
        .navigationTitle(NSLocalizedString("exercise.title", comment: "Exercises title"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingAdd) {
            ExerciseEditorView(exercise: nil)
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        let source = filteredExercises()
        for index in offsets {
            if let globalIndex = exercises.firstIndex(where: { $0 === source[index] }) {
                context.delete(exercises[globalIndex])
            }
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

struct ExerciseEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State var title: String
    @State var details: String
    @State var weight: Double
    @State var images: [UIImage]
    @State var category: ExerciseCategory

    private var existing: Exercise?

    init(exercise: Exercise?) {
        self.existing = exercise
        _title = State(initialValue: exercise?.title ?? "")
        _details = State(initialValue: exercise?.details ?? "")
        _weight = State(initialValue: exercise?.defaultWeightKg ?? 0)
        _images = State(initialValue: exercise?.images.compactMap { UIImage(data: $0.data) } ?? [])
        _category = State(initialValue: exercise?.category ?? .otros)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(NSLocalizedString("exercise.information", comment: "Information section")) {
                    TextField(NSLocalizedString("exercise.name.placeholder", comment: "Exercise name placeholder"), text: $title)
                    TextField(NSLocalizedString("exercise.description.placeholder", comment: "Exercise description placeholder"), text: $details, axis: .vertical)
                    HStack {
                        Text(NSLocalizedString("exercise.weight", comment: "Weight"))
                        Spacer()
                        TextField(NSLocalizedString("unit.kg", comment: "kg unit"), value: $weight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Picker(NSLocalizedString("exercise.category", comment: "Category"), selection: $category) {
                        ForEach(ExerciseCategory.allCases) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                }

                Section(NSLocalizedString("exercise.images", comment: "Images")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(Array(images.enumerated()), id: \.offset) { idx, img in
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipped()
                                    .contextMenu {
                                        Button(role: .destructive) { images.remove(at: idx) } label: { Label(NSLocalizedString("common.delete", comment: "Delete"), systemImage: "trash") }
                                    }
                            }
                            PhotosPickerButton { uiImage in
                                if let img = uiImage { images.append(img) }
                            }
                        }
                    }
                }
            }
            .navigationTitle(existing == nil ? NSLocalizedString("exercise.add", comment: "Add exercise") : NSLocalizedString("exercise.edit", comment: "Edit exercise"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(NSLocalizedString("common.cancel", comment: "Cancel")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button(NSLocalizedString("common.save", comment: "Save"), action: save) }
            }
        }
    }

    private func save() {
        let attachments = images.compactMap { $0.jpegData(compressionQuality: 0.85) }.map { ImageAttachment(data: $0) }
        if let existing {
            existing.title = title
            existing.details = details
            existing.defaultWeightKg = weight
            existing.images = attachments
            existing.category = category
            existing.updatedAt = .now
        } else {
            let ex = Exercise(title: title, details: details, defaultWeightKg: weight, category: category, images: attachments)
            context.insert(ex)
        }
        dismiss()
    }
}

private struct PhotosPickerButton: View {
    var onPick: (UIImage?) -> Void
    @State private var showPicker = false
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        Button {
            showPicker = true
        } label: {
            VStack {
                Image(systemName: "photo.on.rectangle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .padding(24)
                Text("Añadir")
            }
            .frame(width: 120, height: 120)
            .background(RoundedRectangle(cornerRadius: 12).stroke(.secondary))
        }
        .photosPicker(isPresented: $showPicker, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { oldValue, newValue in
            Task {
                if let newValue, let data = try await newValue.loadTransferable(type: Data.self) {
                    let image = UIImage(data: data)
                    onPick(image)
                    showPicker = false
                }
            }
        }
    }
}


