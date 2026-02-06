import Foundation
import Speech
import AVFoundation
import Combine

// MARK: - Voice Chat Service

/// Manages on-device speech recognition for hands-free agent interaction.
/// Uses Apple's Speech framework for privacy-friendly, low-latency transcription.
@MainActor
public final class VoiceChatService: ObservableObject {
    public static let shared = VoiceChatService()
    
    // MARK: - Published State
    
    @Published public private(set) var isListening = false
    @Published public private(set) var isAuthorized = false
    @Published public private(set) var liveTranscript = ""
    @Published public private(set) var errorMessage: String?
    @Published public var continuousMode = false
    
    // MARK: - Private
    
    private var recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var onFinalTranscript: ((String) -> Void)?
    
    private init() {
        recognizer = SFSpeechRecognizer(locale: Locale.current)
    }
    
    // MARK: - Authorization
    
    public func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                switch status {
                case .authorized:
                    self?.isAuthorized = true
                    self?.errorMessage = nil
                case .denied:
                    self?.isAuthorized = false
                    self?.errorMessage = "Speech recognition denied. Enable in Settings > Privacy."
                case .restricted:
                    self?.isAuthorized = false
                    self?.errorMessage = "Speech recognition restricted on this device."
                case .notDetermined:
                    self?.isAuthorized = false
                @unknown default:
                    self?.isAuthorized = false
                }
            }
        }
    }
    
    // MARK: - Listening
    
    /// Start listening for speech. Calls `onResult` with the final transcript when the user stops speaking.
    public func startListening(onResult: @escaping (String) -> Void) {
        guard isAuthorized else {
            requestAuthorization()
            return
        }
        
        guard let recognizer, recognizer.isAvailable else {
            errorMessage = "Speech recognition not available."
            return
        }
        
        // Stop any existing session
        stopListening()
        
        onFinalTranscript = onResult
        
        do {
            try startRecognitionSession(recognizer: recognizer)
            isListening = true
            errorMessage = nil
        } catch {
            errorMessage = "Failed to start listening: \(error.localizedDescription)"
            isListening = false
        }
    }
    
    /// Stop listening and finalize transcript
    public func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
    }
    
    // MARK: - Private Recognition
    
    private func startRecognitionSession(recognizer: SFSpeechRecognizer) throws {
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
        
        recognitionRequest = request
        liveTranscript = ""
        
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                
                if let result {
                    self.liveTranscript = result.bestTranscription.formattedString
                    
                    if result.isFinal {
                        let transcript = result.bestTranscription.formattedString
                        if !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            self.onFinalTranscript?(transcript)
                        }
                        self.liveTranscript = ""
                        
                        // In continuous mode, restart after a final result
                        if self.continuousMode {
                            self.restartListening()
                        } else {
                            self.stopListening()
                        }
                    }
                }
                
                if let error {
                    let nsError = error as NSError
                    // Ignore cancellation errors
                    if nsError.domain != "kAFAssistantErrorDomain" || nsError.code != 216 {
                        self.errorMessage = error.localizedDescription
                    }
                    if !self.continuousMode {
                        self.stopListening()
                    }
                }
            }
        }
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    private func restartListening() {
        guard let callback = onFinalTranscript else { return }
        // Small delay before restarting
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
            if continuousMode {
                startListening(onResult: callback)
            }
        }
    }
}
