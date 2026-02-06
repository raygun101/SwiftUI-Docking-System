import SwiftUI
import Combine
import UIKit

// MARK: - Agent Chat Style

fileprivate struct AgentChatStyle {
    let background: Color
    let surface: Color
    let elevatedSurface: Color
    let accent: Color
    let accentSoft: Color
    let border: Color
    let textPrimary: Color
    let textSecondary: Color
    let bubbleUser: Color
    let bubbleAssistant: Color
    let userAvatarBackground: Color
    let assistantAvatarBackground: Color
    let chipBackground: Color
    let chipForeground: Color
    let shadow: Color
    let error: Color
    
    static var fallback: AgentChatStyle {
        AgentChatStyle(
            background: Color.black.opacity(0.85),
            surface: Color(.secondarySystemBackground).opacity(0.9),
            elevatedSurface: Color(.secondarySystemBackground),
            accent: Color.purple,
            accentSoft: Color.purple.opacity(0.15),
            border: Color.white.opacity(0.08),
            textPrimary: .white,
            textSecondary: .gray,
            bubbleUser: Color.purple.opacity(0.25),
            bubbleAssistant: Color.white.opacity(0.07),
            userAvatarBackground: Color.blue.opacity(0.85),
            assistantAvatarBackground: Color.purple.opacity(0.85),
            chipBackground: Color.purple.opacity(0.12),
            chipForeground: Color.purple,
            shadow: Color.black.opacity(0.35),
            error: Color.red.opacity(0.9)
        )
    }
    
    static func fromTheme(_ theme: DockThemeProtocol) -> AgentChatStyle {
        let colors = theme.colors
        let accent = colors.accent
        return AgentChatStyle(
            background: colors.panelBackground,
            surface: colors.secondaryBackground.opacity(0.92),
            elevatedSurface: colors.hoverBackground.opacity(0.95),
            accent: accent,
            accentSoft: accent.opacity(0.15),
            border: colors.border.opacity(0.35),
            textPrimary: colors.text,
            textSecondary: colors.secondaryText,
            bubbleUser: accent.opacity(0.18),
            bubbleAssistant: colors.secondaryBackground,
            userAvatarBackground: accent,
            assistantAvatarBackground: colors.accentSecondary,
            chipBackground: accent.opacity(0.12),
            chipForeground: accent,
            shadow: colors.shadowColor.opacity(0.4),
            error: colors.accentSecondary
        )
    }
}

fileprivate struct AgentChatStyleKey: EnvironmentKey {
    static let defaultValue: AgentChatStyle = .fallback
}

fileprivate extension EnvironmentValues {
    var agentChatStyle: AgentChatStyle {
        get { self[AgentChatStyleKey.self] }
        set { self[AgentChatStyleKey.self] = newValue }
    }
}

// MARK: - Agent Surface

private struct AgentSurface<Content: View>: View {
    @Environment(\.agentChatStyle) private var style
    let padding: CGFloat
    let spacing: CGFloat
    let content: Content
    
    init(padding: CGFloat = 14, spacing: CGFloat = 12, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            content
        }
        .padding(padding)
        .background(style.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(style.border, lineWidth: 1)
        )
    }
}

// MARK: - Agent Status Badge

private struct AgentStatusBadge: View {
    @Environment(\.agentChatStyle) private var style
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(style.accentSoft)
        .foregroundColor(style.accent)
        .clipShape(Capsule())
    }
}

// MARK: - Attachment Menu

private struct AttachmentMenu: View {
    @Environment(\.agentChatStyle) private var style
    let actionImage: () -> Void
    let actionFile: () -> Void
    let actionCode: () -> Void
    
    var body: some View {
        Menu {
            Button(action: actionImage) {
                Label("Image", systemImage: "photo")
            }
            Button(action: actionFile) {
                Label("File", systemImage: "doc")
            }
            Button(action: actionCode) {
                Label("Code Selection", systemImage: "curlybraces")
            }
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundColor(style.textSecondary)
        }
    }
}

// MARK: - Agent Chat Panel View

public struct AgentChatView: View {
    @Environment(\.dockTheme) private var theme
    @StateObject private var agent = MCPAgent.shared
    @StateObject private var chatManager = ChatServiceManager.shared
    @StateObject private var voiceService = VoiceChatService.shared
    @State private var inputText: String = ""
    @State private var isExpanded: Bool = true
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @FocusState private var isInputFocused: Bool
    
