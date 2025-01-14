import SwiftUI

struct WorkspaceRow: View {
    let workspace: Workspace
    let isEditing: Bool
    let onStartEditing: () -> Void
    let onRename: (String) -> Void
    let onDelete: () -> Void
    @Binding var selectedWorkspace: Workspace?
    
    @State private var editingName: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            if isEditing {
                TextField("Workspace Name", text: $editingName)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .onAppear {
                        editingName = workspace.name
                        isFocused = true
                    }
                    .onSubmit {
                        submitRename()
                    }
                    .onChange(of: isFocused) { oldValue, newValue in
                        if !newValue {
                            submitRename()
                        }
                    }
            } else {
                HStack {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.accentColor)
                        .frame(width: 24, height: 24)
                    Text(workspace.name)
                        .lineLimit(1)
                        .font(.body)
                    Spacer()
                    Menu {
                        Button("Rename") {
                            onStartEditing()
                            editingName = workspace.name
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            onDelete()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                }
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
    }
    
    private func submitRename() {
        if !editingName.isEmpty && editingName != workspace.name {
            onRename(editingName)
        }
    }
}
