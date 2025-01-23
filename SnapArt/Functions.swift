import Foundation
import UIKit

class AIService {
    // Use configuration value instead of hardcoded key
    private static var apiKey: String {
        return APIKeys.openAIKey
    }
    private static let baseURL = "https://api.openai.com/v1/images/generations"
    
    enum AIError: Error {
        case invalidURL
        case invalidResponse
        case imageGenerationFailed(String)
        case invalidImageData
    }
    
    static func generateImage(from prompt: String) async throws -> UIImage {
        // Prepare URL and request
        guard let url = URL(string: baseURL) else {
            throw AIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare request body
        let requestBody: [String: Any] = [
            "prompt": prompt,
            "n": 1,
            "size": "1024x1024",  // Options: "256x256", "512x512", "1024x1024"
            "response_format": "url"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Make API request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        // Check for successful response
        guard httpResponse.statusCode == 200 else {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw AIError.imageGenerationFailed(errorResponse?.error.message ?? "Unknown error")
        }
        
        // Parse response
        let result = try JSONDecoder().decode(ImageResponse.self, from: data)
        guard let imageURL = URL(string: result.data[0].url) else {
            throw AIError.invalidResponse
        }
        
        // Download the generated image
        let (imageData, _) = try await URLSession.shared.data(from: imageURL)
        
        guard let image = UIImage(data: imageData) else {
            throw AIError.invalidImageData
        }
        
        return image
    }
}

// Response models
struct ImageResponse: Codable {
    let created: Int
    let data: [ImageData]
}

struct ImageData: Codable {
    let url: String
}

struct ErrorResponse: Codable {
    let error: APIError
}

struct APIError: Codable {
    let message: String
    let type: String?
} 