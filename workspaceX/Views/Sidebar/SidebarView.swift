import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: WorkspaceViewModel
    @State private var editingWorkspace: Workspace?
    @State private var filterText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var filteredWorkspaces: [Workspace] {
        if filterText.isEmpty {
            return viewModel.workspaces
        }
        return viewModel.workspaces.filter { $0.name.localizedCaseInsensitiveContains(filterText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            List {
                Section(header: Text("Workspaces")) {
                    ForEach(filteredWorkspaces) { workspace in
                        WorkspaceRow(
                            workspace: workspace,
                            isEditing: editingWorkspace == workspace,
                            onStartEditing: {
                                editingWorkspace = workspace
                            },
                            onRename: { newName in
                                viewModel.renameWorkspace(workspace, to: newName)
                                editingWorkspace = nil
                            },
                            onDelete: {
                                viewModel.deleteWorkspace(workspace)
                            },
                            selectedWorkspace: $viewModel.selectedWorkspace
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .headerProminence(.increased)
            .listStyle(.sidebar)
            
            Divider()
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Filter workspaces...", text: $filterText)
                        .textFieldStyle(.plain)
                        .focused($isTextFieldFocused)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.quaternary)
                        .opacity(0.5)
                )
                .padding(.horizontal)
                
                Button(action: { viewModel.addWorkspace() }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("New Workspace")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
            .padding(.vertical, 12)
        }
    }
}

// NSVisualEffectView wrapper for native macOS materials
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }
    
    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}
