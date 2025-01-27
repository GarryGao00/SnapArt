import Foundation
import UIKit

enum AIService {
    enum AIError: LocalizedError {
        case invalidURL
        case invalidResponse
        case imageGenerationFailed(String)
        case invalidImageData
        case encodingError
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid API URL"
            case .invalidResponse:
                return "Invalid response from server"
            case .imageGenerationFailed(let message):
                return "Generation failed: \(message)"
            case .invalidImageData:
                return "Unable to process the image data"
            case .encodingError:
                return "Failed to encode image data"
            }
        }
    }
    
    static func generateArtFromImage(_ image: UIImage, 
                                   prompt: String = "whimsical watercolor style using pastel colors, gentle brush strokes, and soft, diffused outlines.",
                                   controlStrength: Float = 0.7) async throws -> UIImage {
        // Debug print API key
        print("Using Stability API Key: \(APIKeys.stabilityKey.prefix(7))...")
        
        // Prepare URL and request
        guard let url = URL(string: "https://api.stability.ai/v2beta/stable-image/control/structure") else {
            throw AIError.invalidURL
        }
        
        // Convert UIImage to Data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw AIError.encodingError
        }
        
        // Create multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(APIKeys.stabilityKey)", forHTTPHeaderField: "Authorization")
        request.setValue("image/*", forHTTPHeaderField: "Accept")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add image data
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n")
        body.append("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.append("\r\n")
        
        // Add other parameters
        let parameters: [String: Any] = [
            "prompt": prompt,
            "negative_prompt": "",
            "control_strength": controlStrength,
            "seed": 0,
            "output_format": "webp"
        ]
        
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }
        
        body.append("--\(boundary)--\r\n")
        request.httpBody = body
        
        // Make API request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        // Print response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("API Response: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = errorJson["message"] as? String {
                throw AIError.imageGenerationFailed(message)
            }
            throw AIError.imageGenerationFailed("Failed with status code: \(httpResponse.statusCode)")
        }
        
        // Convert response data directly to UIImage
        guard let generatedImage = UIImage(data: data) else {
            throw AIError.invalidImageData
        }
        
        return generatedImage
    }
}

// Helper extension for building multipart form data
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
} 