    public init() {}
    
    public var body: some View {
        let style = AgentChatStyle.fromTheme(theme)
        return VStack(spacing: 12) {
            heroHeader(style: style)
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: agent.isProcessing)
            
            AgentSurface {
                conversationView
            }
            .animation(.easeInOut, value: agent.messages.count)
            
            if !agent.suggestions.isEmpty && !agent.isProcessing {
                SuggestionsBar(suggestions: agent.suggestions, onTap: executeSuggestion)
            }
            
            AgentSurface {
                inputArea(style: style)
            }
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [style.background.opacity(0.95), style.background.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(style.border, lineWidth: 1)
        )
        .shadow(color: style.shadow, radius: 20, y: 10)
        .environment(\.agentChatStyle, style)
        .alert("Error", isPresented: $showError) {
            Button("Settings") {
                openSettings()
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onChange(of: agent.error) { oldValue, newValue in
            if let error = newValue {
                errorMessage = error.message
                showError = true
            }
        }
    }
    
    // MARK: - Header

    private func heroHeader(style: AgentChatStyle) -> some View {
        AgentSurface(padding: 18, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Label {
                        Text("AI Agent")
                            .font(.headline)
                            .foregroundColor(style.textPrimary)
                    } icon: {
                        Image(systemName: "sparkles")
                            .foregroundColor(style.accent)
                    }
                    .labelStyle(.titleAndIcon)
                    
                    Text("An autonomous co-creator ready to explore ideas, scaffold projects, and generate assets for you.")
                        .font(.footnote)
                        .foregroundColor(style.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer(minLength: 8)
                
                VStack(alignment: .trailing, spacing: 8) {
                    if agent.isProcessing {
                        AgentStatusBadge(title: "Thinking", icon: "brain.head.profile")
                    } else {
                        AgentStatusBadge(title: "Ready", icon: "bolt.fill")
                    }
                    
                    Menu {
                        Button(role: .destructive, action: { agent.clearHistory() }) {
                            Label("Clear Chat", systemImage: "trash")
                        }
                        Divider()
                        Toggle("Auto-execute Tools", isOn: $agent.autoExecuteTools)
                        Toggle("Show Thinking", isOn: $agent.showThinking)
                        Divider()
                        Button(action: openSettings) {
                            Label("Settings", systemImage: "gear")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundColor(style.textSecondary)
                    }
                }
            }
        }
    }

    private var conversationView: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(groupedMessages) { group in
                            switch group {
                            case .single(let message):
                                MessageBubble(message: message, onSuggestionTap: executeSuggestion)
                                    .id(message.id)
                            case .toolGroup(let messages):
                                CollapsibleToolGroup(messages: messages)
                                    .id(messages.first?.id ?? UUID())
                            }
                        }
                        
                        if !agent.streamingContent.isEmpty {
                            StreamingBubble(content: agent.streamingContent)
                        }
                        
                        Color.clear.frame(height: 1).id("bottom-anchor")
                    }
                    .padding(.vertical, 4)
                }
                .onChange(of: agent.messages.count) { _, _ in
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo("bottom-anchor", anchor: .bottom)
                    }
                }
                .onChange(of: agent.streamingContent) { _, _ in
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("bottom-anchor", anchor: .bottom)
                    }
                }
            }
            
            // Pinned progress bar at bottom of conversation
            if agent.isProcessing || !agent.pendingToolCalls.isEmpty {
                AgentProgressView(
                    isProcessing: agent.isProcessing,
                    isThinking: agent.isThinking,
                    currentThought: agent.currentThought,
                    toolCalls: agent.pendingToolCalls
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: agent.isProcessing)
            }
        }
    }
    
    // MARK: - Message Grouping
    
    private enum MessageGroup: Identifiable {
        case single(AgentMessage)
        case toolGroup([AgentMessage])
        
        var id: UUID {
            switch self {
            case .single(let msg): return msg.id
            case .toolGroup(let msgs): return msgs.first?.id ?? UUID()
            }
        }
    }
    
    private var groupedMessages: [MessageGroup] {
        var groups: [MessageGroup] = []
        var pendingToolMessages: [AgentMessage] = []
        
        for message in agent.messages {
            if message.role == .tool {
                pendingToolMessages.append(message)
            } else {
                if !pendingToolMessages.isEmpty {
                    groups.append(.toolGroup(pendingToolMessages))
                    pendingToolMessages = []
                }
                groups.append(.single(message))
            }
        }
        if !pendingToolMessages.isEmpty {
            groups.append(.toolGroup(pendingToolMessages))
        }
        return groups
    }
    
    // MARK: - Input Area
    
    private func inputArea(style: AgentChatStyle) -> some View {
        VStack(spacing: 6) {
            // Live transcript indicator
            if voiceService.isListening {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .opacity(voiceService.isListening ? 1 : 0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: voiceService.isListening)
                    
                    Text(voiceService.liveTranscript.isEmpty ? "Listening..." : voiceService.liveTranscript)
                        .font(.system(size: 12))
                        .foregroundColor(style.textSecondary)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    Button(action: { voiceService.stopListening() }) {
                        Text("Done")
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(style.accent)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            
            HStack(spacing: 12) {
                AttachmentMenu(actionImage: attachImage, actionFile: attachFile, actionCode: attachCode)
                    .foregroundColor(style.textSecondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    TextField(
                        "Guide the agent...",
                        text: $inputText,
                        axis: .vertical
                    )
                    .textFieldStyle(.plain)
                    .lineLimit(1...4)
                    .focused($isInputFocused)
                    .padding(.vertical, 6)
                    .foregroundStyle(style.textPrimary)
                    .placeholder(when: inputText.isEmpty && !voiceService.isListening) {
                        Text("Guide the agent...")
                            .foregroundColor(style.textSecondary)
                    }
                    .onSubmit {
                        sendMessage()
                    }
                    
                    Rectangle()
                        .fill(style.border)
                        .frame(height: 1)
                }
                
                // Microphone button
                Button(action: toggleVoiceInput) {
                    Image(systemName: voiceService.isListening ? "mic.fill" : "mic")
                        .font(.title3)
                        .foregroundStyle(voiceService.isListening ? Color.red : style.textSecondary)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(voiceService.isListening ? Color.red.opacity(0.15) : style.accentSoft.opacity(0.5))
                        )
                }
                .buttonStyle(.plain)
                
                // Send button
                Button(action: sendMessage) {
                    Image(systemName: agent.isProcessing ? "stop.fill" : "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(
                            inputText.isEmpty && !agent.isProcessing
                            ? style.textSecondary.opacity(0.4)
                            : style.accent
                        )
                        .padding(6)
                        .background(
                            Circle()
                                .fill(style.accentSoft)
                                .opacity(inputText.isEmpty && !agent.isProcessing ? 0.4 : 1)
                        )
                }
                .disabled(inputText.isEmpty && !agent.isProcessing)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: voiceService.isListening)
    }
    
    // MARK: - Actions
    
    private func sendMessage() {
        if agent.isProcessing {
            agent.stop()
            return
        }
        
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Ensure API key is configured
        if chatManager.apiKey.isEmpty {
            errorMessage = "No API key configured. Please add your OpenAI API key in Settings."
            showError = true
            return
        }
        
        let message = inputText
        inputText = ""
        
        Task {
            await agent.send(message)
        }
    }
    
    private func executeSuggestion(_ suggestion: AgentSuggestion) {
        Task {
            await agent.executeSuggestion(suggestion)
        }
    }
    
    private func toggleVoiceInput() {
        if voiceService.isListening {
            voiceService.stopListening()
        } else {
            voiceService.startListening { transcript in
                // Put transcribed text into input or send directly
                if inputText.isEmpty {
                    inputText = transcript
                } else {
                    inputText += " " + transcript
                }
                // Auto-send if API key is configured
                if !chatManager.apiKey.isEmpty {
                    sendMessage()
                }
            }
        }
    }
    
    private func attachImage() {
        // Implement image attachment
    }
    
    private func attachFile() {
        // Implement file attachment
    }
    
    private func attachCode() {
        // Attach current code selection
    }
    
    private func openSettings() {
        AgentActions.showSettings()
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: AgentMessage
    let onSuggestionTap: (AgentSuggestion) -> Void
    
    @Environment(\.agentChatStyle) private var style
    
    private var stackAlignment: HorizontalAlignment {
        message.role == .user ? .trailing : .leading
    }
    
    private var frameAlignment: Alignment {
        message.role == .user ? .trailing : .leading
    }
    
    private var textAlignment: TextAlignment {
        message.role == .user ? .trailing : .leading
    }
    
    private var showsAvatar: Bool {
        message.role != .system
    }
    
    var body: some View {
        VStack(alignment: stackAlignment, spacing: 6) {
            if showsAvatar {
                avatarView
            }
            
            contentView
                .frame(maxWidth: .infinity, alignment: frameAlignment)
            
            if !message.suggestions.isEmpty {
                VStack(spacing: 4) {
                    ForEach(message.suggestions) { suggestion in
                        SuggestionButton(suggestion: suggestion, onTap: { onSuggestionTap(suggestion) })
                    }
                }
            }
            
            timestampView
        }
        .frame(maxWidth: .infinity, alignment: frameAlignment)
    }
    
    @ViewBuilder
    private var avatarView: some View {
        Circle()
            .fill(message.role == .user ? style.userAvatarBackground : style.assistantAvatarBackground)
            .frame(width: 28, height: 28)
            .overlay {
                Image(systemName: message.role == .user ? "person.fill" : "sparkles")
                    .font(.caption)
                    .foregroundColor(.white)
            }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch message.content {
        case .text(let text):
            AgentMarkdownView(
                text: text,
                textColor: style.textPrimary,
                accentColor: style.accent,
                alignment: textAlignment
            )
            .padding(12)
            .background(
                message.role == .user
                    ? style.bubbleUser
                    : style.bubbleAssistant
            )
            .cornerRadius(16)
            .cornerRadius(message.role == .user ? 16 : 4, corners: message.role == .user ? [.bottomRight] : [.bottomLeft])
            
        case .toolResult(let result):
            ToolResultView(result: result)
            
        case .thinking(let thought):
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.7)
                Text(thought)
                    .font(.caption)
                    .foregroundColor(style.textSecondary)
            }
            .padding(8)
            .background(style.surface.opacity(0.8))
            .cornerRadius(8)
            
        case .image(let data):
            if let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 200)
                    .cornerRadius(12)
            }
            
        case .audio:
            AudioPlayerView()
            
        case .compound(let contents):
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(contents.enumerated()), id: \.offset) { _, content in
                    CompoundContentView(content: content)
                }
            }
        }
    }
    
    private var timestampView: some View {
        Text(message.timestamp, style: .time)
            .font(.caption2)
            .foregroundColor(style.textSecondary.opacity(0.7))
            .frame(maxWidth: .infinity, alignment: frameAlignment)
    }
}

