//
//  Stem_Checker_V4App.swift
//  Stem Checker V4
//
//  Created by James Ryan Wilkins on 12/09/2025.
//

import SwiftUI

@main
struct Stem_Checker_V4App: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // By using a Settings scene, we prevent the app from creating a default window.
        // This gives our AppDelegate full control over the window's lifecycle.
        Settings {
            EmptyView()
        }
    }
}
