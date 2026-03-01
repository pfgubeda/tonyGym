import Foundation

/// Resultado de un producto de Open Food Facts
struct OpenFoodFactsProduct: Decodable {
    let code: String?
    let product: Product?

    struct Product: Decodable {
        let productName: String?
        let brands: String?
        let nutriments: Nutriments?
        let quantity: String?

        enum CodingKeys: String, CodingKey {
            case productName = "product_name"
            case brands
            case nutriments
            case quantity
        }
    }

    struct Nutriments: Decodable {
        let energyKcal100g: Double?
        let proteins100g: Double?
        let carbohydrates100g: Double?
        let fat100g: Double?

        enum CodingKeys: String, CodingKey {
            case energyKcal100g = "energy-kcal_100g"
            case proteins100g = "proteins_100g"
            case carbohydrates100g = "carbohydrates_100g"
            case fat100g = "fat_100g"
        }
    }
}

/// Servicio para consultar Open Food Facts API
enum OpenFoodFactsService {
    private static let baseURL = "https://world.openfoodfacts.org"
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: config)
    }()

    /// Fetches product by barcode
    static func fetchProduct(barcode: String) async throws -> OpenFoodFactsProduct? {
        let url = URL(string: "\(baseURL)/api/v2/product/\(barcode)?fields=product_name,brands,nutriments,quantity")!
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenFoodFactsError.invalidResponse
        }
        guard httpResponse.statusCode == 200 else {
            throw OpenFoodFactsError.httpError(statusCode: httpResponse.statusCode)
        }

        let result = try JSONDecoder().decode(OpenFoodFactsProduct.self, from: data)
        return result.product != nil ? result : nil
    }
}

enum OpenFoodFactsError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case productNotFound

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Respuesta inválida del servidor"
        case .httpError(let code): return "Error del servidor (\(code))"
        case .productNotFound: return "Producto no encontrado"
        }
    }
}
