//import UIKit
import AVFoundation
import SwiftUI


struct AudioPlayer: View {
    @Binding var player: AVAudioPlayer
    @State var currentPlayingTime: Double = 0
    @State var isEditing = false
    @State var isPlaying = false

    @State var updateRecordingTimeTimer: Timer? = nil

    var body: some View {
        VStack(spacing: 10) {
            Slider(value: $currentPlayingTime, in: 0...player.duration) { editing in
                isEditing = editing
                if !editing {
                    player.currentTime = currentPlayingTime
                }
            }

            HStack {
                Text(formatTime(player.currentTime, duration: player.duration))
                Spacer()
                Text(formatTime(player.duration - player.currentTime, duration: player.duration))
            }
            .font(.caption)

            HStack {
                PlayerButton(name: "gobackward.5", size: 40) {
                    player.currentTime -= 5
                }
                Spacer()
                PlayerButton(
                    name: isPlaying ? "pause.circle.fill" : "play.circle.fill",
                    size: 60
                ) {
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
                    } else {
                        player.pause()
                    }

                    isPlaying = !isPlaying
                }

                Spacer()

                PlayerButton(name: "goforward.5", size: 40) {
                    player.currentTime += 5
                }
            }
            .padding(.horizontal, 60)
            .padding(.bottom, 10)
        }.onDisappear {
            player.stop()
            if let updateRecordingTimeTimer {
                updateRecordingTimeTimer.invalidate()
            }
        }
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
        AudioPlayer(player: .constant(player))
    }
}
