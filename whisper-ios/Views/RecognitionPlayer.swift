import AVFoundation
import SwiftUI

struct RecognitionPlayer: View {
    // MARK: - state about player

    @State var player: AVAudioPlayer? = nil
    @State var currentPlayingTime: Double = 0

    // MARK: - timer to update automatic scroll

    /// this is initialized in .onAppear method
    @State var updateScrollTimer: Timer?

    var recognizedSpeech: RecognizedSpeech

    init(recognizedSpeech: RecognizedSpeech) {
        self.recognizedSpeech = recognizedSpeech

        let session = AVAudioSession.sharedInstance()
        try! session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
        try! session.setActive(true)
    }

    var body: some View {
        ScrollViewReader { scrollReader in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(recognizedSpeech.transcriptionLines.enumerated()), id: \.self.offset) {
                        idx, transcriptionLine in
                        Group {
                            let action = moveTranscriptionLine(
                                idx: idx,
                                transcriptionLine: transcriptionLine,
                                scrollReader: scrollReader
                            )
                            Button(action: action) {
                                HStack(alignment: .center) {
                                    Text(formatTime(Double(transcriptionLine.startMSec) / 1000))
                                        .frame(width: 50, alignment: .center)
                                        .foregroundColor(Color.blue)
                                        .padding()
                                    Spacer()
                                    Text(transcriptionLine.text)
                                        .foregroundColor(Color(.label))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                            .padding(10)
                            .background(getTextColor(idx))
                            Divider()
                        }
                        .id(idx)
                    }
                }
            }
            .onAppear { initUpdateScrollTimer(scrollReader) }
            .onDisappear { updateScrollTimer?.invalidate() }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .navigationBarTitle("", displayMode: .inline)
        .onAppear(perform: initAudioPlayer)

        if let player {
            AudioPlayer(
                player: player,
                currentPlayingTime: $currentPlayingTime,
                transcription: allTranscription
            )
            .padding(20)
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
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player!.enableRate = true
        } catch {
            Logger.error("failed to init AVAudioPlayer.")
        }
    }

    func getCurrentTranscriptionIndex() -> Int {
        let lines = recognizedSpeech.transcriptionLines
        for idx in 0 ..< lines.count {
            let startMSec = Double(lines[idx].startMSec)
            let endMSec: Double = idx < lines.count - 1 ? Double(lines[idx + 1].startMSec) : .infinity
            let currentMSec = currentPlayingTime * 1000
            let isInside = startMSec <= currentMSec && currentMSec < endMSec
            if isInside {
                return idx
            }
        }
        return 0
    }

    func initUpdateScrollTimer(_ scrollReader: ScrollViewProxy) {
        updateScrollTimer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true
        ) { _ in
            if player!.isPlaying {
                // because user may want to know context of the current playing line
                // lines before the current line is also displayed
                var topIdx = getCurrentTranscriptionIndex() - 2
                topIdx = topIdx < 0 ? 0 : topIdx
                withAnimation {
                    scrollReader.scrollTo(topIdx, anchor: .top)
                }
            }
        }
    }

    func getTextColor(_ idx: Int) -> Color {
        let lines = recognizedSpeech.transcriptionLines
        let startMSec = Double(lines[idx].startMSec)
        let endMSec: Double = idx < lines.count - 1 ? Double(lines[idx + 1].startMSec) : .infinity
        let currentMSec = currentPlayingTime * 1000
        let isInside = startMSec <= currentMSec && currentMSec < endMSec
        let uiColor: UIColor = isInside ? .systemGray5 : .systemBackground
        return Color(uiColor)
    }

    func moveTranscriptionLine(
        idx: Int,
        transcriptionLine: TranscriptionLine,
        scrollReader: ScrollViewProxy
    ) -> () -> Void {
        {
            // actual currentTime become earlier than the specified time
            // e.g. player.currentTime = 1.25 -> actually player.currentTime shows 1.245232..
            // thus previous transcription line is highlighted incorrectly
            // 0.1 is added to avoid this
            let updatedTime = Double(transcriptionLine.startMSec) / 1000 + 0.1
            player!.currentTime = updatedTime
            currentPlayingTime = updatedTime
            withAnimation(.easeInOut) { scrollReader.scrollTo(idx) }
        }
    }
}

struct RecognitionPlayer_Previews: PreviewProvider {
    static var previews: some View {
        let recognizedSpeech: RecognizedSpeech! = getRecognizedSpeechMock(audioFileName: "sample_ja", csvFileName: "sample_ja")

        RecognitionPlayer(recognizedSpeech: recognizedSpeech)
    }
}
