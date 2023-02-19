import DequeModule
import Foundation
import SwiftUI

struct RecordingController: View {
    @Binding var isRecording: Bool
    @Binding var isPaused: Bool
    @Binding var isPaneOpen: Bool

    let startAction: () -> Void
    let stopAction: () -> Void

    let elapsedTime: Int
    @Binding var idAmps: Deque<IdAmp>

    let miniRecorderHeight: CGFloat = 70

    var body: some View {
        if isRecording {
            miniRecordingController
        } else {
            StartRecordingButton(startAction: startAction)
        }
    }

    var miniRecordingController: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(alignment: .center, spacing: 15) {
                Button { isPaneOpen.toggle() } label: {
                    HStack(alignment: .center, spacing: 15) {
                        Group {
                            if isPaused {
                                Image(systemName: "pause.fill")
                                    .foregroundColor(.gray)
                            } else {
                                Circle()
                                    .fill(.red)
                                    .blinkEffect()
                                    .frame(width: 12)
                            }
                        }.frame(width: 15)
                        Text(formatTime(Double(elapsedTime)))
                            .foregroundColor(Color(.label))
                        Waveform(idAmps: $idAmps, isPaused: $isPaused, removeIdAmps: false)
                            .frame(height: miniRecorderHeight)
                    }
                }

                Group {
                    if isPaused {
                        Button(action: startAction) {
                            Image(systemName: "record.circle")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.red)
                        }
                    } else {
                        Button(action: stopAction) {
                            Image(systemName: "pause.fill")
                                .resizable()
                                .frame(width: 15, height: 15)
                                .foregroundColor(Color(.label))
                        }
                    }
                }
                .frame(width: 30, height: 30)
            }.padding(.horizontal)
        }.frame(height: miniRecorderHeight)
    }
}

struct StartRecordingButton: View {
    let circleDiameter: CGFloat = 80
    let buttonColor: Color = .red
    let borderStrokeColor: Color = .red
    let borderStrokeWidth: CGFloat = 2
    let borderSpacing: CGFloat = 10
    let stoppedStateCornerRadius: CGFloat = 0.10
    let stoppedStateSize: CGFloat = 0.5

    let startAction: () -> Void

    var body: some View {
        ZStack {
            Circle()
                .stroke(borderStrokeColor, lineWidth: borderStrokeWidth)
                .frame(width: circleDiameter, height: circleDiameter)

            let size = circleDiameter - borderSpacing
            Button(action: startAction) { RoundedRectangle(cornerRadius: size)
                .frame(width: size, height: size)
                .foregroundColor(buttonColor)
            }
        }.frame(height: 150)
    }
}

struct RecordingController_Previews: PreviewProvider {
    static var previews: some View {
        var idAmps: Deque<IdAmp> = []
        var idx = 0
        for _ in 0 ... 100 {
            for amp in [-50, -2, -14, -14, -11, -42, -21, -100, -14] {
                idAmps.append(IdAmp(id: UUID(), amp: Float(amp)))
                idx += 1
            }
        }

        return Group {
            RecordingController(
                isRecording: .constant(true),
                isPaused: .constant(true),
                isPaneOpen: .constant(true),
                startAction: {},
                stopAction: {},
                elapsedTime: 23,
                idAmps: .constant(idAmps)
            )

            RecordingController(
                isRecording: .constant(false),
                isPaused: .constant(false),
                isPaneOpen: .constant(false),
                startAction: {},
                stopAction: {},
                elapsedTime: 23,
                idAmps: .constant(idAmps)
            )
        }
    }
}
