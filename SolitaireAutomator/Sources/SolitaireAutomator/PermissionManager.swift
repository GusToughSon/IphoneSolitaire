import Foundation
@preconcurrency import Cocoa
import ScreenCaptureKit

/// Manages macOS permissions required for the automator.
enum PermissionManager {
    
    /// Checks if the app has Accessibility permissions.
    @MainActor static func checkAccessibility() -> Bool {
        Log.debug("Checking Accessibility permissions...")
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessSync = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if accessSync {
            Log.info("Accessibility permissions: GRANTED")
        } else {
            Log.warn("Accessibility permissions: DENIED (Prompting user)")
        }
        return accessSync
    }
    
    /// Checks if the app has Screen Recording permissions.
    static func checkScreenRecording() async -> Bool {
        Log.debug("Checking Screen Recording permissions...")
        do {
            // We try to get shareable content. If it fails or returns no windows, permissions might be missing.
            _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            Log.info("Screen Recording permissions: GRANTED")
            return true
        } catch {
            Log.error("Screen Recording permissions check failed: \(error.localizedDescription)")
            Log.warn("Screen Recording permissions: DENIED (Usually requires a restart of the app after granting in System Settings)")
            return false
        }
    }
}
