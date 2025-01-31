import SwiftUI
import UniformTypeIdentifiers

struct WorkspaceDetailView: View {
    let workspace: Workspace
    @EnvironmentObject private var workspaceViewModel: WorkspaceViewModel
    @State private var sortOrder = [KeyPathComparator(\WorkspaceItem.name)]
    @State private var isShowingFileImporter = false
    @State private var isLaunching = false
    @State private var selection: Set<WorkspaceItem.ID> = []
    @State private var isInspectorPresented = false
    
    var selectedItems: [WorkspaceItem] {
        workspace.items.filter { selection.contains($0.id) }
    }
    
    var body: some View {
        HSplitView {
            VStack(spacing: 0) {
                // Toolbar
                HStack {
                    Text(workspace.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(action: { isShowingFileImporter = true }) {
                        Label("Add Items", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderless)
                }
                .padding()
                
                // Table View
                Table(workspace.items, selection: $selection, sortOrder: $sortOrder) {
                    TableColumn("Name") { item in
                        HStack(spacing: 12) {
                            Image(nsImage: getItemIcon(item))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                            
                            Text(item.name)
                                .lineLimit(1)
                        }
                    }
                    .width(min: 200, ideal: 300)
                    
                    TableColumn("Type") { item in
                        Text(item.type.displayName)
                            .foregroundColor(.secondary)
                    }
                    .width(100)
                    
                    TableColumn("Layout") { item in
                        Picker("Layout", selection: Binding(
                            get: { item.layout },
                            set: { newLayout in
                                updateItemLayout(item, newLayout)
                            }
                        )) {
                            ForEach(WindowLayout.allCases, id: \.self) { layout in
                                Text(layout.rawValue).tag(layout)
                            }
                        }
                    }
                    .width(150)
                    
                    TableColumn("Path") { item in
                        Text(item.path)
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                    }
                    .width(min: 100, ideal: 300)
                    
                    TableColumn("") { item in
                        HStack {
                            Button(action: {
                                if isWorkspaceActive {
                                    if let runningApp = NSWorkspace.shared.runningApplications.first(where: { $0.bundleURL == URL(fileURLWithPath: item.path) }) {
                                        runningApp.terminate()
                                    }
                                } else {
                                    launchItem(item)
                                }
                            }) {
                                Image(systemName: isWorkspaceActive ? "stop.circle.fill" : "play.circle.fill")
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(isWorkspaceActive ? .red : .primary)
                            }
                            .buttonStyle(.borderless)
                            
                            Button(action: { removeItem(item) }) {
                                Image(systemName: "trash.fill")
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .width(80)
                }
                .onChange(of: sortOrder) {
                    var sortedItems = workspace.items
                    sortedItems.sort(using: sortOrder)
                    workspaceViewModel.updateWorkspaceItems(workspace, items: sortedItems)
                }
            }
            
            // Inspector View
            if isInspectorPresented {
                WorkspaceInspectorView(items: selectedItems)
                    .frame(width: 300)
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .fileImporter(
            isPresented: $isShowingFileImporter,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                urls.forEach { addItem($0) }
            case .failure(let error):
                print("Error importing files: \(error.localizedDescription)")
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            providers.forEach { provider in
                _ = provider.loadObject(ofClass: URL.self) { url, error in
                    if let url = url {
                        DispatchQueue.main.async {
                            addItem(url)
                        }
                    }
                }
            }
            return true
        }
        .toolbar {
            ToolbarItemGroup {
                Button(action: {
                    if isWorkspaceActive {
                        workspaceViewModel.stopWorkspace(workspace)
                    } else {
                        launchWorkspace()
                    }
                }) {
                    Label(isWorkspaceActive ? "Stop All" : "Launch All",
                          systemImage: isWorkspaceActive ? "stop.circle.fill" : "play.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(workspace.items.isEmpty || isLaunching)
                
                Button(action: { isInspectorPresented.toggle() }) {
                    Label("Inspector", systemImage: "info.circle")
                }
                .buttonStyle(.bordered)
                .disabled(selection.isEmpty)
            }
        }
    }
    
    private func getItemIcon(_ item: WorkspaceItem) -> NSImage {
        if item.type == .application {
            return NSWorkspace.shared.icon(forFile: item.path)
        } else {
            let contentType = item.type == .folder ? UTType.folder : UTType.data
            return NSWorkspace.shared.icon(for: contentType)
        }
    }
    
    private func updateItemLayout(_ item: WorkspaceItem, _ newLayout: WindowLayout) {
        var updatedItems = workspace.items
        if let index = updatedItems.firstIndex(where: { $0.id == item.id }) {
            var updatedItem = item
            updatedItem.layout = newLayout
            updatedItems[index] = updatedItem
            workspaceViewModel.updateWorkspaceItems(workspace, items: updatedItems)
        }
    }
    
    private func addItem(_ url: URL) {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else { return }
        
        let type: WorkspaceItem.ItemType
        if url.pathExtension == "app" {
            type = .application
        } else if isDirectory.boolValue {
            type = .folder
        } else {
            type = .file
        }
        
        let item = WorkspaceItem(path: url.path, type: type)
        if !workspace.items.contains(where: { $0.path == item.path }) {
            var updatedItems = workspace.items
            updatedItems.append(item)
            workspaceViewModel.updateWorkspaceItems(workspace, items: updatedItems)
        }
    }
    
    private func removeItem(_ item: WorkspaceItem) {
        var updatedItems = workspace.items
        updatedItems.removeAll { $0.id == item.id }
        workspaceViewModel.updateWorkspaceItems(workspace, items: updatedItems)
    }
    
    private func launchWorkspace() {
        isLaunching = true
        workspaceViewModel.activeWorkspaceId = workspace.id
        
        for item in workspace.items {
            launchItem(item)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLaunching = false
        }
    }
    
    var isWorkspaceActive: Bool {
        workspaceViewModel.activeWorkspaceId == workspace.id
    }
    
    private func launchItem(_ item: WorkspaceItem) {
        let url = URL(fileURLWithPath: item.path)
        NSWorkspace.shared.open(url)
        
        if item.layout != .default {
            WindowManager.shared.positionWindow(forItem: item)
        }
    }
}

struct WorkspaceInspectorView: View {
    let items: [WorkspaceItem]
    
    var body: some View {
        List {
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.name)
                        .font(.headline)
                    
                    Text("Type: \(item.type.displayName)")
                        .foregroundColor(.secondary)
                    
                    Text("Layout: \(item.layout.rawValue)")
                        .foregroundColor(.secondary)
                    
                    Text("Path:")
                        .foregroundColor(.secondary)
                    Text(item.path)
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(3)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Configure")
    }
}

struct WorkspaceDetailView_Previews: PreviewProvider {
    static var previews: some View {
        WorkspaceDetailView(workspace: Workspace(name: "Test Workspace"))
            .environmentObject(WorkspaceViewModel())
    }
}
