import SwiftUI

// MARK: - Dock Toolbar Scaffold

/// Wraps toolbar content with consistent spacing, padding, and alignment so every dock panel header uses the same layout.
public struct DockToolbarScaffold<Leading: View, Trailing: View>: View {
    private let leadingContent: () -> Leading
    private let trailingContent: () -> Trailing
    
    @Environment(\.dockTheme) private var theme
    
    public init(
        @ViewBuilder leading: @escaping () -> Leading,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.leadingContent = leading
        self.trailingContent = trailing
    }
    
    public var body: some View {
        HStack(alignment: .center, spacing: 10) {
            HStack(spacing: 6, content: leadingContent)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
            
            Spacer(minLength: 6)
                .layoutPriority(0)
            
            HStack(spacing: 6, content: trailingContent)
                .fixedSize(horizontal: true, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, theme.spacing.headerPadding * 0.65)
        .padding(.vertical, max(theme.spacing.headerPadding - 6, 4))
    }
}

public extension DockToolbarScaffold where Trailing == EmptyView {
    init(@ViewBuilder leading: @escaping () -> Leading) {
        self.init(leading: leading, trailing: { EmptyView() })
    }
}

public extension DockToolbarScaffold where Leading == EmptyView {
    init(@ViewBuilder trailing: @escaping () -> Trailing) {
        self.init(leading: { EmptyView() }, trailing: trailing)
    }
}

// MARK: - Icon Button

/// Compact icon-only button for toolbar actions, keeping controls consistent and space efficient.
public struct DockToolbarIconButton: View {
    public enum Role {
        case normal
        case accent
        case destructive
    }
    
    private let systemName: String
    private let accessibilityLabel: String
    private let role: Role
    private let isActive: Bool
    private let action: () -> Void
    
    @Environment(\.dockTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    
    public init(
        _ systemName: String,
        accessibilityLabel: String,
        role: Role = .normal,
        isActive: Bool = false,
        action: @escaping () -> Void
    ) {
        self.systemName = systemName
        self.accessibilityLabel = accessibilityLabel
        self.role = role
        self.isActive = isActive
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 26, height: 26)
                .foregroundColor(foregroundColor)
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadii.button, style: .continuous)
                        .fill(backgroundColor)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
    
    private var foregroundColor: Color {
        guard isEnabled else { return theme.colors.tertiaryText.opacity(0.8) }
        switch role {
        case .accent:
            return isActive ? theme.colors.panelBackground : theme.colors.accent
        case .destructive:
            return isActive ? theme.colors.panelBackground : Color.red.opacity(0.9)
        case .normal:
            return isActive ? theme.colors.panelBackground : theme.colors.text
        }
    }
    
    private var backgroundColor: Color {
        guard isEnabled else { return theme.colors.secondaryBackground.opacity(0.25) }
        switch role {
        case .accent:
            return isActive ? theme.colors.accent : theme.colors.accent.opacity(0.18)
        case .destructive:
            return isActive ? Color.red.opacity(0.85) : Color.red.opacity(0.14)
        case .normal:
            return isActive ? theme.colors.text.opacity(0.85) : theme.colors.secondaryBackground.opacity(0.55)
        }
    }
}

// MARK: - Chip / Badge

/// Lightweight chip used for contextual information, such as the active document name or status.
public struct DockToolbarChip: View {
    private let icon: String?
    private let title: String
    private let subtitle: String?
    
    @Environment(\.dockTheme) private var theme
    
    public init(icon: String? = nil, title: String, subtitle: String? = nil) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
    }
    
    public var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(theme.colors.accent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(theme.colors.text)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(theme.colors.tertiaryText)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(theme.colors.tertiaryBackground)
        .clipShape(Capsule())
    }
}
