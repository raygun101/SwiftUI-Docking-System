import Foundation
import AVFoundation

// MARK: - Audio Service Protocol

public protocol AudioServiceProtocol: Sendable {
    func generateSpeech(text: String, options: SpeechOptions) async throws -> AudioResult
    func transcribe(audioData: Data, options: TranscriptionOptions) async throws -> TranscriptionResult
}

// MARK: - Audio Types

public struct SpeechOptions: Sendable {
    public let voice: Voice
    public let speed: Double
    public let format: AudioFormat
    
    public enum Voice: String, Sendable, CaseIterable {
        case alloy
        case echo
        case fable
        case onyx
        case nova
        case shimmer
        
        public var displayName: String {
            rawValue.capitalized
        }
    }
    
    public enum AudioFormat: String, Sendable, CaseIterable {
        case mp3
        case opus
        case aac
        case flac
        case wav
        case pcm
    }
    
    public init(
        voice: Voice = .alloy,
        speed: Double = 1.0,
        format: AudioFormat = .mp3
    ) {
        self.voice = voice
        self.speed = min(4.0, max(0.25, speed))
        self.format = format
    }
    
    public static var `default`: SpeechOptions {
        SpeechOptions()
    }
}

public struct AudioResult: Sendable {
    public let audioData: Data
    public let format: SpeechOptions.AudioFormat
    public let duration: TimeInterval?
    public let timestamp: Date
    
    public init(audioData: Data, format: SpeechOptions.AudioFormat, duration: TimeInterval? = nil) {
        self.audioData = audioData
        self.format = format
        self.duration = duration
        self.timestamp = Date()
    }
}

public struct TranscriptionOptions: Sendable {
    public let language: String?
    public let prompt: String?
    public let temperature: Double
    public let timestampGranularities: [TimestampGranularity]
    
    public enum TimestampGranularity: String, Sendable {
        case word
        case segment
    }
    
    public init(
        language: String? = nil,
        prompt: String? = nil,
        temperature: Double = 0,
        timestampGranularities: [TimestampGranularity] = []
    ) {
        self.language = language
        self.prompt = prompt
        self.temperature = temperature
        self.timestampGranularities = timestampGranularities
    }
    
    public static var `default`: TranscriptionOptions {
        TranscriptionOptions()
    }
}

public struct TranscriptionResult: Sendable {
    public let text: String
    public let language: String?
    public let duration: TimeInterval?
    public let segments: [TranscriptionSegment]?
    public let words: [TranscriptionWord]?
    
    public init(
        text: String,
        language: String? = nil,
        duration: TimeInterval? = nil,
        segments: [TranscriptionSegment]? = nil,
        words: [TranscriptionWord]? = nil
    ) {
        self.text = text
        self.language = language
        self.duration = duration
        self.segments = segments
        self.words = words
    }
}

public struct TranscriptionSegment: Sendable {
    public let id: Int
    public let text: String
    public let start: TimeInterval
    public let end: TimeInterval
}

public struct TranscriptionWord: Sendable {
    public let word: String
    public let start: TimeInterval
    public let end: TimeInterval
}

// MARK: - OpenAI Audio Service

