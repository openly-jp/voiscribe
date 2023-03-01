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
    @FocusState var focusedTranscriptionLineId: UUID?

    @State var isOpenCancelAlert: Bool = false

    init(
        recognizedSpeech: RecognizedSpeech,
        player: Binding<AVAudioPlayer?>,
        currentPlayingTime: Binding<Double>,
        isEditing: Binding<Bool>,
        focusedTranscriptionLineId: FocusState<UUID?>
    ) {
        self.recognizedSpeech = recognizedSpeech
        _player = player
        _currentPlayingTime = currentPlayingTime
        _isEditing = isEditing
        _focusedTranscriptionLineId = focusedTranscriptionLineId

        // By default, scroll inside `TextEditor` is enabled
        // and this causes difficulities in scrolling transcrition lines
        // The following code is to avoid this problem. Refer to #101 for the detail.
        UITextView.appearance().textDragInteraction?.isEnabled = false
        UITextView.appearance().isScrollEnabled = false
    }

    var body: some View {
        ScrollViewReader { scrollReader in
            ScrollView {
                // Though LazyVStack is hopefully used,
                // FocusState changes to nil with it while scrolling,
                // thus normal VStack is used to avoid this.
                VStack(spacing: 0) {
                    ForEach(
                        Array(recognizedSpeech.transcriptionLines.enumerated()),
                        id: \.self.element.id
                    ) {
                        idx, transcriptionLine in
                        transcriptionLineRow(idx, transcriptionLine, scrollReader)
                    }
                }
            }
            .onAppear {
                initUpdateScrollTimer(scrollReader)
                initTranscriptionTexts()
            }
            .onDisappear { updateScrollTimer?.invalidate() }
        }
        .navigationBarBackButtonHidden(isEditing)
        .frame(
            minWidth: 0,
            maxWidth: .infinity,
            minHeight: 0,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .padding(.top)
        .toolbar {
            // The following `ToolBar` is only shown when `isEditing` is true,
            // but conditional clause cannot be used in `.toolbar` modifier until iOS16.
            // Thus whether `ToolBar` is shown or not is controlled inside it.
            EditingToolbar(
                isEditing: $isEditing,
                hasContentEdited: hasContentEdited,
                focusedTranscriptionLineId: _focusedTranscriptionLineId,
                updateTranscriptionLines: updateTranscriptionLines
            )
        }
    }

    func transcriptionLineRow(
        _ idx: Int,
        _ transcriptionLine: TranscriptionLine,
        _ scrollReader: ScrollViewProxy
    ) -> some View {
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
                        // The size of default `TextEditor` is somehow smaller
                        // than text box (`Text`), resulting text is hidden partialy.
                        // To make `TextEditor` the same size as `Text`,
                        // create `Text` that is not shown by setting opacity 0
                        // under `TextEditor`. Refer #102 for the detail.
                        ZStack {
                            Text(transcriptionLine.text)
                                .multilineTextAlignment(.leading)
                                .opacity(0)
                                .padding(9)

                            TextEditor(text: $editedTranscriptionTexts[idx])
                                .multilineTextAlignment(.leading)
                                .focused($focusedTranscriptionLineId, equals: transcriptionLine.id)
                        }
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
                    focusedTranscriptionLineId = transcriptionLine.id
                } label: {
                    Label(NSLocalizedString("編集", comment: ""), systemImage: "pencil")
                }

                Button {
                    UIPasteboard.general.string = transcriptionLine.text
                } label: {
                    Label(NSLocalizedString("コピー", comment: ""), systemImage: "doc.on.doc")
                }
            }
            Divider()
        }.id(idx)
    }

    var hasContentEdited: Bool {
        editedTranscriptionTexts != recognizedSpeech.transcriptionLines.map(\.text)
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

struct RecognizingTranscriptionLines: View {
    let recognizedSpeech: RecognizedSpeech
    var body: some View {
        ScrollViewReader { _ in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(recognizedSpeech.transcriptionLines.enumerated()), id: \.self.offset) {
                        idx, transcriptionLine in
                        Group {
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
                            .padding(10)
                            .background(Color(.systemBackground))
                            Divider()
                        }
                        .id(idx)
                    }
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .navigationBarTitle("", displayMode: .inline)
    }
}

struct TranscriptionLines_Previews: PreviewProvider {
    static var previews: some View {
        let recognizedSpeech: RecognizedSpeech! = getRecognizedSpeechMock(
            audioFileName: "sample_ja",
            csvFileName: "sample_ja"
        )
        let player = try! AVAudioPlayer(contentsOf: recognizedSpeech.audioFileURL)

        TranscriptionLines(
            recognizedSpeech: recognizedSpeech,
            player: .constant(player),
            currentPlayingTime: .constant(20.0),
            isEditing: .constant(true),
            focusedTranscriptionLineId: FocusState<UUID?>()
        )

        TranscriptionLines(
            recognizedSpeech: recognizedSpeech,
            player: .constant(player),
            currentPlayingTime: .constant(20.0),
            isEditing: .constant(true),
            focusedTranscriptionLineId: FocusState<UUID?>()
        )
    }
}