// MARK: - Markdown Rendering

private struct AgentMarkdownView: View {
    let text: String
    let textColor: Color
    let accentColor: Color
    let alignment: TextAlignment
    var autoCloseCodeBlocks: Bool = false
    
    private var processedText: String {
        autoCloseCodeBlocks ? MarkdownParser.autoClosedCodeBlocks(text) : text
    }
    
    private var blocks: [MarkdownBlock] {
        MarkdownParser.parse(processedText)
    }
    
    private var horizontalAlignment: HorizontalAlignment {
        switch alignment {
        case .trailing: return .trailing
        case .center: return .center
        default: return .leading
        }
    }
    
    private var frameAlignment: Alignment {
        switch alignment {
        case .trailing: return .trailing
        case .center: return .center
        default: return .leading
        }
    }
    
    var body: some View {
        VStack(alignment: horizontalAlignment, spacing: 10) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
        .frame(maxWidth: .infinity, alignment: frameAlignment)
    }
    
    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let value):
            richText(value)
                .font(fontForHeading(level))
                .fontWeight(level <= 2 ? .semibold : .medium)
                .foregroundColor(textColor)
        case .paragraph(let value):
            richText(value)
        case .orderedList(let items):
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(index + 1).")
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundColor(accentColor)
                        richText(item)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: frameAlignment)
        case .unorderedList(let items):
            VStack(alignment: .leading, spacing: 6) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Circle()
                            .fill(accentColor.opacity(0.8))
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                        richText(item)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: frameAlignment)
        case .blockquote(let value):
            HStack(alignment: .top, spacing: 12) {
                Rectangle()
                    .fill(accentColor.opacity(0.4))
                    .frame(width: 3)
                    .cornerRadius(2)
                richText(value)
                    .foregroundColor(textColor.opacity(0.9))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(textColor.opacity(0.08))
            .cornerRadius(10)
        case .code(let language, let code):
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 6) {
                    if let language, !language.isEmpty {
                        Text(language.uppercased())
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(accentColor)
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(code)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .foregroundColor(textColor)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(textColor.opacity(0.12))
                .cornerRadius(12)
                
                CopyCodeButton(code: code, accentColor: accentColor)
                    .padding(8)
            }
        case .divider:
            Rectangle()
                .fill(textColor.opacity(0.15))
                .frame(height: 1)
        }
    }
    
    private func richText(_ value: String) -> some View {
        let attributed = (try? AttributedString(
            markdown: value,
            options: .init(
                interpretedSyntax: .full,
                failurePolicy: .returnPartiallyParsedIfPossible
            )
        )) ?? AttributedString(value)
        return Text(attributed)
            .foregroundColor(textColor)
            .multilineTextAlignment(alignment)
            .lineSpacing(4)
            .textSelection(.enabled)
    }
    
    private func fontForHeading(_ level: Int) -> Font {
        switch level {
        case 1: return .system(size: 20, weight: .semibold)
        case 2: return .system(size: 18, weight: .semibold)
        case 3: return .system(size: 16, weight: .semibold)
        default: return .system(size: 15, weight: .medium)
        }
    }
}

