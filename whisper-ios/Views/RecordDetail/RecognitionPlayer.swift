import AVFoundation
import SwiftUI

struct RecognitionPlayer: View {
    var recognizedSpeech: RecognizedSpeech
    let deleteRecognizedSpeech: (UUID) -> Void
    let isRecognizing: Bool

    // MARK: - state about player

    @State var player: AVAudioPlayer? = nil
    @State var currentPlayingTime: Double = 0

    // MARK: - states for editing transcription

    @State var isEditing = false
    @FocusState var focusedTranscriptionLineId: UUID?

    var body: some View {
        if isRecognizing {
            VStack(spacing: 0) {
                RecognizingTranscriptionLines(recognizedSpeech: recognizedSpeech)
                RecognizingAudioPlayer()
                    .padding(20)
            }
        } else {
            VStack(spacing: 0) {
                TranscriptionLines(
                    recognizedSpeech: recognizedSpeech,
                    player: $player,
                    currentPlayingTime: $currentPlayingTime,
                    isEditing: $isEditing,
                    focusedTranscriptionLineId: _focusedTranscriptionLineId
                )

                if let player {
                    if !isEditing {
                        AudioPlayer(
                            player: player,
                            currentPlayingTime: $currentPlayingTime,
                            transcription: allTranscription
                        )
                        .padding(20)
                    } else {
                        EditingAudioPlayer(
                            player: player,
                            currentPlayingTime: $currentPlayingTime,
                            focusedTranscriptionLineId: _focusedTranscriptionLineId
                        )
                    }
                }
            }
            .onAppear(perform: initAudioPlayer)
            .toolbar {
                // The following `ToolBar` is only shown when `isEditing` is true,
                // but conditional clause cannot be used in `.toolbar` modifier until iOS16.
                // Thus whether `ToolBar` is shown or not is controlled inside it.
                ToolBar(
                    recognizedSpeech: recognizedSpeech,
                    deleteRecognizedSpeech: deleteRecognizedSpeech,
                    allTranscription: allTranscription,
                    isEditing: $isEditing
                )
            }
        }
    }

    var allTranscription: String {
        recognizedSpeech.transcriptionLines.reduce("") { "\($0)\n\($1.text)" }
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
        let recognizedSpeech: RecognizedSpeech! = getRecognizedSpeechMock(
            audioFileName: "sample_ja",
            csvFileName: "sample_ja"
        )
        let isRecognizing = false

        RecognitionPlayer(
            recognizedSpeech: recognizedSpeech,
            deleteRecognizedSpeech: { _ in },
            isRecognizing: isRecognizing
        )
    }
}
