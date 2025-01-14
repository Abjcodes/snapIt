//
//  workspaceXApp.swift
//  workspaceX
//
//  Created by P10 on 03/01/25.
//

import SwiftUI

@main
struct workspaceXApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        MenuBarExtra("SnapIt", systemImage: "uiwindow.split.2x1") {
            MenuBarContentView()
        }
    }
}