private enum MarkdownBlock: Hashable {
    case heading(level: Int, text: String)
    case paragraph(String)
    case orderedList([String])
    case unorderedList([String])
    case code(language: String?, code: String)
    case blockquote(String)
    case divider
}

private enum MarkdownParser {
    static func autoClosedCodeBlocks(_ text: String) -> String {
        var sanitized = text
        let fences = ["```", "'''"]
        for fence in fences {
            let count = sanitized.components(separatedBy: fence).count - 1
            if count % 2 != 0 {
                sanitized += "\n\(fence)"
            }
        }
        return sanitized
    }
    
    static func parse(_ text: String) -> [MarkdownBlock] {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        let lines = normalized.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var blocks: [MarkdownBlock] = []
        var index = 0
        var paragraphBuffer: [String] = []
        
        func flushParagraph() {
            let sentence = paragraphBuffer.joined(separator: " ").trimmingCharacters(in: .whitespaces)
            if !sentence.isEmpty {
                blocks.append(.paragraph(sentence))
            }
            paragraphBuffer.removeAll()
        }
        
        while index < lines.count {
            let currentLine = lines[index]
            let trimmed = currentLine.trimmingCharacters(in: .whitespaces)
            
            if trimmed.isEmpty {
                flushParagraph()
                index += 1
                continue
            }
            
            if trimmed.hasPrefix("```") {
                flushParagraph()
                let language = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                index += 1
                var codeLines: [String] = []
                while index < lines.count {
                    let line = lines[index]
                    if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                        index += 1
                        break
                    }
                    codeLines.append(line)
                    index += 1
                }
                blocks.append(.code(language: language.isEmpty ? nil : language, code: codeLines.joined(separator: "\n")))
                continue
            }
            
            if trimmed.hasPrefix("#") {
                flushParagraph()
                let level = min(trimmed.prefix { $0 == "#" }.count, 4)
                let content = trimmed.drop { $0 == "#" }.drop(while: { $0 == " " })
                blocks.append(.heading(level: level, text: String(content)))
                index += 1
                continue
            }
            
            if let ordered = parseOrderedList(from: lines, startIndex: &index) {
                flushParagraph()
                blocks.append(.orderedList(ordered))
                continue
            }
            
            if let unordered = parseUnorderedList(from: lines, startIndex: &index) {
                flushParagraph()
                blocks.append(.unorderedList(unordered))
                continue
            }
            
            if trimmed.hasPrefix(">") {
                flushParagraph()
                var quoteLines: [String] = []
                while index < lines.count {
                    let line = lines[index].trimmingCharacters(in: .whitespaces)
                    guard line.hasPrefix(">") else { break }
                    quoteLines.append(String(line.dropFirst().trimmingCharacters(in: .whitespaces)))
                    index += 1
                }
                blocks.append(.blockquote(quoteLines.joined(separator: " ")))
                continue
            }
            
            if trimmed == "---" || trimmed == "***" {
                flushParagraph()
                blocks.append(.divider)
                index += 1
                continue
            }
            
            paragraphBuffer.append(trimmed)
            index += 1
        }
        
