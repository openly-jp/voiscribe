// import UIKit
import AVFoundation
import SwiftUI

let availableSpeedRates = [0.5, 0.8, 1, 1.2, 1.5, 2, 2.5, 3.5, 4]

class IsPlayingObject: NSObject, ObservableObject, AVAudioPlayerDelegate {
    // This state is used for monitoring playing state
    // because SwiftUI doesn't detect state change of isPlaying in AVAudioPlayer
    @Published var isPlaying = false

    func audioPlayerDidFinishPlaying(
        _ _: AVAudioPlayer,
        successfully _: Bool
    ) {
        isPlaying = false
    }
}

struct AudioPlayer: View {
    var player: AVAudioPlayer

    @Binding var currentPlayingTime: Double
    @State var isEditingSlider = false

    @State var isChangingSpeedRate = false
    @State var speedRateIdx = 2 // speedRate = 1x

    @State var updatePlayingTimeTimer: Timer? = nil
    let transcription: String

    // `audioPlayerDidFinishPlaying` method is delegated to
    // the following object from `AVAudioPlayer`
    @StateObject var isPlayingObject = IsPlayingObject()

    var body: some View {
        VStack(spacing: 10) {
            Slider(value: $currentPlayingTime, in: 0 ... player.duration) { editing in
                isEditingSlider = editing
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
                ZStack {
                    HStack {
                        Button(speedRate2String(availableSpeedRates[speedRateIdx])) { isChangingSpeedRate = true }
                            .foregroundColor(Color(.secondaryLabel))
                            .sheet(isPresented: $isChangingSpeedRate) { changeSpeedSheetView }
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        PlayerButton(name: "gobackward.5", size: 35) {
                            player.currentTime -= 5
                            currentPlayingTime = player.currentTime
                        }
                        Spacer()
                        PlayerButton(
                            name: isPlayingObject.isPlaying ? "pause.circle.fill" : "play.circle.fill",
                            size: 55,
                            action: playOrPause
                        )
                        Spacer()
                        PlayerButton(name: "goforward.5", size: 35) {
                            player.currentTime += 5
                            currentPlayingTime = player.currentTime
                        }
                        Spacer()
                    }
                }
                /* Hide as future premium feature
                 PlayerButton(name: "doc.on.doc", size: 20) {
                     UIPasteboard.general.string = transcription
                 }
                 */
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 10)
        }
        .onAppear { player.delegate = isPlayingObject }
        .onDisappear {
            player.stop()
            if let updatePlayingTimeTimer {
                updatePlayingTimeTimer.invalidate()
            }
        }
    }

    var changeSpeedSheetView: some View {
        Group {
            NavigationView {
                List {
                    ForEach(Array(availableSpeedRates.enumerated()), id: \.offset) { idx, speedRate in
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
        if !isPlayingObject.isPlaying {
            updatePlayingTimeTimer = Timer.scheduledTimer(
                withTimeInterval: 0.1,
                repeats: true
            ) { _ in
                if !isEditingSlider {
                    currentPlayingTime = player.currentTime
                }
            }
            RunLoop.main.add(updatePlayingTimeTimer!, forMode: .common)
            player.play()
        } else {
            updatePlayingTimeTimer?.invalidate()
            player.pause()
        }
        isPlayingObject.isPlaying = !isPlayingObject.isPlaying
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

// This view is used when recognition is on going
// this is just for indicating that the audio is being recognized
struct RecognizingAudioPlayer: View {
    @State var isRotating = 0.0
    @State var currentPlayingTime = 0.0
    func speedRate2String(_ speedRate: Double) -> String {
        "\(String(format: "%g", speedRate))x"
    }

    var body: some View {
        VStack(spacing: 10) {
            Slider(value: $currentPlayingTime, in: 0 ... 0) {}
            HStack {
                Text(formatTime(0))
                Spacer()
                Text("認識中")
            }
            .font(.caption)
            ZStack {
                HStack {
                    Button(speedRate2String(availableSpeedRates[2])) {}
                        .foregroundColor(Color(.secondaryLabel))
                        .disabled(true)
                    Spacer()
                }
                HStack {
                    Spacer()
                    PlayerButton(name: "gobackward.5", size: 35) {}
                        .disabled(true)
                    Spacer()
                    ProgressView()
                        .scaleEffect(2)
                    Spacer()
                    PlayerButton(name: "goforward.5", size: 35) {}
                        .disabled(true)
                    Spacer()
                    /* Hide as future premium feature
                     PlayerButton(name: "nosign", size: 20) {}
                         .disabled(true)
                     */
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 10)
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
