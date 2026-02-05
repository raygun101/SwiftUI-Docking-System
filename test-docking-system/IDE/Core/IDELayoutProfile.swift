import Foundation
import SwiftUI
import Combine

// MARK: - Layout Profile

/// Represents a named layout configuration that can be saved and restored
public struct IDELayoutProfile: Codable, Identifiable, Equatable {
    public let id: UUID
    public var name: String
    public var icon: String
    public var panels: [LayoutPanelState]
    public var dockRegions: LayoutRegionState
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        icon: String = "rectangle.3.group",
        panels: [LayoutPanelState] = [],
        dockRegions: LayoutRegionState = .default,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.panels = panels
        self.dockRegions = dockRegions
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public static func == (lhs: IDELayoutProfile, rhs: IDELayoutProfile) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Layout Panel State

/// State of a single panel in a layout
public struct LayoutPanelState: Codable, Identifiable {
    public let id: UUID
    public var panelTypeID: String  // e.g., "editor", "preview", "explorer", "agent"
    public var descriptorID: String?  // For content panels, the ContentPanelDescriptor ID
    public var fileURL: URL?  // For document-backed panels
    public var region: LayoutRegion
    public var order: Int  // Order within the region
    public var isActive: Bool
    
    public init(
        id: UUID = UUID(),
        panelTypeID: String,
        descriptorID: String? = nil,
        fileURL: URL? = nil,
        region: LayoutRegion,
        order: Int = 0,
        isActive: Bool = false
    ) {
        self.id = id
        self.panelTypeID = panelTypeID
        self.descriptorID = descriptorID
        self.fileURL = fileURL
        self.region = region
        self.order = order
        self.isActive = isActive
    }
}

// MARK: - Layout Region

/// Identifies a region in the dock layout
public enum LayoutRegion: String, Codable, CaseIterable {
    case left
    case right
    case top
    case bottom
    case center
    case floating
}

// MARK: - Layout Region State

/// State of all dock regions (sizes, visibility)
public struct LayoutRegionState: Codable {
    public var leftWidth: CGFloat
    public var rightWidth: CGFloat
    public var topHeight: CGFloat
    public var bottomHeight: CGFloat
    public var leftVisible: Bool
    public var rightVisible: Bool
    public var topVisible: Bool
    public var bottomVisible: Bool
    
    public static let `default` = LayoutRegionState(
        leftWidth: 250,
        rightWidth: 300,
        topHeight: 200,
        bottomHeight: 200,
        leftVisible: true,
        rightVisible: true,
        topVisible: false,
        bottomVisible: true
    )
    
    public init(
        leftWidth: CGFloat = 250,
        rightWidth: CGFloat = 300,
        topHeight: CGFloat = 200,
        bottomHeight: CGFloat = 200,
        leftVisible: Bool = true,
        rightVisible: Bool = true,
        topVisible: Bool = false,
        bottomVisible: Bool = true
    ) {
        self.leftWidth = leftWidth
        self.rightWidth = rightWidth
        self.topHeight = topHeight
        self.bottomHeight = bottomHeight
        self.leftVisible = leftVisible
        self.rightVisible = rightVisible
        self.topVisible = topVisible
        self.bottomVisible = bottomVisible
    }
}

// MARK: - Built-in Layout Profiles

extension IDELayoutProfile {
    /// Default coding layout with explorer, editor, and agent panel
    public static let coding = IDELayoutProfile(
        name: "Coding",
        icon: "chevron.left.forwardslash.chevron.right",
        panels: [
            LayoutPanelState(panelTypeID: "explorer", region: .left, order: 0),
            LayoutPanelState(panelTypeID: "editor", region: .center, order: 0, isActive: true),
            LayoutPanelState(panelTypeID: "agent", region: .right, order: 0)
        ],
        dockRegions: LayoutRegionState(
            leftWidth: 250,
            rightWidth: 320,
            leftVisible: true,
            rightVisible: true,
            bottomVisible: false
        )
    )
    
    /// Preview-focused layout with side-by-side editor and preview
    public static let preview = IDELayoutProfile(
        name: "Preview",
        icon: "globe",
        panels: [
            LayoutPanelState(panelTypeID: "explorer", region: .left, order: 0),
            LayoutPanelState(panelTypeID: "editor", region: .center, order: 0, isActive: true),
            LayoutPanelState(panelTypeID: "preview", region: .right, order: 0)
        ],
        dockRegions: LayoutRegionState(
            leftWidth: 220,
            rightWidth: 400,
            leftVisible: true,
            rightVisible: true,
            bottomVisible: false
        )
    )
    
