import Foundation
import SwiftUI

// MARK: - Image Service Protocol

public protocol ImageServiceProtocol: Sendable {
    func generateImage(prompt: String, options: ImageGenerationOptions) async throws -> ImageGenerationResult
    func editImage(image: Data, prompt: String, mask: Data?) async throws -> ImageGenerationResult
    func createVariations(image: Data, count: Int) async throws -> [ImageGenerationResult]
}

// MARK: - Image Types

public struct ImageGenerationOptions: Sendable {
    public let size: ImageSize
    public let quality: ImageQuality
    public let style: ImageStyle
    public let count: Int
    
    public enum ImageSize: String, Sendable, CaseIterable {
        case small = "256x256"
        case medium = "512x512"
        case large = "1024x1024"
        case wide = "1792x1024"
        case tall = "1024x1792"
    }
    
    public enum ImageQuality: String, Sendable, CaseIterable {
        case standard
        case hd
    }
    
    public enum ImageStyle: String, Sendable, CaseIterable {
        case vivid
        case natural
    }
    
    public init(
        size: ImageSize = .large,
        quality: ImageQuality = .standard,
        style: ImageStyle = .vivid,
        count: Int = 1
    ) {
        self.size = size
        self.quality = quality
        self.style = style
        self.count = count
    }
    
    public static var `default`: ImageGenerationOptions {
        ImageGenerationOptions()
    }
}

public struct ImageGenerationResult: Sendable {
    public let imageData: Data?
    public let imageURL: URL?
    public let revisedPrompt: String?
    public let timestamp: Date
    
    public init(imageData: Data? = nil, imageURL: URL? = nil, revisedPrompt: String? = nil) {
        self.imageData = imageData
        self.imageURL = imageURL
        self.revisedPrompt = revisedPrompt
        self.timestamp = Date()
    }
}

// MARK: - OpenAI Image Service (DALL-E)

