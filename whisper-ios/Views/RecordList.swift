import SwiftUI

struct RecordList: View {
    let recognizedSpeechs: [RecognizedSpeech]
    init (){
        self.recognizedSpeechs = Array(recognizedSpeechMocks.values)
    }
    func getLocaleDateString(date: Date) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateStyle = .medium
        dateFormatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        
        return dateFormatter.string(from: date)
    }
    var body: some View {
        NavigationView {
            List(recognizedSpeechs) { recognizedSpeech in
                NavigationLink(destination: RecordDetails(id: recognizedSpeech.id)) {
                    HStack{
                        Image(systemName: "mic.square.fill")
                            .resizable()
                            .frame(width: 30.0, height: 30.0)
                            .padding()
                        VStack(alignment: .leading) {
                            Text(recognizedSpeech.title).font(.headline)
                            Text(recognizedSpeech.transcriptionLines[0].text).lineLimit(1).font(.subheadline)
                            Text(getLocaleDateString(date: recognizedSpeech.createdAt))
                                .foregroundColor(Color.gray)
                        }
                    }
                }
            }.listStyle(PlainListStyle())
            .navigationBarTitle("Notes")
            
        }
    }
}

class RecordList_Previews: PreviewProvider {
    static var previews: some View {
        RecordList()
    }
}
