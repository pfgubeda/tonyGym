import Foundation

/// Alimento común con valores nutricionales por 100g
struct CommonFood: Identifiable {
    let id = UUID()
    let name: String
    let caloriesPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double
}

enum CommonFoods {
    static let all: [CommonFood] = [
        // Carnes
        CommonFood(name: "Pollo pechuga", caloriesPer100g: 165, proteinPer100g: 31, carbsPer100g: 0, fatPer100g: 3.6),
        CommonFood(name: "Pollo muslo", caloriesPer100g: 209, proteinPer100g: 26, carbsPer100g: 0, fatPer100g: 10.9),
        CommonFood(name: "Pavo pechuga", caloriesPer100g: 135, proteinPer100g: 30, carbsPer100g: 0, fatPer100g: 0.7),
        CommonFood(name: "Carne de vaca magra", caloriesPer100g: 250, proteinPer100g: 26, carbsPer100g: 0, fatPer100g: 15),
        CommonFood(name: "Carne de cerdo", caloriesPer100g: 242, proteinPer100g: 27, carbsPer100g: 0, fatPer100g: 14),
        CommonFood(name: "Jamón serrano", caloriesPer100g: 370, proteinPer100g: 21, carbsPer100g: 0, fatPer100g: 32),
        CommonFood(name: "Jamón cocido", caloriesPer100g: 145, proteinPer100g: 21, carbsPer100g: 1.5, fatPer100g: 5.8),
        CommonFood(name: "Bacon", caloriesPer100g: 541, proteinPer100g: 37, carbsPer100g: 1.4, fatPer100g: 42),
        CommonFood(name: "Salchicha", caloriesPer100g: 301, proteinPer100g: 12, carbsPer100g: 1.2, fatPer100g: 28),
        CommonFood(name: "Cordero", caloriesPer100g: 294, proteinPer100g: 25, carbsPer100g: 0, fatPer100g: 21),

        // Pescados
        CommonFood(name: "Salmón", caloriesPer100g: 208, proteinPer100g: 20, carbsPer100g: 0, fatPer100g: 13),
        CommonFood(name: "Atún en lata", caloriesPer100g: 116, proteinPer100g: 26, carbsPer100g: 0, fatPer100g: 0.8),
        CommonFood(name: "Bacalao", caloriesPer100g: 82, proteinPer100g: 18, carbsPer100g: 0, fatPer100g: 0.7),
        CommonFood(name: "Merluza", caloriesPer100g: 71, proteinPer100g: 15, carbsPer100g: 0, fatPer100g: 0.6),
        CommonFood(name: "Gambas", caloriesPer100g: 99, proteinPer100g: 24, carbsPer100g: 0.2, fatPer100g: 0.3),
        CommonFood(name: "Sardinas", caloriesPer100g: 208, proteinPer100g: 25, carbsPer100g: 0, fatPer100g: 11),
        CommonFood(name: "Trucha", caloriesPer100g: 119, proteinPer100g: 20, carbsPer100g: 0, fatPer100g: 3.5),
        CommonFood(name: "Pescado blanco", caloriesPer100g: 82, proteinPer100g: 18, carbsPer100g: 0, fatPer100g: 0.7),
        CommonFood(name: "Caballa", caloriesPer100g: 205, proteinPer100g: 19, carbsPer100g: 0, fatPer100g: 14),

        // Huevos y lácteos
        CommonFood(name: "Huevo entero", caloriesPer100g: 155, proteinPer100g: 13, carbsPer100g: 1.1, fatPer100g: 11),
        CommonFood(name: "Clara de huevo", caloriesPer100g: 52, proteinPer100g: 11, carbsPer100g: 0.7, fatPer100g: 0.2),
        CommonFood(name: "Leche entera", caloriesPer100g: 61, proteinPer100g: 3.2, carbsPer100g: 4.8, fatPer100g: 3.3),
        CommonFood(name: "Leche desnatada", caloriesPer100g: 35, proteinPer100g: 3.4, carbsPer100g: 5, fatPer100g: 0.1),
        CommonFood(name: "Yogur natural", caloriesPer100g: 59, proteinPer100g: 10, carbsPer100g: 3.5, fatPer100g: 0.4),
        CommonFood(name: "Yogur griego", caloriesPer100g: 97, proteinPer100g: 9, carbsPer100g: 3.6, fatPer100g: 5),
        CommonFood(name: "Queso fresco", caloriesPer100g: 98, proteinPer100g: 11, carbsPer100g: 3.5, fatPer100g: 4.3),
        CommonFood(name: "Queso manchego", caloriesPer100g: 364, proteinPer100g: 32, carbsPer100g: 0.5, fatPer100g: 26),
        CommonFood(name: "Queso mozzarella", caloriesPer100g: 280, proteinPer100g: 28, carbsPer100g: 3.1, fatPer100g: 17),
        CommonFood(name: "Requesón", caloriesPer100g: 98, proteinPer100g: 11, carbsPer100g: 3.4, fatPer100g: 4.3),
        CommonFood(name: "Crema de cacahuete", caloriesPer100g: 588, proteinPer100g: 25, carbsPer100g: 20, fatPer100g: 50),

        // Cereales y carbohidratos
        CommonFood(name: "Arroz blanco cocido", caloriesPer100g: 130, proteinPer100g: 2.7, carbsPer100g: 28, fatPer100g: 0.3),
        CommonFood(name: "Arroz integral cocido", caloriesPer100g: 112, proteinPer100g: 2.6, carbsPer100g: 23, fatPer100g: 0.9),
        CommonFood(name: "Pasta cocida", caloriesPer100g: 131, proteinPer100g: 5, carbsPer100g: 25, fatPer100g: 1.1),
        CommonFood(name: "Pan blanco", caloriesPer100g: 265, proteinPer100g: 9, carbsPer100g: 49, fatPer100g: 3.2),
        CommonFood(name: "Pan integral", caloriesPer100g: 247, proteinPer100g: 13, carbsPer100g: 41, fatPer100g: 3.4),
        CommonFood(name: "Avena", caloriesPer100g: 389, proteinPer100g: 17, carbsPer100g: 66, fatPer100g: 6.9),
        CommonFood(name: "Patata cocida", caloriesPer100g: 87, proteinPer100g: 1.9, carbsPer100g: 20, fatPer100g: 0.1),
        CommonFood(name: "Boniato", caloriesPer100g: 86, proteinPer100g: 1.6, carbsPer100g: 20, fatPer100g: 0.1),
        CommonFood(name: "Quinoa cocida", caloriesPer100g: 120, proteinPer100g: 4.4, carbsPer100g: 21, fatPer100g: 1.9),
        CommonFood(name: "Couscous cocido", caloriesPer100g: 112, proteinPer100g: 3.8, carbsPer100g: 23, fatPer100g: 0.2),
        CommonFood(name: "Tortilla de trigo", caloriesPer100g: 304, proteinPer100g: 9.2, carbsPer100g: 51, fatPer100g: 6.9),

        // Legumbres
        CommonFood(name: "Lentejas cocidas", caloriesPer100g: 116, proteinPer100g: 9, carbsPer100g: 20, fatPer100g: 0.4),
        CommonFood(name: "Garbanzos cocidos", caloriesPer100g: 164, proteinPer100g: 8.9, carbsPer100g: 27, fatPer100g: 2.6),
        CommonFood(name: "Alubias cocidas", caloriesPer100g: 127, proteinPer100g: 8.7, carbsPer100g: 22, fatPer100g: 0.5),
        CommonFood(name: "Guisantes cocidos", caloriesPer100g: 84, proteinPer100g: 5.4, carbsPer100g: 15, fatPer100g: 0.2),
        CommonFood(name: "Hummus", caloriesPer100g: 166, proteinPer100g: 7.9, carbsPer100g: 14, fatPer100g: 9.6),

        // Frutas
        CommonFood(name: "Plátano", caloriesPer100g: 89, proteinPer100g: 1.1, carbsPer100g: 23, fatPer100g: 0.3),
        CommonFood(name: "Manzana", caloriesPer100g: 52, proteinPer100g: 0.3, carbsPer100g: 14, fatPer100g: 0.2),
        CommonFood(name: "Naranja", caloriesPer100g: 47, proteinPer100g: 0.9, carbsPer100g: 12, fatPer100g: 0.1),
        CommonFood(name: "Fresas", caloriesPer100g: 32, proteinPer100g: 0.7, carbsPer100g: 8, fatPer100g: 0.3),
        CommonFood(name: "Uvas", caloriesPer100g: 69, proteinPer100g: 0.7, carbsPer100g: 18, fatPer100g: 0.2),
        CommonFood(name: "Sandía", caloriesPer100g: 30, proteinPer100g: 0.6, carbsPer100g: 8, fatPer100g: 0.2),
        CommonFood(name: "Melón", caloriesPer100g: 34, proteinPer100g: 0.8, carbsPer100g: 8, fatPer100g: 0.2),
        CommonFood(name: "Pera", caloriesPer100g: 57, proteinPer100g: 0.4, carbsPer100g: 15, fatPer100g: 0.1),
        CommonFood(name: "Kiwi", caloriesPer100g: 61, proteinPer100g: 1.1, carbsPer100g: 15, fatPer100g: 0.5),
        CommonFood(name: "Mango", caloriesPer100g: 60, proteinPer100g: 0.8, carbsPer100g: 15, fatPer100g: 0.4),
        CommonFood(name: "Aguacate", caloriesPer100g: 160, proteinPer100g: 2, carbsPer100g: 9, fatPer100g: 15),
        CommonFood(name: "Piña", caloriesPer100g: 50, proteinPer100g: 0.5, carbsPer100g: 13, fatPer100g: 0.1),
        CommonFood(name: "Arándanos", caloriesPer100g: 57, proteinPer100g: 0.7, carbsPer100g: 14, fatPer100g: 0.3),
        CommonFood(name: "Frambuesas", caloriesPer100g: 52, proteinPer100g: 1.2, carbsPer100g: 12, fatPer100g: 0.7),

        // Verduras
        CommonFood(name: "Brócoli", caloriesPer100g: 34, proteinPer100g: 2.8, carbsPer100g: 7, fatPer100g: 0.4),
        CommonFood(name: "Espinacas", caloriesPer100g: 23, proteinPer100g: 2.9, carbsPer100g: 3.6, fatPer100g: 0.4),
        CommonFood(name: "Lechuga", caloriesPer100g: 15, proteinPer100g: 1.4, carbsPer100g: 2.9, fatPer100g: 0.2),
        CommonFood(name: "Tomate", caloriesPer100g: 18, proteinPer100g: 0.9, carbsPer100g: 3.9, fatPer100g: 0.2),
        CommonFood(name: "Pepino", caloriesPer100g: 15, proteinPer100g: 0.7, carbsPer100g: 3.6, fatPer100g: 0.1),
        CommonFood(name: "Zanahoria", caloriesPer100g: 41, proteinPer100g: 0.9, carbsPer100g: 10, fatPer100g: 0.2),
        CommonFood(name: "Pimiento", caloriesPer100g: 31, proteinPer100g: 1, carbsPer100g: 6, fatPer100g: 0.3),
        CommonFood(name: "Cebolla", caloriesPer100g: 40, proteinPer100g: 1.1, carbsPer100g: 9, fatPer100g: 0.1),
        CommonFood(name: "Calabacín", caloriesPer100g: 17, proteinPer100g: 1.2, carbsPer100g: 3.1, fatPer100g: 0.3),
        CommonFood(name: "Coliflor", caloriesPer100g: 25, proteinPer100g: 1.9, carbsPer100g: 5, fatPer100g: 0.3),
        CommonFood(name: "Judías verdes", caloriesPer100g: 31, proteinPer100g: 1.8, carbsPer100g: 7, fatPer100g: 0.1),
        CommonFood(name: "Guisantes", caloriesPer100g: 81, proteinPer100g: 5.4, carbsPer100g: 14, fatPer100g: 0.4),
        CommonFood(name: "Maíz", caloriesPer100g: 86, proteinPer100g: 3.3, carbsPer100g: 19, fatPer100g: 1.2),
        CommonFood(name: "Champiñones", caloriesPer100g: 22, proteinPer100g: 3.1, carbsPer100g: 3.3, fatPer100g: 0.3),
        CommonFood(name: "Espárragos", caloriesPer100g: 20, proteinPer100g: 2.2, carbsPer100g: 3.9, fatPer100g: 0.1),

        // Frutos secos y semillas
        CommonFood(name: "Almendras", caloriesPer100g: 579, proteinPer100g: 21, carbsPer100g: 22, fatPer100g: 50),
        CommonFood(name: "Nueces", caloriesPer100g: 654, proteinPer100g: 15, carbsPer100g: 14, fatPer100g: 65),
        CommonFood(name: "Cacahuetes", caloriesPer100g: 567, proteinPer100g: 26, carbsPer100g: 16, fatPer100g: 49),
        CommonFood(name: "Anacardos", caloriesPer100g: 553, proteinPer100g: 18, carbsPer100g: 30, fatPer100g: 44),
        CommonFood(name: "Avellanas", caloriesPer100g: 628, proteinPer100g: 15, carbsPer100g: 17, fatPer100g: 61),
        CommonFood(name: "Pistachos", caloriesPer100g: 560, proteinPer100g: 20, carbsPer100g: 28, fatPer100g: 45),
        CommonFood(name: "Semillas de chía", caloriesPer100g: 486, proteinPer100g: 17, carbsPer100g: 42, fatPer100g: 31),
        CommonFood(name: "Semillas de girasol", caloriesPer100g: 584, proteinPer100g: 21, carbsPer100g: 20, fatPer100g: 52),

        // Snacks y otros
        CommonFood(name: "Chocolate negro 70%", caloriesPer100g: 546, proteinPer100g: 7.8, carbsPer100g: 44, fatPer100g: 42),
        CommonFood(name: "Chocolate con leche", caloriesPer100g: 535, proteinPer100g: 8, carbsPer100g: 59, fatPer100g: 30),
        CommonFood(name: "Miel", caloriesPer100g: 304, proteinPer100g: 0, carbsPer100g: 82, fatPer100g: 0),
        CommonFood(name: "Mermelada", caloriesPer100g: 278, proteinPer100g: 0.4, carbsPer100g: 69, fatPer100g: 0.1),
        CommonFood(name: "Aceite de oliva", caloriesPer100g: 884, proteinPer100g: 0, carbsPer100g: 0, fatPer100g: 100),
        CommonFood(name: "Mantequilla", caloriesPer100g: 717, proteinPer100g: 0.9, carbsPer100g: 0.1, fatPer100g: 81),
        CommonFood(name: "Mayonesa", caloriesPer100g: 680, proteinPer100g: 1.1, carbsPer100g: 0.6, fatPer100g: 75),
        CommonFood(name: "Ketchup", caloriesPer100g: 112, proteinPer100g: 1.8, carbsPer100g: 26, fatPer100g: 0.1),
        CommonFood(name: "Café", caloriesPer100g: 2, proteinPer100g: 0.1, carbsPer100g: 0, fatPer100g: 0),
        CommonFood(name: "Té", caloriesPer100g: 1, proteinPer100g: 0, carbsPer100g: 0.3, fatPer100g: 0),
        CommonFood(name: "Zumo de naranja", caloriesPer100g: 45, proteinPer100g: 0.7, carbsPer100g: 10, fatPer100g: 0.2),
        CommonFood(name: "Batido de proteínas", caloriesPer100g: 110, proteinPer100g: 20, carbsPer100g: 8, fatPer100g: 2),
        CommonFood(name: "Barrita proteica", caloriesPer100g: 400, proteinPer100g: 30, carbsPer100g: 40, fatPer100g: 10),
        CommonFood(name: "Cereales de desayuno", caloriesPer100g: 379, proteinPer100g: 7, carbsPer100g: 84, fatPer100g: 1.4),
        CommonFood(name: "Tostadas con mantequilla", caloriesPer100g: 313, proteinPer100g: 7.5, carbsPer100g: 42, fatPer100g: 12),
        CommonFood(name: "Tortilla de patatas", caloriesPer100g: 180, proteinPer100g: 8, carbsPer100g: 12, fatPer100g: 12),
        CommonFood(name: "Ensalada mixta", caloriesPer100g: 45, proteinPer100g: 2.5, carbsPer100g: 5, fatPer100g: 2),
        CommonFood(name: "Pizza margarita", caloriesPer100g: 266, proteinPer100g: 11, carbsPer100g: 33, fatPer100g: 10),
        CommonFood(name: "Hamburguesa", caloriesPer100g: 295, proteinPer100g: 17, carbsPer100g: 25, fatPer100g: 14),
        CommonFood(name: "Patatas fritas", caloriesPer100g: 312, proteinPer100g: 3.4, carbsPer100g: 41, fatPer100g: 15),
        CommonFood(name: "Croissant", caloriesPer100g: 406, proteinPer100g: 8.2, carbsPer100g: 45, fatPer100g: 21),
        CommonFood(name: "Magdalena", caloriesPer100g: 377, proteinPer100g: 5.2, carbsPer100g: 53, fatPer100g: 16),
        CommonFood(name: "Galletas", caloriesPer100g: 502, proteinPer100g: 6.5, carbsPer100g: 65, fatPer100g: 24),
        CommonFood(name: "Helado", caloriesPer100g: 207, proteinPer100g: 3.5, carbsPer100g: 24, fatPer100g: 11),
        CommonFood(name: "Yogur con frutas", caloriesPer100g: 105, proteinPer100g: 3.5, carbsPer100g: 18, fatPer100g: 2.5),
    ]

    static func search(_ query: String) -> [CommonFood] {
        let lowercased = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !lowercased.isEmpty else { return Array(all.prefix(20)) }
        return all.filter { $0.name.lowercased().contains(lowercased) }
            .prefix(30)
            .map { $0 }
    }
}
