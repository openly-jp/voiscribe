import AVFoundation
import SwiftUI

struct RecognitionPlayer: View {
    // MARK: - state about player

    @State var player: AVAudioPlayer? = nil
    @State var currentPlayingTime: Double = 0

    var recognizedSpeech: RecognizedSpeech

    init(recognizedSpeech: RecognizedSpeech) {
        self.recognizedSpeech = recognizedSpeech

        let session = AVAudioSession.sharedInstance()
        try! session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
        try! session.setActive(true)
    }

    var body: some View {
        Group {
            TranscriptionLines(
                recognizedSpeech: recognizedSpeech,
                player: $player,
                currentPlayingTime: $currentPlayingTime
            )

            if let player {
                AudioPlayer(
                    player: player,
                    currentPlayingTime: $currentPlayingTime,
                    transcription: allTranscription
                )
                .padding(20)
            }
        }.onAppear(perform: initAudioPlayer)
    }

    var allTranscription: String {
        recognizedSpeech.transcriptionLines.reduce("") { $0 + $1.text }
    }

    /// initialize AVAudioPlayer
    ///
    /// The URL of the audio file is needed to initialize AVAudioPlayer.
    /// However, streaming ASR creates multiple audio files,
    /// which are combined into one file after ASR is completed.
    /// Therefore, initialization of AVAudioPlayer must wait for the completion of ASR.
    func initAudioPlayer() {
        // TODO: fix this (issue #25)
        let fileName = recognizedSpeech.audioFileURL.lastPathComponent
       let url = getURLByName(fileName: fileName)
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player!.enableRate = true
        } catch {
            Logger.error("failed to init AVAudioPlayer.")
        }
    }


}

struct RecognitionPlayer_Previews: PreviewProvider {
    static var previews: some View {
        let recognizedSpeech: RecognizedSpeech! = getRecognizedSpeechMock(audioFileName: "sample_ja", csvFileName: "sample_ja")

        RecognitionPlayer(recognizedSpeech: recognizedSpeech)
    }
}
