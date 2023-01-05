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
    @State var player: AVAudioPlayer

    init(
        recognizedSpeech: RecognizedSpeech,
        isRecognizing: Bool
    ) {
        let rs = recognizedSpeech
        self.recognizedSpeech = recognizedSpeech
        self.isRecognizing = isRecognizing

        // TODO: fix this (issue #25)
        let url = getURLByName(fileName: recognizedSpeech.audioFileURL.lastPathComponent)
        player = try! AVAudioPlayer(contentsOf: url)
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
                Text("認識中")
            } else {
                ScrollView{
                    ForEach(recognizedSpeech.transcriptionLines) {
                        transcriptionLine in
                        HStack(alignment: .center){
                            Button {
                                player.currentTime = Double(transcriptionLine.startMSec) / 1000
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
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                .padding()
                .navigationBarTitle("", displayMode: .inline)
                AudioPlayer(player: $player)
                    .padding(20)
            }
        }
    }
}

class RecordDetails_Previews: PreviewProvider {
    static var previews: some View {
        let recognizedSpeech: RecognizedSpeech! = getRecognizedSpeechMock(audioFileName: "sample_ja", csvFileName: "sample_ja")
        RecordDetails(recognizedSpeech: recognizedSpeech, isRecognizing: false)
    }
}
