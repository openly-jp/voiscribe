// import UIKit
import AVFoundation
import SwiftUI

let availableSpeedRates = [0.5, 0.8, 1, 1.2, 1.5, 2, 2.5, 3.5, 4]

struct AudioPlayer: View {
    var player: AVAudioPlayer

    @Binding var currentPlayingTime: Double
    @State var isEditing = false
    @State var isPlaying = false

    @State var isChangingSpeedRate = false
    @State var speedRateIdx = 2 // speedRate = 1x

    @State var updateRecordingTimeTimer: Timer? = nil
    let transcription: String

    var body: some View {
        VStack(spacing: 10) {
            Slider(value: $currentPlayingTime, in: 0 ... player.duration) { editing in
                isEditing = editing
                if !editing {
                    player.currentTime = currentPlayingTime
                    currentPlayingTime = player.currentTime
                }
            }

            HStack {
                Text(formatTime(player.currentTime, duration: player.duration))
                Spacer()
                Text(formatTime(player.duration - player.currentTime, duration: player.duration))
            }
            .font(.caption)

            HStack {
                Button(speedRate2String(availableSpeedRates[speedRateIdx])) { isChangingSpeedRate = true }
                    .foregroundColor(Color(.secondaryLabel))
                    .sheet(isPresented: $isChangingSpeedRate) { changeSpeedSheetView }
                Spacer()
                PlayerButton(name: "gobackward.5", size: 35) {
                    player.currentTime -= 5
                    currentPlayingTime = player.currentTime
                }
                Spacer()
                PlayerButton(
                    name: isPlaying ? "pause.circle.fill" : "play.circle.fill",
                    size: 55,
                    action: playOrPause
                )
                Spacer()
                PlayerButton(name: "goforward.5", size: 35) {
                    player.currentTime += 5
                    currentPlayingTime = player.currentTime
                }
                Spacer()

                ShareButton(transcription: transcription)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 10)
        }.onDisappear {
            player.stop()
            if let updateRecordingTimeTimer {
                updateRecordingTimeTimer.invalidate()
            }
        }
    }

    var changeSpeedSheetView: some View {
        Group {
            NavigationView {
                List {
                    ForEach(Array(availableSpeedRates.enumerated()), id: \.self.offset) { idx, speedRate in
                        Button {
                            speedRateIdx = idx
                            player.rate = Float(speedRate)
                        } label: {
                            HStack {
                                Text(speedRate2String(speedRate))
                                Spacer()
                                if idx == speedRateIdx {
                                    Image(systemName: "checkmark")
                                }
                            }.padding(10)
                        }
                    }
                }
                .navigationBarTitle("再生速度の変更")
                .listStyle(.inset)
            }
            HStack {
                Spacer()
                Button("閉じる") {
                    isChangingSpeedRate = false
                }
                Spacer()
            }
        }
    }

    func playOrPause() {
        if !isPlaying {
            updateRecordingTimeTimer = Timer.scheduledTimer(
                withTimeInterval: 0.1,
                repeats: true
            ) { _ in
                if !isEditing {
                    currentPlayingTime = player.currentTime
                }
            }
            player.play()
            isPlaying = true
        } else {
            updateRecordingTimeTimer?.invalidate()
            player.pause()
            isPlaying = false
        }
    }

    func speedRate2String(_ speedRate: Double) -> String {
        "\(String(format: "%g", speedRate))x"
    }
}

struct PlayerButton: View {
    let name: String
    let size: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: CGFloat(size)))
                .foregroundColor(Color(.secondaryLabel))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let url = getRecognizedSpeechMock(audioFileName: "sample_ja", csvFileName: "sample_ja")?.audioFileURL
        let player = try! AVAudioPlayer(contentsOf: url!)
        AudioPlayer(
            player: player,
            currentPlayingTime: .constant(0),
            transcription: "認識結果です"
        )
    }
}
