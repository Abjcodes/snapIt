import Foundation

struct Workspace: Identifiable, Equatable, Hashable, Codable {
    let id: UUID
    var name: String
    var items: [WorkspaceItem]
    var icon: String = "folder"
    
    init(id: UUID = UUID(), name: String, items: [WorkspaceItem] = [], icon: String = "folder") {
        self.id = id
        self.name = name
        self.items = items
        self.icon = icon
    }
}

struct WorkspaceItem: Identifiable, Hashable, Codable {
    let id: UUID
    let path: String
    let type: ItemType
    let name: String
    var layout: WindowLayout = .default
    var url: String?  // Optional URL for browser applications
    
    enum ItemType: String, Codable {
        case file
        case folder
        case application
        
        var displayName: String {
            switch self {
            case .application: return "Application"
            case .folder: return "Folder"
            case .file: return "File"
            }
        }
    }
    
    init(path: String, type: ItemType, layout: WindowLayout = .default) {
        self.id = UUID()
        self.path = path
        self.type = type
        self.name = (path as NSString).lastPathComponent
        self.layout = layout
    }
}
