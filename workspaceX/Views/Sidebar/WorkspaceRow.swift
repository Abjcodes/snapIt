import SwiftUI

struct WorkspaceActionDialog: View {
    let workspace: Workspace
    let onRename: (String) -> Void
    let onDelete: () -> Void
    @Binding var isPresented: Bool
    @State private var workspaceName: String
    @State private var showingDeleteConfirmation = false
    @EnvironmentObject private var viewModel: WorkspaceViewModel
    
    init(workspace: Workspace, isPresented: Binding<Bool>, onRename: @escaping (String) -> Void, onDelete: @escaping () -> Void) {
        self.workspace = workspace
        self._isPresented = isPresented
        self.onRename = onRename
        self.onDelete = onDelete
        _workspaceName = State(initialValue: workspace.name)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Edit Workspace")
                    .font(.title3.bold())
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Name Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Name")
                            .font(.headline)
                        TextField("Workspace Name", text: $workspaceName)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Delete Section
                    VStack(spacing: 12) {
                        Divider()
                        
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete Workspace", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
            
            // Bottom Bar
            HStack {
                Spacer()
                Button("Save") {
                    if !workspaceName.isEmpty {
                        onRename(workspaceName)
                    }
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(workspaceName.isEmpty)
            }
            .padding()
        }
        .padding()
        .frame(width: 300)
        .alert("Delete Workspace", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
                isPresented = false
            }
        } message: {
            Text("Are you sure you want to delete this workspace? This action cannot be undone.")
        }
    }
}

struct WorkspaceRow: View {
    let workspace: Workspace
    let isEditing: Bool
    let onStartEditing: () -> Void
    let onRename: (String) -> Void
    let onDelete: () -> Void
    @Binding var selectedWorkspace: Workspace?
    @State private var showingActionDialog = false
    
    var body: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: workspace.icon)
                    .font(.system(size: 20))
                    .foregroundColor(.accentColor)
                    .frame(width: 24, height: 24)
                Text(workspace.name)
                    .lineLimit(1)
                    .font(.body)
                Spacer()
                Button {
                    showingActionDialog = true
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
        }
        .contentShape(Rectangle())
        .frame(height: 32)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(selectedWorkspace?.id == workspace.id ?
                      Color.accentColor.opacity(0.2) : Color.clear)
        )
        .onTapGesture {
            if !isEditing {
                selectedWorkspace = workspace
            }
        }
        .sheet(isPresented: $showingActionDialog) {
            WorkspaceActionDialog(
                workspace: workspace,
                isPresented: $showingActionDialog,
                onRename: onRename,
                onDelete: onDelete
            )
        }
    }
}
