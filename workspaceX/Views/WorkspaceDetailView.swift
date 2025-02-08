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
                
                // Window Preview
                VStack {
                    Text("Window Layout Preview")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    GeometryReader { geometry in
                        ZStack {
                            // Desktop Wallpaper Background
                            if let screen = NSScreen.main,
                               let wallpaperURL = NSWorkspace.shared.desktopImageURL(for: screen),
                               let wallpaperImage = NSImage(contentsOf: wallpaperURL) {
                                Image(nsImage: wallpaperImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            
                            // Window previews
                            ForEach(workspace.items) { item in
                                let frame = getWindowFrame(for: item.layout, in: geometry.size)
                                WindowPreviewItem(item: item)
                                    .frame(width: frame.width, height: frame.height)
                                    .position(x: frame.minX + frame.width/2, y: frame.minY + frame.height/2)
                            }
                        }
                    }
                    .frame(width: 300, height: 300)
                    .background(Color(NSColor.windowBackgroundColor).opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.bottom)
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
                    
                    TableColumn("URL") { item in
                        if isBrowserApp(item.path) {
                            TextField("Enter URL", text: Binding(
                                get: { item.url ?? "" },
                                set: { updateItemURL(item, $0) }
                            ))
                        } else {
                            Text("")
                        }
                    }
                    .width(200)
                    
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
    
    private func isBrowserApp(_ path: String) -> Bool {
        let browserBundles = ["com.google.Chrome", "com.apple.Safari", "org.mozilla.firefox"]
        if let bundle = Bundle(path: path)?.bundleIdentifier {
            return browserBundles.contains(bundle)
        }
        return false
    }
    
    private func updateItemURL(_ item: WorkspaceItem, _ newURL: String) {
        var updatedItems = workspace.items
        if let index = updatedItems.firstIndex(where: { $0.id == item.id }) {
            var updatedItem = item
            updatedItem.url = newURL.isEmpty ? nil : newURL
            updatedItems[index] = updatedItem
            workspaceViewModel.updateWorkspaceItems(workspace, items: updatedItems)
        }
    }
    
    private func launchItem(_ item: WorkspaceItem) {
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
    
    private func getPreviewPosition(_ layout: WindowLayout, size: CGSize) -> CGPoint {
        let width = size.width
        let height = size.height
        let margin: CGFloat = 20
        let itemWidth: CGFloat = 60
        let itemHeight: CGFloat = 30
        
        let availableWidth = width - margin * 2
        let availableHeight = height - margin * 2
        
        let centerX = width / 2
        let centerY = height / 2
        
        let leftX = margin + itemWidth/2
        let rightX = width - margin - itemWidth/2
        let topY = margin + itemHeight/2
        let bottomY = height - margin - itemHeight/2
        
        switch layout {
        case .default:
            return CGPoint(x: centerX, y: centerY)
        case .leftHalf:
            return CGPoint(x: leftX + availableWidth/4, y: centerY)
        case .rightHalf:
            return CGPoint(x: rightX - availableWidth/4, y: centerY)
        case .topHalf:
            return CGPoint(x: centerX, y: topY + availableHeight/4)
        case .bottomHalf:
            return CGPoint(x: centerX, y: bottomY - availableHeight/4)
        case .leftOneThird:
            return CGPoint(x: leftX + availableWidth/6, y: centerY)
        case .rightOneThird:
            return CGPoint(x: rightX - availableWidth/6, y: centerY)
        case .middleOneThird:
            return CGPoint(x: centerX, y: centerY)
        case .leftTwoThirds:
            return CGPoint(x: leftX + availableWidth/3, y: centerY)
        case .rightTwoThirds:
            return CGPoint(x: rightX - availableWidth/3, y: centerY)
        case .topLeftQuarter:
            return CGPoint(x: leftX + availableWidth/4, y: topY + availableHeight/4)
        case .bottomLeftQuarter:
            return CGPoint(x: leftX + availableWidth/4, y: bottomY - availableHeight/4)
        case .topRightQuarter:
            return CGPoint(x: rightX - availableWidth/4, y: topY + availableHeight/4)
        case .bottomRightQuarter:
            return CGPoint(x: rightX - availableWidth/4, y: bottomY - availableHeight/4)
        case .topLeftSixth:
            return CGPoint(x: leftX + availableWidth/6, y: topY + availableHeight/4)
        case .topMiddleSixth:
            return CGPoint(x: centerX, y: topY + availableHeight/4)
        case .topRightSixth:
            return CGPoint(x: rightX - availableWidth/6, y: topY + availableHeight/4)
        case .bottomLeftSixth:
            return CGPoint(x: leftX + availableWidth/6, y: bottomY - availableHeight/4)
        case .bottomMiddleSixth:
            return CGPoint(x: centerX, y: bottomY - availableHeight/4)
        case .bottomRightSixth:
            return CGPoint(x: rightX - availableWidth/6, y: bottomY - availableHeight/4)
        }
    }
    
    struct WindowPreviewItem: View {
        let item: WorkspaceItem
        
        var body: some View {
            VStack(spacing: 2) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: item.path))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                Text(item.name)
                    .font(.system(size: 8))
                    .lineLimit(1)
            }
            .padding(4)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(NSColor.windowBackgroundColor)
                        .opacity(0.8))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
        }
    }
    
    private func getWindowFrame(for layout: WindowLayout, in size: CGSize) -> CGRect {
        let width = size.width
        let height = size.height
        
        // Helper function to create frame without margins
        func createFrame(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) -> CGRect {
            let frameWidth = w * width
            let frameHeight = h * height
            let frameX = x * width
            let frameY = (1 - y - h) * height // Flip Y coordinate system
            
            return CGRect(
                x: frameX,
                y: frameY,
                width: frameWidth,
                height: frameHeight
            )
        }
        
        switch layout {
        case .default:
            return createFrame(x: 0.25, y: 0.25, w: 0.5, h: 0.5)
        case .leftHalf:
            return createFrame(x: 0, y: 0, w: 0.5, h: 1)
        case .rightHalf:
            return createFrame(x: 0.5, y: 0, w: 0.5, h: 1)
        case .topHalf:
            return createFrame(x: 0, y: 0.5, w: 1, h: 0.5)
        case .bottomHalf:
            return createFrame(x: 0, y: 0, w: 1, h: 0.5)
        case .leftOneThird:
            return createFrame(x: 0, y: 0, w: 0.33, h: 1)
        case .rightOneThird:
            return createFrame(x: 0.67, y: 0, w: 0.33, h: 1)
        case .middleOneThird:
            return createFrame(x: 0.33, y: 0, w: 0.34, h: 1)
        case .leftTwoThirds:
            return createFrame(x: 0, y: 0, w: 0.67, h: 1)
        case .rightTwoThirds:
            return createFrame(x: 0.33, y: 0, w: 0.67, h: 1)
        case .topLeftQuarter:
            return createFrame(x: 0, y: 0.5, w: 0.5, h: 0.5)
        case .bottomLeftQuarter:
            return createFrame(x: 0, y: 0, w: 0.5, h: 0.5)
        case .topRightQuarter:
            return createFrame(x: 0.5, y: 0.5, w: 0.5, h: 0.5)
        case .bottomRightQuarter:
            return createFrame(x: 0.5, y: 0, w: 0.5, h: 0.5)
        case .topLeftSixth:
            return createFrame(x: 0, y: 0.5, w: 0.33, h: 0.5)
        case .topMiddleSixth:
            return createFrame(x: 0.33, y: 0.5, w: 0.34, h: 0.5)
        case .topRightSixth:
            return createFrame(x: 0.67, y: 0.5, w: 0.33, h: 0.5)
        case .bottomLeftSixth:
            return createFrame(x: 0, y: 0, w: 0.33, h: 0.5)
        case .bottomMiddleSixth:
            return createFrame(x: 0.33, y: 0, w: 0.34, h: 0.5)
        case .bottomRightSixth:
            return createFrame(x: 0.67, y: 0, w: 0.33, h: 0.5)
        }
    }
}
