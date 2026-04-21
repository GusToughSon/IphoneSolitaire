import Foundation
import CoreGraphics

/// Handles the simulation of touch events on the iPhone Mirroring window via macOS mouse events.
@MainActor
class InputSimulator {
    static let shared = InputSimulator()
    
    private init() {}
    
    /// Clicks a point relative to the iPhone Mirroring window's origin.
    /// - Parameter point: The coordinate relative to the window (e.g., 100, 200).
    func click(at point: CGPoint) {
        Task { @MainActor in
            guard let window = await MirroringEngine.shared.findMirroringWindow() else {
                Log.error("InputSimulator: Cannot click. Window 'iPhone Mirroring' not found.")
                return
            }
            
            // Mirroring window coordinates are in screen space
            let frame = window.frame
            let screenPoint = CGPoint(
                x: frame.origin.x + point.x,
                y: frame.origin.y + point.y
            )
            
            Log.action("InputSimulator: Sending click to Screen(\(Int(screenPoint.x)), \(Int(screenPoint.y))) [Rel: \(Int(point.x)), \(Int(point.y))]")
            
            performClick(at: screenPoint)
        }
    }
    
    /// Performs a physical click at the given screen-space point.
    private func performClick(at point: CGPoint) {
        let source = CGEventSource(stateID: .combinedSessionState)
        
        guard let mouseDown = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left),
              let mouseUp = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left) else {
            Log.error("InputSimulator: Failed to create CGEvent")
            return
        }
        
        // Post events to the system
        mouseDown.post(tap: .cghidEventTap)
        
        // Brief pause to simulate a real human tap
        usleep(100_000) // 100ms
        
        mouseUp.post(tap: .cghidEventTap)
    }
    
    /// Simulated swipe from start to end (relative to window).
    func swipe(from start: CGPoint, to end: CGPoint, duration: TimeInterval = 0.5) {
         Task { @MainActor in
            guard let window = await MirroringEngine.shared.findMirroringWindow() else { return }
            let frame = window.frame
            
            let screenStart = CGPoint(x: frame.origin.x + start.x, y: frame.origin.y + start.y)
            let screenEnd = CGPoint(x: frame.origin.x + end.x, y: frame.origin.y + end.y)
            
            Log.action("InputSimulator: Swiping from (\(Int(start.x)), \(Int(start.y))) to (\(Int(end.x)), \(Int(end.y)))")
            
            let source = CGEventSource(stateID: .combinedSessionState)
            let down = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown, mouseCursorPosition: screenStart, mouseButton: .left)
            down?.post(tap: .cghidEventTap)
            
            // Perform interpolation for smooth drag
            let steps = 10
            for i in 1...steps {
                let t = CGFloat(i) / CGFloat(steps)
                let currentPoint = CGPoint(
                    x: screenStart.x + (screenEnd.x - screenStart.x) * t,
                    y: screenStart.y + (screenEnd.y - screenStart.y) * t
                )
                let drag = CGEvent(mouseEventSource: source, mouseType: .leftMouseDragged, mouseCursorPosition: currentPoint, mouseButton: .left)
                drag?.post(tap: .cghidEventTap)
                usleep(useconds_t(duration * 1_000_000 / Double(steps)))
            }
            
            let up = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp, mouseCursorPosition: screenEnd, mouseButton: .left)
            up?.post(tap: .cghidEventTap)
        }
    }
}
