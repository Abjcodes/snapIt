//
//  MenuBarContentView.swift
//  workspaceX
//
//  Created by P10 on 14/01/25.
//

import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject private var viewModel: WorkspaceViewModel
    
    var body: some View {
        Group {
            if viewModel.workspaces.isEmpty {
                Text("No workspaces found")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(viewModel.workspaces) { workspace in
                    WorkspaceMenuItem(workspace: workspace)
                }
                
                Divider()
            }
            
            Button("Open Workspace X") {
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        .padding(.vertical, 4)
    }
}

struct WorkspaceMenuItem: View {
    let workspace: Workspace
    
    var body: some View {
        Button {
            launchWorkspace(workspace)
        } label: {
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundColor(.accentColor)
                Text(workspace.name)            }
            .contentShape(Rectangle())
        }
    }
    
    private func launchWorkspace(_ workspace: Workspace) {
        for item in workspace.items {
            let url = URL(fileURLWithPath: item.path)
            NSWorkspace.shared.open(url)
            
            if item.layout != .default {
                WindowManager.shared.positionWindow(forItem: item)
            }
        }
    }
}

#Preview {
    MenuBarContentView()
}
