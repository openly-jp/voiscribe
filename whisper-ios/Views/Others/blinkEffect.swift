import SwiftUI

// https://qiita.com/Rubydog/items/82b670866b3e500fff95
struct BlinkEffect: ViewModifier {
    @State var isOn: Bool = false
    let opacityRange: ClosedRange<Double>
    let interval: Double

    init(opacity: ClosedRange<Double>, interval: Double) {
        self.opacityRange = opacity
        self.interval = interval
    }

    func body(content: Content) -> some View {
        content
            .opacity(self.isOn ? self.opacityRange.lowerBound : self.opacityRange.upperBound)
            .animation(Animation.linear(duration: self.interval).repeatForever(), value: isOn)
            .onAppear(perform: {
                self.isOn = true
            })
    }
}

extension View {
    func blinkEffect(opacity: ClosedRange<Double> = 0.1...1, interval: Double = 0.6) -> some View {
        self.modifier(BlinkEffect(opacity: opacity, interval: interval))
    }
}
