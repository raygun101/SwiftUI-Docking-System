import SwiftUI

// MARK: - MCP Settings View

public struct MCPSettingsView: View {
    @StateObject private var chatManager = ChatServiceManager.shared
    @StateObject private var imageManager = ImageServiceManager.shared
    @StateObject private var audioManager = AudioServiceManager.shared
    
    @AppStorage("mcp_openai_api_key") private var storedAPIKey: String = ""
    @AppStorage("mcp_chat_model") private var storedModel: String = MCPDefaults.defaultChatModel
    
    @State private var openAIKey: String = ""
    @State private var selectedTab = 0
    
    @Environment(\.dockTheme) var theme
    @Environment(\.dismiss) var dismiss
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tabs
                Picker("Settings", selection: $selectedTab) {
                    Text("API Keys").tag(0)
                    Text("Chat").tag(1)
                    Text("Image").tag(2)
                    Text("Audio").tag(3)
                }
                .pickerStyle(.segmented)
                .padding()
                
                Divider()
                
                ScrollView {
                    VStack(spacing: 20) {
                        switch selectedTab {
                        case 0:
                            apiKeysSection
                        case 1:
                            chatSettingsSection
                        case 2:
                            imageSettingsSection
                        case 3:
                            audioSettingsSection
                        default:
                            EmptyView()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("MCP Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveSettings()
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadSettings()
            }
        }
    }
    
    // MARK: - API Keys Section
    
    private var apiKeysSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsSection(title: "OpenAI API Key", icon: "key.fill") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Required for GPT chat, DALL-E images, and Whisper audio")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        TextField("sk-...", text: $openAIKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                        
                        Button("Paste") {
                            if let clipboard = UIPasteboard.general.string {
                                openAIKey = clipboard
                            }
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                    }
                    
                    HStack {
                        Image(systemName: openAIKey.isEmpty ? "xmark.circle" : "checkmark.circle")
                            .foregroundColor(openAIKey.isEmpty ? .red : .green)
                        Text(openAIKey.isEmpty ? "Not configured" : "Configured")
                            .font(.caption)
                            .foregroundColor(openAIKey.isEmpty ? .red : .green)
                    }
                }
            }
            
            // API Usage Info
            SettingsSection(title: "API Information", icon: "info.circle") {
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(label: "Chat Model", value: chatManager.model)
                    InfoRow(label: "Image Model", value: "DALL-E 3")
                    InfoRow(label: "Audio Model", value: "TTS-1 / Whisper")
                }
            }
        }
    }
    
    // MARK: - Chat Settings
    
    private var chatSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsSection(title: "Model", icon: "cpu") {
                Picker("Model", selection: $chatManager.model) {
                    // Latest Flagships (GPT-5 Series)
                    Text("GPT-5.2").tag("gpt-5.2")
                    Text("GPT-5 mini").tag("gpt-5-mini")
                    Text("GPT-5 nano").tag("gpt-5-nano")

                    // Advanced Reasoning (o-series)
                    Text("OpenAI o3").tag("o3")
                    Text("OpenAI o4-mini").tag("o4-mini")

                    // High-Performance Multimedia & Context
                    Text("GPT-4.1").tag("gpt-4.1")
                    Text("GPT-4o (Omni)").tag("gpt-4o")
                    Text("GPT-4o mini").tag("gpt-4o-mini")

                    // Legacy / Specialized
                    Text("GPT-4 Turbo").tag("gpt-4-turbo")
                    Text("GPT-3.5 Turbo").tag("gpt-3.5-turbo")
                }
                .pickerStyle(.menu)
            }
            
            SettingsSection(title: "Agent Behavior", icon: "brain") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Auto-execute Tools", isOn: .constant(true))
                    Text("Automatically run tools when the agent suggests them")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    Toggle("Show Thinking Process", isOn: .constant(true))
                    Text("Display the agent's reasoning steps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Image Settings
    
    private var imageSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsSection(title: "Default Settings", icon: "photo") {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Default Size")
                            .font(.subheadline)
                        Picker("Size", selection: .constant("1024x1024")) {
                            Text("256×256").tag("256x256")
                            Text("512×512").tag("512x512")
                            Text("1024×1024").tag("1024x1024")
                            Text("1792×1024 (Wide)").tag("1792x1024")
                            Text("1024×1792 (Tall)").tag("1024x1792")
                        }
                        .pickerStyle(.menu)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Quality")
                            .font(.subheadline)
                        Picker("Quality", selection: .constant("standard")) {
                            Text("Standard").tag("standard")
                            Text("HD").tag("hd")
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Style")
                            .font(.subheadline)
                        Picker("Style", selection: .constant("vivid")) {
                            Text("Vivid").tag("vivid")
                            Text("Natural").tag("natural")
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
            
            SettingsSection(title: "Generated Images", icon: "photo.stack") {
                HStack {
                    Text("\(imageManager.generatedImages.count) images generated")
                        .font(.subheadline)
                    Spacer()
                    Button("Clear") {
                        imageManager.clearHistory()
                    }
                    .font(.caption)
                }
            }
        }
    }
    
    // MARK: - Audio Settings
    
    private var audioSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsSection(title: "Text-to-Speech", icon: "speaker.wave.3") {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Default Voice")
                            .font(.subheadline)
                        Picker("Voice", selection: .constant("alloy")) {
                            Text("Alloy").tag("alloy")
                            Text("Echo").tag("echo")
                            Text("Fable").tag("fable")
                            Text("Onyx").tag("onyx")
                            Text("Nova").tag("nova")
                            Text("Shimmer").tag("shimmer")
                        }
                        .pickerStyle(.menu)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Speed: 1.0x")
                            .font(.subheadline)
                        Slider(value: .constant(1.0), in: 0.25...4.0)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Output Format")
                            .font(.subheadline)
                        Picker("Format", selection: .constant("mp3")) {
                            Text("MP3").tag("mp3")
                            Text("WAV").tag("wav")
                            Text("AAC").tag("aac")
                            Text("FLAC").tag("flac")
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
            
            SettingsSection(title: "Transcription", icon: "waveform") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Default Language")
                        .font(.subheadline)
                    Picker("Language", selection: .constant("auto")) {
                        Text("Auto-detect").tag("auto")
                        Text("English").tag("en")
                        Text("Spanish").tag("es")
                        Text("French").tag("fr")
                        Text("German").tag("de")
                    }
                    .pickerStyle(.menu)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadSettings() {
        // Load from persistent storage
        openAIKey = storedAPIKey
        
        // Sync with managers
        if !storedAPIKey.isEmpty {
            chatManager.setAPIKey(storedAPIKey)
            imageManager.apiKey = storedAPIKey
            audioManager.apiKey = storedAPIKey
        }
        chatManager.model = storedModel
    }
    
    private func saveSettings() {
        // Persist to storage
        storedAPIKey = openAIKey
        storedModel = chatManager.model
        
        // Update managers
        if !openAIKey.isEmpty {
            chatManager.setAPIKey(openAIKey)
            imageManager.apiKey = openAIKey
            audioManager.apiKey = openAIKey
        }
    }
}

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    @Environment(\.dockTheme) var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.orange)
                Text(title)
                    .font(.headline)
            }
            
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.colors.secondaryBackground)
        .cornerRadius(12)
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}
