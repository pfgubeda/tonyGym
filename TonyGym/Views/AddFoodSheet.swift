import SwiftUI
import SwiftData

struct AddFoodSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let selectedDate: Date
    let selectedMealType: MealType
    var preselectedFavorite: FavoriteFood?

    @State private var activeTab: AddMode = .manual
    @State private var effectiveFavorite: FavoriteFood?
    @State private var searchText: String = ""
    @State private var selectedFood: CommonFood?
    @State private var customName: String = ""
    @State private var customCalories: Double = 0
    @State private var customProtein: Double = 0
    @State private var customCarbs: Double = 0
    @State private var customFat: Double = 0
    @State private var quantity: Double = 100
    @State private var mealType: MealType
    @State private var addToFavorites: Bool = false
    @State private var showingBarcodeScanner: Bool = false
    @State private var scannedProduct: OpenFoodFactsProduct.Product?
    @State private var scannedBarcode: String?
    @State private var isLoadingProduct: Bool = false
    @State private var scanError: String?

    init(selectedDate: Date, selectedMealType: MealType, preselectedFavorite: FavoriteFood? = nil) {
        self.selectedDate = selectedDate
        self.selectedMealType = selectedMealType
        self.preselectedFavorite = preselectedFavorite
        _mealType = State(initialValue: selectedMealType)
    }

    enum AddMode: String, CaseIterable {
        case manual = "Manual"
        case scan = "Escanear"
    }

    private var searchResults: [CommonFood] {
        CommonFoods.search(searchText)
    }

    private var isFormValid: Bool {
        if selectedFood != nil || scannedProduct != nil || effectiveFavorite != nil {
            return true
        }
        return !customName.isEmpty && (customCalories > 0 || customProtein > 0)
    }

    private var calculatedCalories: Double {
        if let food = selectedFood {
            return (food.caloriesPer100g * quantity / 100).rounded()
        }
        if let favorite = effectiveFavorite {
            return (favorite.per100g ? favorite.calories * quantity / 100 : favorite.calories).rounded()
        }
        if let product = scannedProduct, let kcal = product.nutriments?.energyKcal100g {
            return (kcal * quantity / 100).rounded()
        }
        return customCalories
    }

    private var calculatedProtein: Double {
        if let food = selectedFood {
            return (food.proteinPer100g * quantity / 100).rounded()
        }
        if let favorite = effectiveFavorite {
            return (favorite.per100g ? favorite.protein * quantity / 100 : favorite.protein).rounded()
        }
        if let product = scannedProduct, let p = product.nutriments?.proteins100g {
            return (p * quantity / 100).rounded()
        }
        return customProtein
    }

    private var calculatedCarbs: Double {
        if let food = selectedFood {
            return (food.carbsPer100g * quantity / 100).rounded()
        }
        if let favorite = effectiveFavorite {
            return (favorite.per100g ? favorite.carbs * quantity / 100 : favorite.carbs).rounded()
        }
        if let product = scannedProduct, let c = product.nutriments?.carbohydrates100g {
            return (c * quantity / 100).rounded()
        }
        return customCarbs
    }

    private var calculatedFat: Double {
        if let food = selectedFood {
            return (food.fatPer100g * quantity / 100).rounded()
        }
        if let favorite = effectiveFavorite {
            return (favorite.per100g ? favorite.fat * quantity / 100 : favorite.fat).rounded()
        }
        if let product = scannedProduct, let f = product.nutriments?.fat100g {
            return (f * quantity / 100).rounded()
        }
        return customFat
    }

    private var displayName: String {
        if let product = scannedProduct {
            return [product.productName, product.brands].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " - ")
        }
        return selectedFood?.name ?? effectiveFavorite?.name ?? customName
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Mode", selection: $activeTab) {
                    Text(NSLocalizedString("nutrition.manual", comment: "Manual")).tag(AddMode.manual)
                    Text(NSLocalizedString("nutrition.scan", comment: "Scan")).tag(AddMode.scan)
                }
                .pickerStyle(.segmented)
                .padding()

                if activeTab == .manual {
                    manualContent
                } else {
                    scanContent
                }
            }
            .navigationTitle(NSLocalizedString("nutrition.add.title", comment: "Add food"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.cancel", comment: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("common.save", comment: "Save")) {
                        saveEntry()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
        .onAppear {
            mealType = selectedMealType
            if effectiveFavorite == nil, let fav = preselectedFavorite {
                effectiveFavorite = fav
            }
        }
        .sheet(isPresented: $showingBarcodeScanner) {
            BarcodeScannerView(
                onScan: { barcode in
                    showingBarcodeScanner = false
                    Task { await fetchProductFromBarcode(barcode) }
                },
                onCancel: {
                    showingBarcodeScanner = false
                }
            )
        }
    }

    // MARK: - Manual Content

    private var manualContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Search
                TextField(NSLocalizedString("nutrition.search.placeholder", comment: "Search"), text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()

                if !searchText.isEmpty && selectedFood == nil {
                    searchResultsList
                }

                // Selected food or custom entry
                if selectedFood != nil || scannedProduct != nil || effectiveFavorite != nil {
                    selectedFoodSection
                } else {
                    customEntrySection
                }

                // Quantity (when food from DB, scanned or favorite)
                if selectedFood != nil || scannedProduct != nil || effectiveFavorite != nil {
                    quantitySection
                }

                if let error = scanError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                // Meal type
                mealTypeSection

                // Add to favorites
                Toggle(NSLocalizedString("nutrition.add.to.favorites", comment: "Add to favorites"), isOn: $addToFavorites)
            }
            .padding()
        }
    }

    private var searchResultsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("nutrition.search.results", comment: "Search results"))
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(searchResults) { food in
                Button {
                    selectedFood = food
                    searchText = food.name
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(food.name)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Text("\(Int(food.caloriesPer100g)) kcal • \(Int(food.proteinPer100g))g prot/100g")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.blue)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.ultraThinMaterial)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var selectedFoodSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(displayName)
                    .font(.headline)
                    .lineLimit(2)
                Spacer()
                Button {
                    selectedFood = nil
                    scannedProduct = nil
                    scannedBarcode = nil
                    effectiveFavorite = nil
                    searchText = ""
                    scanError = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.orange.opacity(0.2))
            )

            Text("\(Int(calculatedCalories)) kcal • \(Int(calculatedProtein))g proteína")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var customEntrySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField(NSLocalizedString("nutrition.name", comment: "Name"), text: $customName)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("kcal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("0", value: $customCalories, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Proteína (g)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("0", value: $customProtein, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
    }

    private var quantitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("nutrition.quantity", comment: "Quantity"))
                .font(.subheadline)
                .fontWeight(.medium)

            HStack {
                Slider(value: $quantity, in: 10...500, step: 10)
                Text("\(Int(quantity)) g")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(width: 50, alignment: .trailing)
            }
        }
    }

    private var mealTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("nutrition.meal.type", comment: "Meal type"))
                .font(.subheadline)
                .fontWeight(.medium)

            Picker("Meal type", selection: $mealType) {
                ForEach(MealType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Scan Content

    private var scanContent: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)
            Text(NSLocalizedString("nutrition.scan", comment: "Scan"))
                .font(.title2)
            Text("Escanea el código de barras del producto para obtener su información nutricional automáticamente.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                showingBarcodeScanner = true
            } label: {
                Label("Escanear código", systemImage: "camera.viewfinder")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)
            .disabled(isLoadingProduct)

            if isLoadingProduct {
                ProgressView()
            }

            Spacer()
        }
    }

    private func fetchProductFromBarcode(_ barcode: String) async {
        scanError = nil
        isLoadingProduct = true
        defer { isLoadingProduct = false }

        do {
            if let result = try await OpenFoodFactsService.fetchProduct(barcode: barcode),
               let product = result.product,
               product.nutriments != nil {
                await MainActor.run {
                    scannedProduct = product
                    scannedBarcode = barcode
                    selectedFood = nil
                    customName = ""
                    quantity = 100
                    activeTab = .manual
                }
            } else {
                await MainActor.run {
                    scanError = NSLocalizedString("nutrition.scan.notfound", comment: "Product not found")
                }
            }
        } catch {
            await MainActor.run {
                scanError = error.localizedDescription
            }
        }
    }

    // MARK: - Save

    private func saveEntry() {
        let entry = FoodEntry(
            date: selectedDate,
            name: displayName,
            calories: calculatedCalories,
            protein: calculatedProtein,
            carbs: calculatedCarbs,
            fat: calculatedFat,
            quantity: quantity,
            mealType: mealType,
            source: scannedProduct != nil ? .barcode : .manual,
            barcode: scannedBarcode
        )
        context.insert(entry)

        // Increment usage count when adding from favorite
        if let favorite = effectiveFavorite {
            favorite.usageCount += 1
        }

        if addToFavorites {
            let (cal, prot, carb, f, per100): (Double, Double, Double, Double, Bool)
            if let food = selectedFood {
                (cal, prot, carb, f, per100) = (food.caloriesPer100g, food.proteinPer100g, food.carbsPer100g, food.fatPer100g, true)
            } else if let favorite = effectiveFavorite {
                (cal, prot, carb, f, per100) = (favorite.calories, favorite.protein, favorite.carbs, favorite.fat, favorite.per100g)
            } else if let product = scannedProduct, let nut = product.nutriments {
                (cal, prot, carb, f, per100) = (
                    nut.energyKcal100g ?? 0,
                    nut.proteins100g ?? 0,
                    nut.carbohydrates100g ?? 0,
                    nut.fat100g ?? 0,
                    true
                )
            } else {
                (cal, prot, carb, f, per100) = (
                    quantity > 0 ? calculatedCalories / quantity * 100 : calculatedCalories,
                    quantity > 0 ? calculatedProtein / quantity * 100 : calculatedProtein,
                    quantity > 0 ? calculatedCarbs / quantity * 100 : calculatedCarbs,
                    quantity > 0 ? calculatedFat / quantity * 100 : calculatedFat,
                    true
                )
            }
            let favorite = FavoriteFood(
                name: displayName,
                calories: cal,
                protein: prot,
                carbs: carb,
                fat: f,
                per100g: per100,
                usageCount: 1
            )
            context.insert(favorite)
        }

        dismiss()
    }
}

