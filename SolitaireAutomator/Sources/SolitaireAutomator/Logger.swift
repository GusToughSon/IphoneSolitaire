import Foundation

/// Global Debug Logger for the Solitaire Automator project.
/// Every module should use this to ensure we can troubleshoot via console output.
enum Log {
    enum Level: String {
        case info = "ℹ️ INFO"
        case debug = "🔍 DEBUG"
        case warning = "⚠️ WARNING"
        case error = "❌ ERROR"
        case action = "🎯 ACTION"
    }

    static func message(_ text: String, level: Level = .info, file: String = #file, function: String = #function, line: Int = #line) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let fileName = (file as NSString).lastPathComponent
        let output = "[\(timestamp)] [\(level.rawValue)] [\(fileName):\(line)] \(function) -> \(text)"
        print(output)
    }

    static func info(_ text: String, file: String = #file, function: String = #function, line: Int = #line) {
        message(text, level: .info, file: file, function: function, line: line)
    }

    static func debug(_ text: String, file: String = #file, function: String = #function, line: Int = #line) {
        message(text, level: .debug, file: file, function: function, line: line)
    }

    static func warn(_ text: String, file: String = #file, function: String = #function, line: Int = #line) {
        message(text, level: .warning, file: file, function: function, line: line)
    }

    static func error(_ text: String, file: String = #file, function: String = #function, line: Int = #line) {
        message(text, level: .error, file: file, function: function, line: line)
    }

    static func action(_ text: String, file: String = #file, function: String = #function, line: Int = #line) {
        message(text, level: .action, file: file, function: function, line: line)
    }
}
