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
    @State var currentLineIdx: Int = 0

    init(
        recognizedSpeech: RecognizedSpeech,
        isRecognizing: Bool
    ) {
        self.recognizedSpeech = recognizedSpeech
        self.isRecognizing = isRecognizing

        // TODO: fix this (issue #25)
        let url = getURLByName(fileName: recognizedSpeech.audioFileURL.lastPathComponent)
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
                HStack {
                    Spacer()
                    Text("認識中")
                    Spacer()
                }
                Spacer()
            } else {
                ScrollView{
                    ForEach(Array(recognizedSpeech.transcriptionLines.enumerated()), id: \.self.offset) {
                        idx, transcriptionLine in
                        Group{
                            HStack(alignment: .center){
                                Button {
                                    player.currentTime = Double(transcriptionLine.startMSec) / 1000
                                    currentPlayingTime = Double(transcriptionLine.startMSec) / 1000
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
                        }.background(getTextColor(idx))
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                .padding()
                .navigationBarTitle("", displayMode: .inline)
                AudioPlayer(player: $player, currentPlayingTime: $currentPlayingTime)
                    .padding(20)
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
}

class RecordDetails_Previews: PreviewProvider {
    static var previews: some View {
        let recognizedSpeech: RecognizedSpeech! = getRecognizedSpeechMock(audioFileName: "sample_ja", csvFileName: "sample_ja")
        RecordDetails(recognizedSpeech: recognizedSpeech, isRecognizing: false)
    }
}
