import SwiftUI

struct RecordDetails: View {
    let recognizedSpeech: RecognizedSpeech?
    
    init(id: UUID) {
        self.recognizedSpeech = recognizedSpeechMocks[id]
    }
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
        if recognizedSpeech == nil {
            Text("データの取得に失敗しました")
        } else {
            VStack(alignment: .leading){
                Text(getLocaleDateString(date: recognizedSpeech!.createdAt))
                    .foregroundColor(Color.gray)
                Text(recognizedSpeech!.title)
                    .font(.title)
                    .fontWeight(.bold)
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(Color.gray)
                ForEach(recognizedSpeech!.transcriptionLines) {
                    transcriptionLine in
                    HStack(alignment: .top){
                        Text(getStartTimeStringFromMsec(startMsec: transcriptionLine.startMSec))
                            .frame(width: 50)
                            .foregroundColor(Color.blue)
                            .padding()
                        Text(transcriptionLine.text)
                            .padding()
                    }
                    Divider()
                }
            }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
            .padding()    }
    }
}

class RecordDetails_Previews: PreviewProvider {
    static var previews: some View {
        let recognizedSpeechId: UUID = Array(recognizedSpeechMocks.keys)[0]
        RecordDetails(id: recognizedSpeechId)
    }
}
