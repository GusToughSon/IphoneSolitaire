import Foundation
import ScreenCaptureKit
import VideoToolbox

/// Handles the detection and monitoring of the iPhone Mirroring window.
@MainActor
class MirroringEngine: NSObject {
    static let shared = MirroringEngine()
    
    private let targetOwnerName = "iPhone Mirroring"
    private let targetWindowName = "iPhone Mirroring"
    
    private var stream: SCStream?
    private(set) var lastFrame: CGImage?
    private var isStreaming = false
    
    private override init() {
        super.init()
    }
    
    /// Finds the iPhone Mirroring window among active windows.
    func findMirroringWindow() async -> SCWindow? {
        Log.debug("Scanning for '\(targetOwnerName)' window...")
        
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            let windows = content.windows
            
            Log.debug("Found \(windows.count) on-screen windows total.")
            
            for window in windows {
                let ownerName = window.owningApplication?.applicationName ?? "Unknown"
                let windowTitle = window.title ?? "Untitled"
                
                // Verbose logging of window scan
                Log.debug("Checking window: [Owner: \(ownerName)] [Title: \(windowTitle)]")
                
                if ownerName == targetOwnerName && windowTitle == targetWindowName {
                    Log.action("Found matching iPhone Mirroring window! [ID: \(window.windowID)]")
                    focusMirroringWindow()
                    return window
                }
            }
            
            Log.warn("iPhone Mirroring window NOT found. Is it open?")
            return nil
            
        } catch {
            Log.error("Failed to fetch shareable content: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Monitors the window's existence and frame, and starts streaming.
    func startMonitoring() {
        Log.info("Starting mirroring engine monitor loop...")
        Task {
            while true {
                if let window = await findMirroringWindow() {
                    let frame = window.frame
                    Log.debug("Live Window Status: Active at (\(frame.origin.x), \(frame.origin.y)) Size: \(frame.size.width)x\(frame.size.height)")
                    
                    // Check for "Danger Zone" (off-screen or behind menu bar)
                    checkWindowSafety(frame)
                    
                    if !isStreaming {
                        await setupStream(for: window)
                    }
                }
                
                // Sleep for 2 seconds between checks for existence
                try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
            }
        }
    }
    
    /// Brings the iPhone Mirroring application to the front.
    private func focusMirroringWindow() {
        let apps = NSWorkspace.shared.runningApplications
        if let mirroringApp = apps.first(where: { $0.localizedName == targetOwnerName }) {
            Log.action("Focusing '\(targetOwnerName)' application...")
            
            // Bring to front with force
            mirroringApp.activate(options: [.activateIgnoringOtherApps])
            
            // Second pass for reliability in command-line environments
            if !mirroringApp.isActive {
                Log.debug("Initial focus attempt slow, retrying...")
                mirroringApp.activate(options: [.activateIgnoringOtherApps])
            }
        }
    }
    
    private func checkWindowSafety(_ frame: CGRect) {
        // Simple heuristic: Y < 25 is often behind the menu bar
        if frame.origin.y < 25 {
            Log.warn("⚠️ WINDOW DANGER ZONE: The Mirroring window is partially off-screen or behind the menu bar (Y: \(Int(frame.origin.y))). Clicks may be unreliable!")
            Log.info("Action: Please move the iPhone Mirroring window down into a clear area on your screen.")
        }
    }
    
    private func setupStream(for window: SCWindow) async {
        guard !isStreaming else { return }
        
        Log.info("Setting up SCStream for iPhone Mirroring...")
        
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let config = SCStreamConfiguration()
        
        // Configuration for Vision processing
        config.width = Int(window.frame.width)
        config.height = Int(window.frame.height)
        config.minimumFrameInterval = CMTime(value: 1, timescale: 10) // 10 FPS
        config.queueDepth = 5
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.showsCursor = false
        
        do {
            stream = SCStream(filter: filter, configuration: config, delegate: nil)
            try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: .global(qos: .userInteractive))
            try await stream?.startCapture()
            
            isStreaming = true
            Log.info("SCStream started successfully.")
        } catch {
            Log.error("Failed to start SCStream: \(error.localizedDescription)")
        }
    }
}

extension MirroringEngine: @preconcurrency SCStreamOutput {
    nonisolated func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen else { return }
        
        guard let pixelBuffer = sampleBuffer.imageBuffer else { return }
        
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
        
        if let image = cgImage {
            Task { @MainActor in
                self.lastFrame = image
                VisionScanner.shared.scan(image: image)
            }
        }
    }
}
