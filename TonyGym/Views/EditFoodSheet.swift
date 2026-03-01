import SwiftUI
import SwiftData

struct EditFoodSheet: View {
    @Bindable var entry: FoodEntry
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var showingDeleteConfirm: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section(NSLocalizedString("nutrition.name", comment: "Name")) {
                    TextField(NSLocalizedString("nutrition.name", comment: "Name"), text: $entry.name)
                }

                Section(NSLocalizedString("nutrition.quantity", comment: "Quantity")) {
                    HStack {
                        TextField("g", value: $entry.quantity, format: .number)
                            .keyboardType(.decimalPad)
                        Text("g")
                            .foregroundStyle(.secondary)
                    }
                }

                Section(NSLocalizedString("nutrition.nutrients", comment: "Nutrients")) {
                    HStack {
                        Text(NSLocalizedString("nutrition.calories", comment: "Calories"))
                        TextField("kcal", value: $entry.calories, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text(NSLocalizedString("nutrition.protein", comment: "Protein"))
                        TextField("g", value: $entry.protein, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text(NSLocalizedString("nutrition.carbs", comment: "Carbs"))
                        TextField("g", value: $entry.carbs, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text(NSLocalizedString("nutrition.fat", comment: "Fat"))
                        TextField("g", value: $entry.fat, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section(NSLocalizedString("nutrition.meal.type", comment: "Meal type")) {
                    Picker("", selection: $entry.mealType) {
                        ForEach(MealType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        HStack {
                            Spacer()
                            Label(NSLocalizedString("nutrition.delete.food", comment: "Delete food"), systemImage: "trash")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("nutrition.edit.title", comment: "Edit food"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("common.save", comment: "Save")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.close", comment: "Close")) {
                        dismiss()
                    }
                }
            }
            .alert(NSLocalizedString("nutrition.delete.confirm", comment: "Delete confirm"), isPresented: $showingDeleteConfirm) {
                Button(NSLocalizedString("common.cancel", comment: "Cancel"), role: .cancel) { }
                Button(NSLocalizedString("common.delete", comment: "Delete"), role: .destructive) {
                    context.delete(entry)
                    dismiss()
                }
            } message: {
                Text(NSLocalizedString("nutrition.delete.confirm.message", comment: "Delete confirm message"))
            }
        }
    }
}
