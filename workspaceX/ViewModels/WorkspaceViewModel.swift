import SwiftUI

class WorkspaceViewModel: ObservableObject {
    @Published var workspaces: [Workspace] {
        didSet {
            saveWorkspaces()
        }
    }
    @Published var selectedWorkspace: Workspace? {
        didSet {
            if let workspace = selectedWorkspace {
                UserDefaults.standard.set(workspace.id.uuidString, forKey: "selectedWorkspaceId")
            } else {
                UserDefaults.standard.removeObject(forKey: "selectedWorkspaceId")
            }
        }
    }
    @Published var activeWorkspaceId: UUID? {
        didSet {
            if let id = activeWorkspaceId {
                UserDefaults.standard.set(id.uuidString, forKey: "activeWorkspaceId")
            } else {
                UserDefaults.standard.removeObject(forKey: "activeWorkspaceId")
            }
        }
    }
    
    private let workspacesKey = "savedWorkspaces"
    
    init() {
        if let data = UserDefaults.standard.data(forKey: workspacesKey),
           let decodedWorkspaces = try? JSONDecoder().decode([Workspace].self, from: data) {
            self.workspaces = decodedWorkspaces
            if let selectedId = UserDefaults.standard.string(forKey: "selectedWorkspaceId"),
               let uuid = UUID(uuidString: selectedId),
               let workspace = decodedWorkspaces.first(where: { $0.id == uuid }) {
                self.selectedWorkspace = workspace
            } else {
                self.selectedWorkspace = nil
            }
        } else {
            self.workspaces = []
            self.selectedWorkspace = nil
        }
    }
    
    private func saveWorkspaces() {
        if let encoded = try? JSONEncoder().encode(workspaces) {
            UserDefaults.standard.set(encoded, forKey: workspacesKey)
        }
    }
    
    func addWorkspace() {
        let newWorkspace = Workspace(name: "New Workspace")
        workspaces.append(newWorkspace)
        selectedWorkspace = newWorkspace
    }
    
    func deleteWorkspace(_ workspace: Workspace) {
        if selectedWorkspace == workspace {
            selectedWorkspace = nil
        }
        workspaces.removeAll { $0.id == workspace.id }
    }
    
    func renameWorkspace(_ workspace: Workspace, to newName: String) {
        if let index = workspaces.firstIndex(where: { $0.id == workspace.id }) {
            var updatedWorkspace = workspace
            updatedWorkspace.name = newName
            workspaces[index] = updatedWorkspace
            
            if selectedWorkspace?.id == workspace.id {
                selectedWorkspace = updatedWorkspace
            }
        }
    }
    
    func updateWorkspaceItems(_ workspace: Workspace, items: [WorkspaceItem]) {
        if let index = workspaces.firstIndex(where: { $0.id == workspace.id }) {
            var updatedWorkspace = workspace
            updatedWorkspace.items = items
            workspaces[index] = updatedWorkspace
            
            if selectedWorkspace?.id == workspace.id {
                selectedWorkspace = updatedWorkspace
            }
        }
    }
    
    func stopWorkspace(_ workspace: Workspace) {
        if activeWorkspaceId == workspace.id {
            for item in workspace.items {
                if item.type == .application {
                    let url = URL(fileURLWithPath: item.path)
                    if let runningApp = NSWorkspace.shared.runningApplications.first(where: { $0.bundleURL == url }) {
                        runningApp.terminate()
                    }
                }
            }
            activeWorkspaceId = nil
        }
    }
}
