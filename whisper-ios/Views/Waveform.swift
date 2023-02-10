import DequeModule
import SwiftUI

struct IdAmp: Identifiable, Equatable {
    var id: UUID
    var amp: Float
}

/// A view that displays a waveform of the audio input.
///
/// The height of this view is the same as the height of the parent view.
struct Waveform: View {
    @Binding var idAmps: Deque<IdAmp>
    @Binding var isPaused: Bool

    // Since the number of idAmps increases monotonically,
    // idAmps that are no longer displayed should be removed.
    // However, if this View is used in multiple locations,
    // deleting idAmps in each location will cause a bug,
    // so it is necessary to set removeIdAmps to true in only one location.
    let removeIdAmps: Bool

    // parameter to control the sensitivity of the waveform
    let sensitivity: Float = 10
    let e: Float = 2.718281828459
    let rectangleWidth: CGFloat = 2.0
    let spacingWidth: CGFloat = 2.0

    var body: some View {
        GeometryReader { geometry in
            ForEach(Array(idAmps.enumerated()), id: \.self.element.id) { idx, idAmp in
                // idAmp.amp: -160 ~ 0
                // expAmp: exp(-160 / sensitivity) ~ 1
                let expAmp = CGFloat(powf(e, idAmp.amp / sensitivity))
                let height = expAmp * geometry.size.height
                let x = getX(
                    idAmpIdx: idx,
                    numIdAmps: idAmps.count,
                    geometry: geometry
                )

                if x > 0 {
                    Rectangle()
                        .frame(width: rectangleWidth, height: height)
                        .position(x: x, y: geometry.size.height / 2)
                        .foregroundColor(isPaused ? Color(.label) : .red)
                }
            }
            .onChange(of: idAmps) { _ in
                if removeIdAmps { removeUndisplayedAmp(geometry) }
            }
        }
    }

    /// remove amps that is not displayed
    ///
    /// amplitude obtained from AVAudioRecorder is added every 0.5s.
    /// without removing amps that is not diplayed in screen,
    /// it will cause out of memory error
    func removeUndisplayedAmp(_ geometry: GeometryProxy) {
        var numIdAmps = idAmps.count
        while getX(idAmpIdx: 0, numIdAmps: numIdAmps, geometry: geometry) < 0 {
            idAmps.popFirst()
            numIdAmps -= 1
        }
    }

    func getX(
        idAmpIdx: Int,
        numIdAmps: Int,
        geometry: GeometryProxy
    ) -> CGFloat {
        let numRightRecs = CGFloat(numIdAmps - 1 - idAmpIdx)
        let rightX = numRightRecs * (rectangleWidth + spacingWidth)
        return geometry.size.width - rightX
    }
}

struct Waveform_Previews: PreviewProvider {
    static var previews: some View {
        var idAmps: Deque<IdAmp> = []
        var idx = 0
        for _ in 0 ... 100 {
            for amp in [-50, -2, -14, -14, -11, -42, -21, -100, -14] {
                idAmps.append(IdAmp(id: UUID(), amp: Float(amp)))
                idx += 1
            }
        }
        return Waveform(
            idAmps: .constant(idAmps),
            isPaused: .constant(false),
            removeIdAmps: true
        )
    }
}