        flushParagraph()
        return blocks.isEmpty ? [.paragraph(text)] : blocks
    }
    
    private static func parseOrderedList(from lines: [String], startIndex: inout Int) -> [String]? {
        var tempIndex = startIndex
        var items: [String] = []
        while tempIndex < lines.count {
            let trimmed = lines[tempIndex].trimmingCharacters(in: .whitespaces)
            guard let dotIndex = trimmed.firstIndex(of: "."), dotIndex != trimmed.startIndex else { break }
            let prefix = trimmed[..<dotIndex]
            guard Int(prefix) != nil else { break }
            let afterDotIndex = trimmed.index(after: dotIndex)
            guard afterDotIndex < trimmed.endIndex, trimmed[afterDotIndex] == " " else { break }
            let content = trimmed[trimmed.index(after: afterDotIndex)...].trimmingCharacters(in: .whitespaces)
            items.append(String(content))
            tempIndex += 1
            if tempIndex < lines.count {
                let nextTrimmed = lines[tempIndex].trimmingCharacters(in: .whitespaces)
                if nextTrimmed.isEmpty { tempIndex += 1; break }
                if nextTrimmed.firstIndex(of: ".") == nil { break }
            }
        }
        guard !items.isEmpty else { return nil }
        startIndex = tempIndex
        return items
    }
    
    private static func parseUnorderedList(from lines: [String], startIndex: inout Int) -> [String]? {
        var tempIndex = startIndex
        var items: [String] = []
        while tempIndex < lines.count {
            let trimmed = lines[tempIndex].trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") else { break }
            let content = trimmed.dropFirst(2).trimmingCharacters(in: .whitespaces)
            items.append(String(content))
            tempIndex += 1
            if tempIndex < lines.count {
                let nextTrimmed = lines[tempIndex].trimmingCharacters(in: .whitespaces)
                if nextTrimmed.isEmpty { tempIndex += 1; break }
                if !(nextTrimmed.hasPrefix("- ") || nextTrimmed.hasPrefix("* ")) { break }
            }
        }
        guard !items.isEmpty else { return nil }
        startIndex = tempIndex
        return items
    }
}

