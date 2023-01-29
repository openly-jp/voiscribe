import AVFoundation
import SwiftUI

struct TranscriptionLines: View {
    let recognizedSpeech: RecognizedSpeech

    @Binding var player: AVAudioPlayer?
    @Binding var currentPlayingTime: Double

    // MARK: - timer to update automatic scroll

    /// this is initialized in .onAppear method
    @State var updateScrollTimer: Timer?

    // MARK: - states for editing transcriptions

    @Binding var isEditing: Bool
    @State var editedTranscriptionTexts = [String]()
    @FocusState var focus: UUID?

    var body: some View {
        ScrollViewReader { scrollReader in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(
                        Array(recognizedSpeech.transcriptionLines.enumerated()),
                        id: \.self.element.id
                    ) {
                        (idx: Int, transcriptionLine: TranscriptionLine) in
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

                                    if isEditing {
                                        TextEditor(text: $editedTranscriptionTexts[idx])
                                            .multilineTextAlignment(.leading)
                                            .focused($focu, equals: transcriptionLine.id)
                                            .border(Color(.systemGray5), width: 1)
                                    } else {
                                        Text(transcriptionLine.text)
                                            .foregroundColor(Color(.label))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                            }
                            .padding(10)
                            .background(getTextColor(idx))
                            .contextMenu {
                                Button {
                                    isEditing = true
                                    focus = transcriptionLine.id
                                } label: {
                                    Label("編集", systemImage: "pencil")
                                }

                                Button {
                                    UIPasteboard.general.string = transcriptionLine.text
                                } label: {
                                    Label("コピー", systemImage: "doc.on.doc")
                                }
                            }
                            Divider()
                        }
                        .id(idx)
                    }
                }
            }
            .onAppear {
                initUpdateScrollTimer(scrollReader)
                initTranscriptionTexts()
            }
            .onDisappear { updateScrollTimer?.invalidate() }
        }
        .frame(
            minWidth: 0,
            maxWidth: .infinity,
            minHeight: 0,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .padding(.top)
        .toolbar { if isEditing { editingToolBar } }
    }

    var editingToolBar: some ToolbarContent {
        Group {
            ToolbarItem(placement: .principal) {
                Text("書き起こし編集")
                    .foregroundColor(Color(.label))
                    .font(.title3)
                    .bold()
                    .padding()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("編集終了") {
                    updateTranscriptionLines()

                    isEditing = false
                    focus = nil
                }
            }
        }
    }

    func updateTranscriptionLines() {
        for idx in 0 ..< recognizedSpeech.transcriptionLines.count {
            let transcriptionLine = recognizedSpeech.transcriptionLines[idx]
            transcriptionLine.text = editedTranscriptionTexts[idx]
            TranscriptionLineData.update(transcriptionLine)
        }
    }

    func initTranscriptionTexts() {
        for transcriptionLine in recognizedSpeech.transcriptionLines {
            editedTranscriptionTexts.append(transcriptionLine.text)
        }
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

    func getTextColor(_ idx: Int) -> Color {
        let lines = recognizedSpeech.transcriptionLines
        let startMSec = Double(lines[idx].startMSec)
        let endMSec: Double = idx < lines.count - 1 ? Double(lines[idx + 1].startMSec) : .infinity
        let currentMSec = currentPlayingTime * 1000
        let isInside = startMSec <= currentMSec && currentMSec < endMSec
        let uiColor: UIColor = isInside ? .systemGray5 : .systemBackground
        return Color(uiColor)
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
}

struct TranscriptionLines_Previews: PreviewProvider {
    static var previews: some View {
        let recognizedSpeech: RecognizedSpeech! = getRecognizedSpeechMock(audioFileName: "sample_ja", csvFileName: "sample_ja")
        let player = try! AVAudioPlayer(contentsOf: recognizedSpeech.audioFileURL)

        TranscriptionLines(
            recognizedSpeech: recognizedSpeech,
            player: .constant(player),
            currentPlayingTime: .constant(20.0),
            isEditing: .constant(true),
            focus: FocusState<UUID?>()
        )

        TranscriptionLines(
            recognizedSpeech: recognizedSpeech,
            player: .constant(player),
            currentPlayingTime: .constant(20.0),
            isEditing: .constant(true),
            focus: FocusState<UUID?>()
        )
    }
}
