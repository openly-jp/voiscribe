import AVFoundation
import SwiftUI

struct RecognitionPlayer: View {
    // MARK: - state about player

    @State var player: AVAudioPlayer? = nil
    @State var currentPlayingTime: Double = 0

    // MARK: - states for editing transcription

    @State var isEditing = false
    @FocusState var focus: UUID?

    var recognizedSpeech: RecognizedSpeech
    @Binding var recognizedSpeeches: [RecognizedSpeech]

    @Environment(\.presentationMode) var presentationMode

    init(
        recognizedSpeech: RecognizedSpeech,
        recognizedSpeeches: Binding<[RecognizedSpeech]>
    ) {
        self.recognizedSpeech = recognizedSpeech
        _recognizedSpeeches = recognizedSpeeches

        let session = AVAudioSession.sharedInstance()
        try! session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
        try! session.setActive(true)
    }

    var body: some View {
        VStack(spacing: 0) {
            TranscriptionLines(
                recognizedSpeech: recognizedSpeech,
                player: $player,
                currentPlayingTime: $currentPlayingTime,
                isEditing: $isEditing,
                focus: _focus
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
                        focus: _focus
                    )
                }
            }
        }
        .onAppear(perform: initAudioPlayer)
        .toolbar { if !isEditing { toolBar } }
    }

    var toolBar: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button {
                isEditing = true
            } label: {
                Image(systemName: "highlighter")
                    .foregroundColor(Color(.label))
            }

            Menu {
                Button {
                    UIPasteboard.general.string = allTranscription
                } label: {
                    Label("全文をコピー", systemImage: "doc.on.doc")
                }
                Button(role: .destructive) {
                    if let removeIdx = recognizedSpeeches.firstIndex { $0.id == recognizedSpeech.id } {
                        recognizedSpeeches.remove(at: removeIdx)
                        CoreDataRepository.deleteRecognizedSpeech(recognizedSpeech: recognizedSpeech)
                        presentationMode.wrappedValue.dismiss()
                    }
                } label: {
                    Label("削除", systemImage: "trash")
                        .foregroundColor(.red)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(Color(.label))
                    .rotationEffect(.degrees(90))
            }
        }
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
//         let url = recognizedSpeech.audioFileURL
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

        RecognitionPlayer(
            recognizedSpeech: recognizedSpeech,
            recognizedSpeeches: .constant([])
        )
    }
}
