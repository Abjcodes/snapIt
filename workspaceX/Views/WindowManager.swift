import Foundation
import Cocoa
import AppKit
import ApplicationServices

class WindowManager {
    static let shared = WindowManager()
    private init() {}
    
    func positionWindow(forItem item: WorkspaceItem) {
        // Execute window positioning on main thread
        DispatchQueue.main.async {
            self.positionApplicationWindow(item: item)
        }
    }
    
    private func positionApplicationWindow(item: WorkspaceItem) {
        let url = URL(fileURLWithPath: item.path)
        let appName = url.deletingPathExtension().lastPathComponent
        
        // Find running application
        guard let runningApp = NSWorkspace.shared.runningApplications.first(where: { app in
            return app.localizedName == appName ||
                   app.bundleURL?.deletingPathExtension().lastPathComponent == appName
        }) else {
            print("Error: Could not find running application:", appName)
            return
        }
        
        // Get the application's process identifier
        let pid = runningApp.processIdentifier
        
        // Create an AXUIElement for the application
        let appRef = AXUIElementCreateApplication(pid)
        
        // Check accessibility permissions
        var accessibilityEnabled = AXIsProcessTrusted()
        if !accessibilityEnabled {
            print("Warning: Accessibility permissions not granted")
            return
        }
        
        // Activate the app first
        runningApp.activate()
        
        // Try to get the window with improved window checking
        var retryCount = 0
        let maxRetries = 20  // Increased max retries
        let retryInterval = 0.5 // Time between retries in seconds
        
        func tryPositioningWindow() {
            // Get the application's windows
            var value: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &value)
            
            guard result == .success,
                  let windowArray = value as? [AXUIElement],
                  !windowArray.isEmpty else {
                retryCount += 1
                if retryCount < maxRetries {
                    // Retry after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + retryInterval) {
                        tryPositioningWindow()
                    }
                } else {
                    print("Error: Failed to get window for \(appName) after \(maxRetries) attempts")
                }
                return
            }
            
            // Find the first visible window
            func isWindowVisible(_ windowRef: AXUIElement) -> Bool {
                var value: CFTypeRef?
                
                // Check if window is minimized
                AXUIElementCopyAttributeValue(windowRef, kAXMinimizedAttribute as CFString, &value)
                if let minimized = value as? Bool, minimized {
                    return false
                }
                
                // Check if window has a size
                var size = CGSize.zero
                AXUIElementCopyAttributeValue(windowRef, kAXSizeAttribute as CFString, &value)
                if let sizeValue = value  {
                    AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
                    if size.width == 0 || size.height == 0 {
                        return false
                    }
                }
                
                return true
            }
            
            guard let windowRef = windowArray.first(where: { isWindowVisible($0) }) else {
                retryCount += 1
                if retryCount < maxRetries {
                    DispatchQueue.main.asyncAfter(deadline: .now() + retryInterval) {
                        tryPositioningWindow()
                    }
                } else {
                    print("Error: No visible window found for \(appName) after \(maxRetries) attempts")
                }
                return
            }
            
            // Get the frame for the desired layout
            let frame = item.layout.frame
            
            // Set position and size
            var point = CGPoint(x: frame.origin.x, y: frame.origin.y)
            var size = CGSize(width: frame.width, height: frame.height)
            
            // Convert coordinates from bottom-left to top-left
            if let screenHeight = NSScreen.main?.frame.height {
                point.y = screenHeight - (point.y + frame.height)
            }
            
            // Set position first
            if let positionValue = AXValueCreate(.cgPoint, &point) {
                AXUIElementSetAttributeValue(windowRef, kAXPositionAttribute as CFString, positionValue)
                
                // Set size after a short delay to ensure position is set
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    if let sizeValue = AXValueCreate(.cgSize, &size) {
                        AXUIElementSetAttributeValue(windowRef, kAXSizeAttribute as CFString, sizeValue)
                    }
                }
            }
        }
        
        // Start the positioning attempt after activation delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            tryPositioningWindow()
        }
    }
}

// Extension to handle AX errors
extension AXError {
    var description: String {
        switch self {
        case .success:
            return "Success"
        case .failure:
            return "Failure"
        case .illegalArgument:
            return "Illegal Argument"
        case .invalidUIElement:
            return "Invalid UI Element"
        case .invalidUIElementObserver:
            return "Invalid UI Element Observer"
        case .cannotComplete:
            return "Cannot Complete"
        case .attributeUnsupported:
            return "Attribute Unsupported"
        case .actionUnsupported:
            return "Action Unsupported"
        case .notificationUnsupported:
            return "Notification Unsupported"
        case .notImplemented:
            return "Not Implemented"
        case .notificationAlreadyRegistered:
            return "Notification Already Registered"
        case .notificationNotRegistered:
            return "Notification Not Registered"
        case .apiDisabled:
            return "API Disabled"
        case .noValue:
            return "No Value"
        case .parameterizedAttributeUnsupported:
            return "Parameterized Attribute Unsupported"
        case .notEnoughPrecision:
            return "Not Enough Precision"
        @unknown default:
            return "Unknown Error"
        }
    }
}