    /// Focused layout with just the editor
    public static let focused = IDELayoutProfile(
        name: "Focused",
        icon: "rectangle.center.inset.filled",
        panels: [
            LayoutPanelState(panelTypeID: "editor", region: .center, order: 0, isActive: true)
        ],
        dockRegions: LayoutRegionState(
            leftVisible: false,
            rightVisible: false,
            topVisible: false,
            bottomVisible: false
        )
    )
}

// MARK: - Layout Profile Manager

/// Manages layout profiles for a project
@MainActor
public final class IDELayoutManager: ObservableObject {
    @Published public private(set) var profiles: [IDELayoutProfile] = []
    @Published public var activeProfileID: UUID?
    
    private let projectURL: URL
    private let profilesFileName = ".ide-layouts.json"
    
    public init(projectURL: URL) {
        self.projectURL = projectURL
        loadProfiles()
    }
    
    // MARK: - Profile Management
    
    public var activeProfile: IDELayoutProfile? {
        profiles.first { $0.id == activeProfileID }
    }
    
    public func createProfile(name: String, basedOn profile: IDELayoutProfile? = nil) -> IDELayoutProfile {
        var newProfile = profile ?? .coding
        newProfile = IDELayoutProfile(
            name: name,
            icon: newProfile.icon,
            panels: newProfile.panels,
            dockRegions: newProfile.dockRegions
        )
        profiles.append(newProfile)
        saveProfiles()
        return newProfile
    }
    
    public func updateProfile(_ profile: IDELayoutProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            var updated = profile
            updated.updatedAt = Date()
            profiles[index] = updated
            saveProfiles()
        }
    }
    
    public func deleteProfile(_ profileID: UUID) {
        profiles.removeAll { $0.id == profileID }
        if activeProfileID == profileID {
            activeProfileID = profiles.first?.id
        }
        saveProfiles()
    }
    
    public func switchToProfile(_ profileID: UUID) {
        guard profiles.contains(where: { $0.id == profileID }) else { return }
        activeProfileID = profileID
        saveProfiles()
        
        // Notify observers of layout change
        NotificationCenter.default.post(
            name: .layoutProfileDidChange,
            object: self,
            userInfo: ["profileID": profileID]
        )
    }
    
    // MARK: - Persistence
    
    private var profilesFileURL: URL {
        projectURL.appendingPathComponent(profilesFileName)
    }
    
    private func loadProfiles() {
        guard FileManager.default.fileExists(atPath: profilesFileURL.path) else {
            // Initialize with default profiles
            profiles = [.coding, .preview, .focused]
            activeProfileID = profiles.first?.id
            return
        }
        
        do {
            let data = try Data(contentsOf: profilesFileURL)
            let decoded = try JSONDecoder().decode(LayoutProfilesStorage.self, from: data)
            profiles = decoded.profiles
            activeProfileID = decoded.activeProfileID ?? profiles.first?.id
        } catch {
            print("[IDELayoutManager] Failed to load profiles: \(error)")
            profiles = [.coding, .preview, .focused]
            activeProfileID = profiles.first?.id
        }
    }
    
    private func saveProfiles() {
        let storage = LayoutProfilesStorage(
            profiles: profiles,
            activeProfileID: activeProfileID
        )
        
        do {
            let data = try JSONEncoder().encode(storage)
            try data.write(to: profilesFileURL, options: .atomic)
        } catch {
            print("[IDELayoutManager] Failed to save profiles: \(error)")
        }
    }
    
    /// Capture current dock state into a profile (placeholder - requires DockLayout integration)
    public func captureCurrentLayout(as name: String, panels: [LayoutPanelState] = [], regionState: LayoutRegionState = .default) -> IDELayoutProfile {
        let profile = IDELayoutProfile(
            name: name,
            panels: panels,
            dockRegions: regionState
        )
        
        profiles.append(profile)
        saveProfiles()
        return profile
    }
}

// MARK: - Storage Model

private struct LayoutProfilesStorage: Codable {
    let profiles: [IDELayoutProfile]
    let activeProfileID: UUID?
}

// MARK: - Notifications

extension Notification.Name {
    static let layoutProfileDidChange = Notification.Name("layoutProfileDidChange")
}