// MARK: - Streaming Bubble

struct StreamingBubble: View {
    let content: String
    
    @Environment(\.agentChatStyle) private var style
    
    private var processedContent: String {
        MarkdownParser.autoClosedCodeBlocks(content)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Circle()
                .fill(style.assistantAvatarBackground)
                .frame(width: 28, height: 28)
                .overlay {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            
            AgentMarkdownView(
                text: processedContent,
                textColor: style.textPrimary,
                accentColor: style.accent,
                alignment: .leading,
                autoCloseCodeBlocks: true
            )
            .padding(12)
            .background(style.bubbleAssistant)
            .cornerRadius(16)
            .overlay(alignment: .bottomLeading) {
                RetroCursorView(color: style.accent)
                    .padding(.leading, 6)
                    .padding(.bottom, 6)
            }
        }
    }
}

// MARK: - Copy Button & Cursor

private struct CopyCodeButton: View {
    let code: String
    let accentColor: Color
    @State private var copied = false
    
    var body: some View {
        Button {
            UIPasteboard.general.string = code
            copied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                copied = false
            }
        } label: {
            Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(accentColor.opacity(0.18))
                .foregroundColor(accentColor)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct RetroCursorView: View {
    let color: Color
    @State private var isVisible: Bool = true
    private let timer = Timer.publish(every: 0.55, on: .main, in: .common).autoconnect()
    
    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(color)
            .frame(width: 6, height: 16)
            .opacity(isVisible ? 1 : 0.15)
            .onReceive(timer) { _ in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isVisible.toggle()
                }
            }
    }
}

// MARK: - Agent Progress View

struct AgentProgressView: View {
    let isProcessing: Bool
    let isThinking: Bool
    let currentThought: String
    let toolCalls: [ToolCall]
    
    @Environment(\.agentChatStyle) private var style
    @State private var phase: CGFloat = 0
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()
    
