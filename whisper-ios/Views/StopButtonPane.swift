import SwiftUI
import AVFoundation


struct StopButtonPane: View {
    let stopAction: () -> Void

    let circleDiameter: CGFloat = 80
    let buttonColor: Color = .red
    let borderStrokeColor: Color = .red
    let borderStrokeWidth: CGFloat = 2
    let borderSpacing: CGFloat = 10
    let animation: Animation = .easeInOut
    let stoppedStateCornerRadius: CGFloat = 0.10
    let stoppedStateSize: CGFloat = 0.5

    var body: some View {
        ZStack {
            Circle()
                .stroke(borderStrokeColor, lineWidth: borderStrokeWidth)
                .frame(width: circleDiameter, height: circleDiameter)

            recordButton(size: circleDiameter - borderSpacing)
                .animation(animation)
                .foregroundColor(buttonColor)
        }
    }


    private func recordButton(size: CGFloat) -> some View {
        return Button(action: stopAction){
            RoundedRectangle(cornerRadius: size * stoppedStateCornerRadius)
                .frame(width: size * stoppedStateSize, height: size * stoppedStateSize)
        }
    }
}

struct StopButtonPane_Previews: PreviewProvider {
    static var previews: some View {
        return StopButtonPane(stopAction: {})
    }
}
