import Foundation
import Cocoa

@main
@MainActor
struct SolitaireAutomator {
    static func main() {
        // 0. Force CoreGraphics Initialization to prevent CGS_REQUIRE_INIT crash
        _ = CGDisplayBounds(CGMainDisplayID())
        
        Log.info("=== iPhone Solitaire Automator Starting ===")
        Log.debug("System Architecture: \(ProcessInfo.processInfo.machineName)")
        
        // 1. Setup Escape Key Listener (Emergency Stop)
        setupEscapeKeyListener()
        
        // 2. Start the core logic in a Task
        Task {
            // Check Permissions
            let hasAccess = PermissionManager.checkAccessibility()
            let hasScreen = await PermissionManager.checkScreenRecording()
            
            guard hasAccess && hasScreen else {
                Log.error("Missing required permissions. Please grant them in System Settings > Privacy & Security.")
                Log.info("Note: Accessibility is for clicking, Screen Recording is for seeing the game.")
                exit(1)
            }
            
            Log.info("Starting Core Engine...")
            MirroringEngine.shared.startMonitoring()
            
            Log.debug("Core Engine is running in the background.")
        }
        
        // 3. Start the OS event loop to process NSEvent monitors
        // This will block the main thread and keep the app alive.
        Log.debug("Starting Main Event Loop (NSEvent monitors active).")
        NSApplication.shared.run()
    }
    
    /// Listens for the Escape key (keycode 53) globally to terminate the app.
    static func setupEscapeKeyListener() {
        Log.debug("Setting up Emergency Stop (Global Esc key listener)...")
        
        // Global monitor (works even if app is in background)
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 {
                Log.info("Emergency Stop: Escape key pressed (Global). Exiting...")
                exit(0)
            }
        }
        
        // Local monitor (works if app is frontmost)
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 {
                Log.info("Emergency Stop: Escape key pressed (Local). Exiting...")
                exit(0)
            }
            return event
        }
    }
}

extension ProcessInfo {
    var machineName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}