    private var progressStep: Double {
        guard isProcessing else { return 1 }
        let completed = toolCalls.filter { $0.status == .completed }.count
        let total = max(toolCalls.count, 1)
        return Double(completed) / Double(total) + (toolCalls.isEmpty ? 0.15 : 0.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ProgressCircle(progress: progressStep)
                    .frame(width: 36, height: 36)
                    .foregroundColor(style.accent)
                    .animation(.easeInOut(duration: 0.4), value: progressStep)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(statusTitle)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(style.textPrimary)
                    
                    if isThinking {
                        Text(currentThought.isEmpty ? "Thinking" : currentThought)
                            .font(.caption)
                            .foregroundColor(style.textSecondary)
                            .lineLimit(2)
                    } else if let running = toolCalls.first(where: { $0.status == .running }) {
                        Text("Running \(running.toolID)...")
                            .font(.caption)
                            .foregroundColor(style.textSecondary)
                    }
                }
                
                Spacer()
                
                if isProcessing {
                    HStack(spacing: 4) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(style.accent)
                                .frame(width: 4, height: 4)
                                .opacity(dotOpacity(for: index))
                        }
                    }
                    .onReceive(timer) { _ in
                        phase = (phase + 1).truncatingRemainder(dividingBy: 3)
                    }
                }
            }
            .padding(12)
            .background(style.surface)
            .cornerRadius(12)
            
            if !toolCalls.isEmpty {
                VStack(spacing: 8) {
                    ForEach(toolCalls) { call in
                        ToolCallProgressRow(call: call)
                    }
                }
            }
        }
    }
    
    private var statusTitle: String {
        if !toolCalls.isEmpty {
            let completed = toolCalls.filter { $0.status == .completed }.count
            return "Executing \(toolCalls.count) tasks (\(completed)/\(toolCalls.count))"
        }
        if isThinking { return "Thinking" }
        return "Working"
    }
    
    private func dotOpacity(for index: Int) -> Double {
        Double(index) == Double(Int(phase)) ? 1 : 0.3
    }
}

private struct ProgressCircle: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 4)
            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

private struct ToolCallProgressRow: View {
    let call: ToolCall
    @Environment(\.agentChatStyle) private var style
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(call.toolID)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(style.textPrimary)
                if let result = call.result, case .error(let error) = result {
                    Text(error.message)
                        .font(.caption2)
                        .foregroundColor(style.error)
                }
            }
            
            Spacer()
            
            if call.status == .running {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
        .padding(10)
        .background(style.surface.opacity(0.6))
        .cornerRadius(8)
    }
    
    private var statusIcon: String {
        switch call.status {
        case .pending: return "clock"
        case .running: return "gearshape"
        case .completed: return "checkmark.circle"
        case .failed: return "exclamationmark.triangle"
        }
    }
    
    private var statusColor: Color {
        switch call.status {
        case .pending: return .gray
        case .running: return .orange
        case .completed: return .green
        case .failed: return style.accent
        }
    }
}

// MARK: - Collapsible Tool Group

struct CollapsibleToolGroup: View {
    let messages: [AgentMessage]
    @Environment(\.agentChatStyle) private var style
    @State private var isExpanded = false
    
    private var summary: String {
        let count = messages.count
        let successCount = messages.filter { msg in
            if case .toolResult(let result) = msg.content, result.isSuccess { return true }
            return false
        }.count
        let failCount = count - successCount
        
        if failCount > 0 {
            return "\(count) tool \(count == 1 ? "action" : "actions") (\(successCount) ok, \(failCount) failed)"
        }
        return "\(count) tool \(count == 1 ? "action" : "actions") completed"
    }
    
