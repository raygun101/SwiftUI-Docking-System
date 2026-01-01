//
//  test_docking_systemApp.swift
//  test-docking-system
//
//  Created by Leslie Godwin on 2025/12/26.
//

import SwiftUI

@main
struct test_docking_systemApp: App {
    @StateObject private var themeManager: ThemeManager
    
    init() {
        ThemePresets.registerAll()
        _themeManager = StateObject(wrappedValue: ThemeManager())
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
        }
    }
}
