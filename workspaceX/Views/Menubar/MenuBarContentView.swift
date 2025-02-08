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
    @EnvironmentObject private var viewModel: WorkspaceViewModel
    
    var isActive: Bool {
        viewModel.activeWorkspaceId == workspace.id
    }
    
    var body: some View {
        Button {
            if isActive {
                viewModel.stopWorkspace(workspace)
            } else {
                launchWorkspace(workspace)
            }
        } label: {
            HStack {
                Image(systemName: isActive ? "stop.circle.fill" : workspace.icon)
                    .foregroundColor(isActive ? .red : .accentColor)
                Text(workspace.name)
                if isActive {
                    Image(systemName: workspace.icon)
                        .foregroundColor(.accentColor)
                    Text(workspace.name)
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                } else {
                    Image(systemName: workspace.icon)
                        .foregroundColor(.accentColor)
                    Text(workspace.name)
                }
            }
            .contentShape(Rectangle())
        }
    }
    
    private func launchWorkspace(_ workspace: Workspace) {
        viewModel.activeWorkspaceId = workspace.id
        for item in workspace.items {
            if isBrowserApp(item.path) && item.url != nil {
                let browserURL = URL(fileURLWithPath: item.path)
                let config = NSWorkspace.OpenConfiguration()
                
                // Format the URL properly for browser launch
                var urlString = item.url!
                if !urlString.lowercased().hasPrefix("http://") && !urlString.lowercased().hasPrefix("https://") {
                    urlString = "https://" + urlString
                }
                
                // Handle Safari differently
                if let bundleId = Bundle(path: item.path)?.bundleIdentifier,
                   bundleId == "com.apple.Safari" {
                    if let url = URL(string: urlString) {
                        NSWorkspace.shared.open([url],
                                                withApplicationAt: browserURL,
                                                configuration: config)
                    }
                } else {
                    config.arguments = [urlString]
                    NSWorkspace.shared.openApplication(at: browserURL, configuration: config)
                }
            } else {
                let url = URL(fileURLWithPath: item.path)
                NSWorkspace.shared.open(url)
            }
            
            if item.layout != .default {
                WindowManager.shared.positionWindow(forItem: item)
            }
        }
    }
    
    private func isBrowserApp(_ path: String) -> Bool {
        let browserBundles = ["com.google.Chrome", "com.apple.Safari", "org.mozilla.firefox"]
        if let bundle = Bundle(path: path)?.bundleIdentifier {
            return browserBundles.contains(bundle)
        }
        return false
    }
    }


#Preview {
    MenuBarContentView()
}
