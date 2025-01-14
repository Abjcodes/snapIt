//
//  ContentView.swift
//  workspaceX
//
//  Created by P10 on 03/01/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = WorkspaceViewModel()

    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel)
                .environmentObject(viewModel)
        } detail: {
            if let selectedWorkspace = viewModel.selectedWorkspace {
                WorkspaceDetailView(workspace: selectedWorkspace)
                    .environmentObject(viewModel)
            } else {
                Text("Select a workspace")
                    .font(.title)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    ContentView()
}