    private var toolNames: String {
        let names = messages.compactMap { $0.toolCalls?.first?.toolID }
        let unique = Array(Set(names))
        return unique.prefix(3).joined(separator: ", ") + (unique.count > 3 ? "..." : "")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Collapsed summary header
            Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { isExpanded.toggle() } }) {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.2")
                        .font(.system(size: 12))
                        .foregroundColor(style.accent)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(summary)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(style.textPrimary)
                        if !toolNames.isEmpty {
                            Text(toolNames)
                                .font(.system(size: 10))
                                .foregroundColor(style.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(style.textSecondary)
                }
                .padding(10)
                .background(style.surface.opacity(0.7))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(style.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            
            // Expanded detail
            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(messages) { message in
                        toolMessageRow(message)
                    }
                }
                .padding(.top, 6)
                .padding(.leading, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    @ViewBuilder
    private func toolMessageRow(_ message: AgentMessage) -> some View {
        let toolName = message.toolCalls?.first?.toolID ?? "tool"
        let isSuccess: Bool = {
            if case .toolResult(let result) = message.content { return result.isSuccess }
            return false
        }()
        
        HStack(spacing: 8) {
            Image(systemName: isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 11))
                .foregroundColor(isSuccess ? .green : .red)
            
            Text(toolName)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(style.textPrimary)
            
            Spacer()
            
            Text(message.timestamp, style: .time)
                .font(.system(size: 10))
                .foregroundColor(style.textSecondary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(style.surface.opacity(0.4))
        .cornerRadius(6)
    }
}

// MARK: - Tool Result View

struct ToolResultView: View {
    let result: ToolResult
    
    @Environment(\.agentChatStyle) private var style
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch result {
            case .success(let output):
                outputView(output)
                
            case .error(let error):
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(style.accent)
                    Text(error.message)
                        .foregroundColor(style.textPrimary)
                }
                .padding(8)
                .background(style.accentSoft)
                .cornerRadius(8)
                
            case .streaming:
                ProgressView()
            }
        }
    }
    
    @ViewBuilder
    private func outputView(_ output: ToolOutput) -> some View {
        switch output {
        case .text(let text), .markdown(let text):
            Text(text)
                .foregroundColor(style.textPrimary)
                .padding(8)
                .background(style.surface)
                .cornerRadius(8)
        
        case .code(let code, let language):
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(language.uppercased())
                        .font(.caption2)
                        .foregroundColor(style.textSecondary)
                    Spacer()
                    Button(action: { copyToClipboard(code) }) {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                    }
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(code)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(style.textPrimary)
                        .padding(8)
                }
            }
            .padding(8)
            .background(style.surface.opacity(0.8))
            .cornerRadius(8)
            
        case .image(let data, _):
            if let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 200)
                    .cornerRadius(8)
            }
            
        case .file(let url):
            HStack {
                Image(systemName: "doc.fill")
                    .foregroundColor(style.accent)
                Text(url.lastPathComponent)
                    .foregroundColor(style.textPrimary)
            }
            .padding(8)
            .background(style.surface)
            .cornerRadius(8)
            
        default:
            EmptyView()
        }
    }
    
    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
    }
}

// MARK: - Suggestions Bar

struct SuggestionsBar: View {
    let suggestions: [AgentSuggestion]
    let onTap: (AgentSuggestion) -> Void
    @Environment(\.agentChatStyle) private var style
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions) { suggestion in
                    SuggestionChip(suggestion: suggestion, onTap: { onTap(suggestion) })
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(style.surface)
    }
}

struct SuggestionChip: View {
    let suggestion: AgentSuggestion
    let onTap: () -> Void
    @Environment(\.agentChatStyle) private var style
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: suggestion.icon)
                    .font(.caption)
                Text(suggestion.title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(style.chipBackground)
            .foregroundColor(style.chipForeground)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct SuggestionButton: View {
    let suggestion: AgentSuggestion
    let onTap: () -> Void
    
    @Environment(\.agentChatStyle) private var style
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: suggestion.icon)
                    .foregroundColor(style.accent)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(style.textPrimary)
                    Text(suggestion.description)
                        .font(.caption2)
                        .foregroundColor(style.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(style.textSecondary)
            }
            .padding(10)
            .background(style.surface)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Compound Content View

struct CompoundContentView: View {
    let content: AgentMessage.MessageContent
    
    @Environment(\.agentChatStyle) private var style
    
    var body: some View {
        switch content {
        case .text(let text):
            Text(text)
                .foregroundColor(style.textPrimary)
        case .image(let data):
            if let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 150)
                    .cornerRadius(8)
            }
        default:
            EmptyView()
        }
    }
}

// MARK: - Audio Player View

struct AudioPlayerView: View {
    @State private var isPlaying = false
    @Environment(\.agentChatStyle) private var style
    
    var body: some View {
        HStack {
            Button(action: { isPlaying.toggle() }) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(style.accent)
            }
            
            // Waveform visualization placeholder
            HStack(spacing: 2) {
                ForEach(0..<20) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(style.accent.opacity(0.5))
                        .frame(width: 3, height: CGFloat.random(in: 8...24))
                }
            }
            
            Text("0:00")
                .font(.caption)
                .foregroundColor(style.textSecondary)
        }
        .padding(8)
        .background(style.accentSoft)
        .cornerRadius(12)
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    @ViewBuilder
    func placeholder<Content: View>(when shouldShow: Bool, alignment: Alignment = .leading, @ViewBuilder content: () -> Content) -> some View {
        ZStack(alignment: alignment) {
            if shouldShow { content() }
            self
        }
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
