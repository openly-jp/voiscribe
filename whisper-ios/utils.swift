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
