import AVFoundation
import SwiftUI

struct RecordDetails: View {
    let recognizedSpeech: RecognizedSpeech
    let isRecognizing: Bool
    func getLocaleDateString(date: Date) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateStyle = .medium
        dateFormatter.dateFormat = "yyyy年MM月dd日 HH:mm"

        return dateFormatter.string(from: date)
    }

    // MARK: - state about player
    @State var player: AVAudioPlayer
    @State var currentPlayingTime: Double = 0

    // MARK: - timer to update automatic scroll
    // this is initialized in .onAppear method
    @State var updateScrollTimer: Timer?

    init(
        recognizedSpeech: RecognizedSpeech,
        isRecognizing: Bool
    ) {
        self.recognizedSpeech = recognizedSpeech
        self.isRecognizing = isRecognizing

        // TODO: fix this (issue #25)
        let url = getURLByName(fileName: recognizedSpeech.audioFileURL.lastPathComponent)

        let session = AVAudioSession.sharedInstance()
        try! session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
        try! session.setActive(true)
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player.enableRate = true
        } catch {
            player = try! AVAudioPlayer()
            debugPrint("fail to init audio player")
        }
    }

    var body: some View {
        return VStack(alignment: .leading){
            Text(getLocaleDateString(date: recognizedSpeech.createdAt))
                .foregroundColor(Color.gray)
                .padding(.horizontal)
            Text(recognizedSpeech.title)
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal)
            Rectangle()
                .frame(height: 2)
                .foregroundColor(Color.gray)
                .padding(.horizontal)
            if isRecognizing {
                Spacer()
                RecognizingView()
                Spacer()
            } else if recognizedSpeech.transcriptionLines.count == 0 {
                Spacer()
                Group {
                    HStack { Spacer(); Text("申し訳ございません。"); Spacer() }
                    HStack { Spacer(); Text("認識結果がありません。"); Spacer() }
                    HStack { Spacer(); Text("もう一度認識をお願いいたします。"); Spacer() }
                }.foregroundColor(.red)
                Spacer()
            } else {
                ScrollViewReader { scrollReader in
                    ScrollView {
                        LazyVStack{
                            ForEach(Array(recognizedSpeech.transcriptionLines.enumerated()), id: \.self.offset) {
                                idx, transcriptionLine in
                                Group{
                                    HStack(alignment: .center){
                                        Button {
                                            // actual currentTime become earlier than the specified time
                                            // e.g. player.currentTime = 1.25 -> actually player.currentTime shows 1.245232..
                                            // thus previous transcription line is highlighted uncorrectly
                                            // 0.1 is added to avoid this
                                            let updatedTime = Double(transcriptionLine.startMSec) / 1000 + 0.1
                                            player.currentTime = updatedTime
                                            currentPlayingTime = updatedTime
                                            withAnimation (.easeInOut){ scrollReader.scrollTo(idx) }
                                        } label: {
                                            Text(formatTime(Double(transcriptionLine.startMSec) / 1000))
                                                .frame(width: 50, alignment: .center)
                                                .foregroundColor(Color.blue)
                                                .padding()
                                        }
                                        Spacer()
                                        Text(transcriptionLine.text)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    Divider()
                                }
                                .background(getTextColor(idx))
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
                AudioPlayer(player: $player, currentPlayingTime: $currentPlayingTime)
                    .padding(20)
            }
        }
    }

    func initUpdateScrollTimer(_ scrollReader: ScrollViewProxy) {
        updateScrollTimer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true
        ) { _ in
            if player.isPlaying {
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

    func getCurrentTranscriptionIndex() -> Int {
        let lines = recognizedSpeech.transcriptionLines
        for idx in 0..<lines.count {
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

    func getTextColor(_ idx: Int) -> Color {
        let lines = recognizedSpeech.transcriptionLines
        let startMSec = Double(lines[idx].startMSec)
        let endMSec: Double = idx < lines.count - 1 ? Double(lines[idx + 1].startMSec) : .infinity
        let currentMSec = currentPlayingTime * 1000
        let isInside = startMSec <= currentMSec && currentMSec < endMSec
        let uiColor: UIColor = isInside ? .systemGray5 : .systemBackground
        return Color(uiColor)
    }
}

class RecordDetails_Previews: PreviewProvider {
    static var previews: some View {
        let recognizedSpeech: RecognizedSpeech! = getRecognizedSpeechMock(audioFileName: "sample_ja", csvFileName: "sample_ja")
        RecordDetails(recognizedSpeech: recognizedSpeech, isRecognizing: false)
    }
}

struct RecognizingView: View {
    var body: some View {
        HStack {
            Spacer()
            ProgressView()
                .scaleEffect(2)
                .padding(30)
            Spacer()
        }
        HStack {
            Spacer()
            Text("認識中")
            Spacer()
        }
    }
}
