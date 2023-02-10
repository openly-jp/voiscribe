import AVFoundation
import SwiftUI

let ICON_SIZE = 20

struct EditingAudioPlayer: View {
    var player: AVAudioPlayer

    @Binding var currentPlayingTime: Double

    @State var isChangingSpeedRate = false
    @State var speedRateIdx = 2 // speedRate = 1x

    @State var updateRecordingTimeTimer: Timer? = nil

    // `audioPlayerDidFinishPlaying` method is delegated to
    // the following object from `AVAudioPlayer`
    @StateObject var isPlayingObject = IsPlayingObject()

    @FocusState var focusedTranscriptionLineId: UUID?
    @State var prevFocusedTranscriptionLineId: UUID?

    var body: some View {
        HStack {
            Button(speedRate2String(availableSpeedRates[speedRateIdx])) { isChangingSpeedRate = true }
                .foregroundColor(Color(.secondaryLabel))
                .sheet(isPresented: $isChangingSpeedRate) { changeSpeedSheetView }

            Spacer()
            PlayerButton(name: "gobackward.5", size: ICON_SIZE) {
                player.currentTime -= 5
                currentPlayingTime = player.currentTime
            }

            Spacer()
            PlayerButton(
                name: isPlayingObject.isPlaying ? "pause.fill" : "play.fill",
                size: ICON_SIZE,
                action: playOrPause
            )

            Spacer()
            PlayerButton(name: "goforward.5", size: ICON_SIZE) {
                player.currentTime += 5
                currentPlayingTime = player.currentTime
            }

            Spacer()
            keyboardButton()
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 15)
        .onAppear { player.delegate = isPlayingObject }
        .onDisappear {
            player.stop()
            if let updateRecordingTimeTimer {
                updateRecordingTimeTimer.invalidate()
            }
        }
    }

    func keyboardButton() -> some View {
        if focusedTranscriptionLineId != nil {
            return PlayerButton(name: "keyboard.chevron.compact.down", size: ICON_SIZE) {
                prevFocusedTranscriptionLineId = focusedTranscriptionLineId
                focusedTranscriptionLineId = nil
            }
        } else {
            return PlayerButton(name: "keyboard", size: ICON_SIZE) {
                focusedTranscriptionLineId = prevFocusedTranscriptionLineId
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
        if !isPlayingObject.isPlaying {
            updateRecordingTimeTimer = Timer.scheduledTimer(
                withTimeInterval: 0.1,
                repeats: true
            ) { _ in
                currentPlayingTime = player.currentTime
            }
            RunLoop.main.add(updateRecordingTimeTimer!, forMode: .common)
            player.play()
        } else {
            updateRecordingTimeTimer?.invalidate()
            player.pause()
        }
        isPlayingObject.isPlaying = !isPlayingObject.isPlaying
    }

    func speedRate2String(_ speedRate: Double) -> String {
        "\(String(format: "%g", speedRate))x"
    }
}

struct EditingAudioPlayer_Previews: PreviewProvider {
    static var previews: some View {
        let url = getRecognizedSpeechMock(audioFileName: "sample_ja", csvFileName: "sample_ja")?.audioFileURL
        let player = try! AVAudioPlayer(contentsOf: url!)
        EditingAudioPlayer(
            player: player,
            currentPlayingTime: .constant(0)
        )
    }
}
