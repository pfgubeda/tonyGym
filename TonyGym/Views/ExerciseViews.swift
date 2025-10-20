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
                    filterChip(label: "Todos", isSelected: selectedFilter == nil) { selectedFilter = nil }
                    ForEach(ExerciseCategory.allCases) { cat in
                        filterChip(label: cat.displayName, isSelected: selectedFilter == cat) { selectedFilter = cat }
                    }
                }
                .padding(.horizontal)
            }
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
                                    .background(Capsule().fill(Color.secondary.opacity(0.15)))
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
        .navigationTitle("Ejercicios")
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
                Section("Información") {
                    TextField("Título", text: $title)
                    TextField("Descripción (admite imágenes)", text: $details, axis: .vertical)
                    HStack {
                        Text("Peso por defecto")
                        Spacer()
                        TextField("kg", value: $weight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Picker("Categoría", selection: $category) {
                        ForEach(ExerciseCategory.allCases) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                }

                Section("Imágenes") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(Array(images.enumerated()), id: \.offset) { idx, img in
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipped()
                                    .contextMenu {
                                        Button(role: .destructive) { images.remove(at: idx) } label: { Label("Eliminar", systemImage: "trash") }
                                    }
                            }
                            PhotosPickerButton { uiImage in
                                if let img = uiImage { images.append(img) }
                            }
                        }
                    }
                }
            }
            .navigationTitle(existing == nil ? "Nuevo ejercicio" : "Editar ejercicio")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Guardar", action: save) }
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


