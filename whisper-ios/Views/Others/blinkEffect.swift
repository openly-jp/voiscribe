import SwiftUI

// https://qiita.com/Rubydog/items/82b670866b3e500fff95
struct BlinkEffect: ViewModifier {
    @State var isOn: Bool = false
    let opacityRange: ClosedRange<Double>
    let interval: Double

    init(opacity: ClosedRange<Double>, interval: Double) {
        opacityRange = opacity
        self.interval = interval
    }

    func body(content: Content) -> some View {
        content
            .opacity(isOn ? opacityRange.lowerBound : opacityRange.upperBound)
            .animation(isOn ? Animation.linear(duration: interval).repeatForever() : nil, value: isOn)
            .onAppear {
                // Without the following DispathcQueue, the issue #157 occurs.
                // https://developer.apple.com/forums/thread/651065?answerId=665270022#665270022
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isOn = true
                }
            }
    }
}

extension View {
    func blinkEffect(
        opacity: ClosedRange<Double> = 0.1 ... 1,
        interval: Double = 0.6
    ) -> some View {
        modifier(BlinkEffect(opacity: opacity, interval: interval))
    }
}
