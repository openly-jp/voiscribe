import Foundation

func formatTime(_ seconds: Double, duration: Double? = nil) -> String {
    var d = duration
    if d == nil {
        d = seconds
    }

    let f = DateComponentsFormatter()
    f.allowedUnits = d! >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
    f.unitsStyle = .positional
    f.zeroFormattingBehavior = .pad
    return f.string(from: seconds)!
}

enum Logger {
    static func info(_ items: Any..., file: String = #file, line: Int = #line, function: String = #function) {
        let filename = URL(fileURLWithPath: file).lastPathComponent
        for item in items {
            print("💡 [\(filename) \(line):\(function)] : \(item)")
        }
    }

    static func debug(_ items: Any..., file: String = #file, line: Int = #line, function: String = #function) {
        #if DEBUG
            let filename = URL(fileURLWithPath: file).lastPathComponent
            for item in items {
                print("⚙️ [\(filename) \(line):\(function)] : \(item)")
            }
        #endif
    }

    static func warning(_ items: Any..., file: String = #file, line: Int = #line, function: String = #function) {
        let filename = URL(fileURLWithPath: file).lastPathComponent
        for item in items {
            print("⚠️ [\(filename) \(line):\(function)] : \(item)")
        }
    }

    static func error(_ items: Any..., file: String = #file, line: Int = #line, function: String = #function) {
        let filename = URL(fileURLWithPath: file).lastPathComponent
        for item in items {
            print("🚨 [\(filename) \(line):\(function)] : \(item)")
        }
    }
}
