import SwiftUI

struct RecordDetails: View {
    let recognizedSpeech: RecognizedSpeech
    
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
        VStack(alignment: .leading){
            Text(getLocaleDateString(date: recognizedSpeech.createdAt))
                .foregroundColor(Color.gray)
            Text(recognizedSpeech.title)
                .font(.title)
                .fontWeight(.bold)
            Rectangle()
                .frame(height: 2)
                .foregroundColor(Color.gray)
            ForEach(recognizedSpeech.transcriptionLines) {
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
        .padding()
        .navigationBarTitle("", displayMode: .inline)
    }
}

class RecordDetails_Previews: PreviewProvider {
    static var previews: some View {
        let recognizedSpeech: RecognizedSpeech! = Array(recognizedSpeechMocks.values)[0]
        RecordDetails(recognizedSpeech: recognizedSpeech)
    }
}
