import DequeModule
import SwiftUI

struct IdAmp : Identifiable {
    var id: UUID
    var amp: Float
}

struct Waveform: View {
    @Binding var idAmps: Deque<IdAmp>
    @Binding var isPaused: Bool
    
    let e: Float = 2.718281828459
    let rectangleWidth: CGFloat = 2.0
    let spacingWidth: CGFloat = 2.0

    var body: some View {
        GeometryReader { geometry in
            returnView(geometry)
        }
    }
    
    func returnView(_ geometry: GeometryProxy) -> some View {
        removeUndisplayedAmp(geometry)
        return Group {
            ForEach(Array(idAmps.enumerated()), id: \.self.offset) { idx, idAmp in
                let amp = CGFloat(powf(e, idAmp.amp / 10) * 4)
                let x = getX(
                    idAmpIdx: idx,
                    numIdAmps: idAmps.count,
                    geometry: geometry
                )

                Rectangle()
                    .frame(width: rectangleWidth, height: amp * 50)
                    .position(x: x)
                    .foregroundColor(isPaused ? Color(.label) : .red)
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
        for _ in (0...100) {
            for amp in [-50, -2, -14, -14, -11, -42, -21, -100, -14] {
                idAmps.append(IdAmp(id: UUID(), amp: Float(amp)))
                idx += 1
            }
        }
        return Waveform(idAmps: .constant(idAmps), isPaused: .constant(false))
    }
}
