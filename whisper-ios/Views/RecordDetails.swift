import SwiftUI

struct RecordDetails: View {
    let recognizedSpeech: RecognizedSpeech
    let isRecognizing: Bool
    let recognizedSpeech2: RecognizedSpeech! = getRecognizedSpeechMock(audioFileName: "sample_ja", csvFileName: "sample_ja")
    func getLocaleDateString(date: Date) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateStyle = .medium
        dateFormatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        
        return dateFormatter.string(from: date)
    }
    func getStartTimeStringFromMsec(startMsec: Int64) -> String {
        let min = startMsec / 1000 / 60
        let sec = startMsec / 1000 - (min * 60)
        return String(format: "%02d:%02d", min, sec)
    }
    var body: some View {
        if isRecognizing {
            Text("認識中")
        } else {
            VStack(alignment: .leading){
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
                ScrollView{
                    ForEach(recognizedSpeech.transcriptionLines) {
                        transcriptionLine in
                        HStack(alignment: .center){
                            Text(getStartTimeStringFromMsec(startMsec: transcriptionLine.startMSec))
                                .frame(width: 50, alignment: .center)
                                .foregroundColor(Color.blue)
                                .padding()
                            Spacer()
                            Text(transcriptionLine.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Divider()
                    }
                }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                    .padding()
                    .navigationBarTitle("", displayMode: .inline)
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