public actor OpenAIImageService: ImageServiceProtocol {
    private let apiKey: String
    private let baseURL: URL
    private let session: URLSession
    
    public init(
        apiKey: String,
        baseURL: URL = URL(string: "https://api.openai.com/v1")!
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        self.session = URLSession(configuration: config)
    }
    
    public func generateImage(prompt: String, options: ImageGenerationOptions) async throws -> ImageGenerationResult {
        let url = baseURL.appendingPathComponent("images/generations")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "dall-e-3",
            "prompt": prompt,
            "n": 1,
            "size": options.size.rawValue,
            "quality": options.quality.rawValue,
            "style": options.style.rawValue,
            "response_format": "b64_json"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ToolError.networkError("Image generation failed")
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataArray = json["data"] as? [[String: Any]],
              let first = dataArray.first,
              let b64String = first["b64_json"] as? String,
              let imageData = Data(base64Encoded: b64String) else {
            throw ToolError.executionFailed("Failed to parse image response")
        }
        
        let revisedPrompt = first["revised_prompt"] as? String
        
        return ImageGenerationResult(imageData: imageData, revisedPrompt: revisedPrompt)
    }
    
    public func editImage(image: Data, prompt: String, mask: Data?) async throws -> ImageGenerationResult {
        let url = baseURL.appendingPathComponent("images/edits")
        let boundary = UUID().uuidString
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add image
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.png\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        body.append(image)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add mask if provided
        if let maskData = mask {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"mask\"; filename=\"mask.png\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
            body.append(maskData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        // Add prompt
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
        body.append(prompt.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add model
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("dall-e-2".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ToolError.networkError("Image edit failed")
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataArray = json["data"] as? [[String: Any]],
              let first = dataArray.first,
              let b64String = first["b64_json"] as? String,
              let imageData = Data(base64Encoded: b64String) else {
            throw ToolError.executionFailed("Failed to parse image response")
        }
        
        return ImageGenerationResult(imageData: imageData)
    }
    
    public func createVariations(image: Data, count: Int) async throws -> [ImageGenerationResult] {
        let url = baseURL.appendingPathComponent("images/variations")
        let boundary = UUID().uuidString
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.png\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        body.append(image)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"n\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(count)".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ToolError.networkError("Image variations failed")
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataArray = json["data"] as? [[String: Any]] else {
            throw ToolError.executionFailed("Failed to parse response")
        }
        
        return dataArray.compactMap { item -> ImageGenerationResult? in
            guard let b64String = item["b64_json"] as? String,
                  let imageData = Data(base64Encoded: b64String) else {
                return nil
            }
            return ImageGenerationResult(imageData: imageData)
        }
    }
}

// MARK: - Image Service Manager

@MainActor
public final class ImageServiceManager: ObservableObject {
    public static let shared = ImageServiceManager()
    private static let apiKeyDefaultsKey = "mcp_openai_api_key"
    private var hasFinishedInitializing = false
    
    @Published public var apiKey: String = "" {
        didSet {
            guard hasFinishedInitializing else { return }
            UserDefaults.standard.set(apiKey, forKey: Self.apiKeyDefaultsKey)
            updateService()
        }
    }
    @Published public private(set) var generatedImages: [ImageGenerationResult] = []
    @Published public private(set) var isGenerating: Bool = false
    
    public private(set) var service: any ImageServiceProtocol
    
    private init() {
        let storedKey = UserDefaults.standard.string(forKey: Self.apiKeyDefaultsKey) ?? ""
        self.apiKey = storedKey
        self.service = OpenAIImageService(apiKey: storedKey)
        hasFinishedInitializing = true
    }
    
    private func updateService() {
        service = OpenAIImageService(apiKey: apiKey)
        MCPLog.settings.info("Configured image service (API key set: \(!self.apiKey.isEmpty, privacy: .public))")
    }
    
    public func generate(prompt: String, options: ImageGenerationOptions = .default) async throws -> ImageGenerationResult {
        guard !apiKey.isEmpty else {
            throw ToolError.networkError("Missing OpenAI API key. Please configure it in Settings before generating images.")
        }
        isGenerating = true
        defer { isGenerating = false }
        
        let result = try await service.generateImage(prompt: prompt, options: options)
        generatedImages.append(result)
        return result
    }
    
    public func clearHistory() {
        generatedImages.removeAll()
    }
}

// MARK: - Image Generation Tool

public struct ImageGenerationTool: MCPTool {
    public let definition = ToolDefinition(
        id: "generate_image",
        name: "Generate Image",
        description: "Generate an AI image from a text description using DALL-E",
        category: .image,
        parameters: [
            ToolParameter(name: "prompt", description: "Description of the image to generate", type: .string),
            ToolParameter(name: "size", description: "Image size", type: .string, required: false, defaultValue: "1024x1024", options: ["256x256", "512x512", "1024x1024", "1792x1024", "1024x1792"]),
            ToolParameter(name: "quality", description: "Image quality", type: .string, required: false, defaultValue: "standard", options: ["standard", "hd"]),
            ToolParameter(name: "style", description: "Image style", type: .string, required: false, defaultValue: "vivid", options: ["vivid", "natural"])
        ],
        icon: "photo.artframe"
    )
    
    public init() {}
    
    public func execute(with invocation: ToolInvocation) async throws -> ToolResult {
        guard let prompt = invocation.parameters["prompt"]?.stringValue else {
            return .error(.missingParameter("prompt"))
        }
        
        let sizeStr = invocation.parameters["size"]?.stringValue ?? "1024x1024"
        let qualityStr = invocation.parameters["quality"]?.stringValue ?? "standard"
        let styleStr = invocation.parameters["style"]?.stringValue ?? "vivid"
        
        let size = ImageGenerationOptions.ImageSize(rawValue: sizeStr) ?? .large
        let quality = ImageGenerationOptions.ImageQuality(rawValue: qualityStr) ?? .standard
        let style = ImageGenerationOptions.ImageStyle(rawValue: styleStr) ?? .vivid
        
        let options = ImageGenerationOptions(size: size, quality: quality, style: style)
        
        let service = await ImageServiceManager.shared.service
        let result = try await service.generateImage(prompt: prompt, options: options)
        
        if let imageData = result.imageData {
            return .success(.image(imageData, mimeType: "image/png"))
        } else if let imageURL = result.imageURL {
            return .success(.text("Image generated: \(imageURL.absoluteString)"))
        } else {
            return .error(.executionFailed("No image data returned"))
        }
    }
}
