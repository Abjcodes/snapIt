//
//  workspaceXApp.swift
//  workspaceX
//
//  Created by P10 on 03/01/25.
//

import SwiftUI

@main
struct workspaceXApp: App {
    @StateObject private var workspaceViewModel = WorkspaceViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(workspaceViewModel)
        }
        MenuBarExtra("SnapIt", systemImage: "uiwindow.split.2x1") {
            MenuBarContentView()
                .environmentObject(workspaceViewModel)
        }
    }
}