public actor OpenAIAudioService: AudioServiceProtocol {
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
    
    public func generateSpeech(text: String, options: SpeechOptions) async throws -> AudioResult {
        let url = baseURL.appendingPathComponent("audio/speech")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "tts-1",
            "input": text,
            "voice": options.voice.rawValue,
            "speed": options.speed,
            "response_format": options.format.rawValue
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ToolError.networkError("Speech generation failed")
        }
        
        return AudioResult(audioData: data, format: options.format)
    }
    
    public func transcribe(audioData: Data, options: TranscriptionOptions) async throws -> TranscriptionResult {
        let url = baseURL.appendingPathComponent("audio/transcriptions")
        let boundary = UUID().uuidString
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add audio file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.mp3\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/mpeg\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add model
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add language if specified
        if let language = options.language {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
            body.append(language.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        // Add response format for timestamps
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("verbose_json".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ToolError.networkError("Transcription failed")
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let text = json["text"] as? String else {
            throw ToolError.executionFailed("Failed to parse transcription")
        }
        
        let language = json["language"] as? String
        let duration = json["duration"] as? TimeInterval
        
        return TranscriptionResult(text: text, language: language, duration: duration)
    }
}

// MARK: - Audio Service Manager

@MainActor
public final class AudioServiceManager: ObservableObject {
    public static let shared = AudioServiceManager()
    private static let apiKeyDefaultsKey = "mcp_openai_api_key"
    private var hasFinishedInitializing = false
    
    @Published public var apiKey: String = "" {
        didSet {
            guard hasFinishedInitializing else { return }
            UserDefaults.standard.set(apiKey, forKey: Self.apiKeyDefaultsKey)
            updateService()
        }
    }
    @Published public private(set) var generatedAudio: [AudioResult] = []
    @Published public private(set) var isGenerating: Bool = false
    
    public private(set) var service: any AudioServiceProtocol
    
    private init() {
        let storedKey = UserDefaults.standard.string(forKey: Self.apiKeyDefaultsKey) ?? ""
        self.apiKey = storedKey
        self.service = OpenAIAudioService(apiKey: storedKey)
        hasFinishedInitializing = true
    }
    
    private func updateService() {
        service = OpenAIAudioService(apiKey: apiKey)
        MCPLog.settings.info("Configured audio service (API key set: \(!self.apiKey.isEmpty, privacy: .public))")
    }
    
    public func generateSpeech(text: String, options: SpeechOptions = .default) async throws -> AudioResult {
        guard !apiKey.isEmpty else {
            throw ToolError.networkError("Missing OpenAI API key. Please configure it in Settings before generating audio.")
        }
        isGenerating = true
        defer { isGenerating = false }
        
        let result = try await service.generateSpeech(text: text, options: options)
        generatedAudio.append(result)
        return result
    }
    
    public func transcribe(audioData: Data, options: TranscriptionOptions = .default) async throws -> TranscriptionResult {
        guard !apiKey.isEmpty else {
            throw ToolError.networkError("Missing OpenAI API key. Please configure it in Settings before transcribing audio.")
        }
        return try await service.transcribe(audioData: audioData, options: options)
    }
    
    public func clearHistory() {
        generatedAudio.removeAll()
    }
}

// MARK: - Audio Generation Tool

public struct TextToSpeechTool: MCPTool {
    public let definition = ToolDefinition(
        id: "text_to_speech",
        name: "Text to Speech",
        description: "Convert text to natural-sounding speech audio",
        category: .audio,
        parameters: [
            ToolParameter(name: "text", description: "The text to convert to speech", type: .string),
            ToolParameter(name: "voice", description: "Voice to use", type: .string, required: false, defaultValue: "alloy", options: ["alloy", "echo", "fable", "onyx", "nova", "shimmer"]),
            ToolParameter(name: "speed", description: "Speech speed (0.25 to 4.0)", type: .number, required: false, defaultValue: "1.0"),
            ToolParameter(name: "format", description: "Audio format", type: .string, required: false, defaultValue: "mp3", options: ["mp3", "opus", "aac", "flac", "wav"])
        ],
        icon: "speaker.wave.3"
    )
    
    public init() {}
    
    public func execute(with invocation: ToolInvocation) async throws -> ToolResult {
        guard let text = invocation.parameters["text"]?.stringValue else {
            return .error(.missingParameter("text"))
        }
        
        let voiceStr = invocation.parameters["voice"]?.stringValue ?? "alloy"
        let speed = invocation.parameters["speed"]?.numberValue ?? 1.0
        let formatStr = invocation.parameters["format"]?.stringValue ?? "mp3"
        
        let voice = SpeechOptions.Voice(rawValue: voiceStr) ?? .alloy
        let format = SpeechOptions.AudioFormat(rawValue: formatStr) ?? .mp3
        
        let options = SpeechOptions(voice: voice, speed: speed, format: format)
        
        let service = await AudioServiceManager.shared.service
        let result = try await service.generateSpeech(text: text, options: options)
        
        return .success(.audio(result.audioData, mimeType: "audio/\(format.rawValue)"))
    }
}

// MARK: - Transcription Tool

public struct TranscriptionTool: MCPTool {
    public let definition = ToolDefinition(
        id: "transcribe_audio",
        name: "Transcribe Audio",
        description: "Transcribe audio to text using Whisper",
        category: .audio,
        parameters: [
            ToolParameter(name: "audio_path", description: "Path to the audio file", type: .file),
            ToolParameter(name: "language", description: "Language code (e.g., 'en', 'es')", type: .string, required: false)
        ],
        icon: "waveform"
    )
    
    public init() {}
    
    public func execute(with invocation: ToolInvocation) async throws -> ToolResult {
        guard let audioPath = invocation.parameters["audio_path"]?.stringValue else {
            return .error(.missingParameter("audio_path"))
        }
        
        let url = URL(fileURLWithPath: audioPath)
        guard let audioData = try? Data(contentsOf: url) else {
            return .error(.executionFailed("Could not read audio file"))
        }
        
        let language = invocation.parameters["language"]?.stringValue
        let options = TranscriptionOptions(language: language)
        
        let service = await AudioServiceManager.shared.service
        let result = try await service.transcribe(audioData: audioData, options: options)
        
        return .success(.text(result.text))
    }
}
