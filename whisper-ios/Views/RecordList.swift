import SwiftUI

struct RecordList: View {
    @Binding var recognizedSpeeches: [RecognizedSpeech]

    func getLocaleDateString(date: Date) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateStyle = .medium
        dateFormatter.dateFormat = "yyyy年MM月dd日 HH:mm"

        return dateFormatter.string(from: date)
    }
    var body: some View {
        NavigationView {
            List {
                ForEach(recognizedSpeeches, id: \.self.id) { recognizedSpeech in
                    NavigationLink(destination: RecordDetails(recognizedSpeech: recognizedSpeech)) {
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
                }
                .onDelete(perform: deleteRecognizedSpeech)
            }
            .listStyle(PlainListStyle())
            .navigationBarTitle("Notes")
        }
    }

    private func deleteRecognizedSpeech(indexSet: IndexSet) {
        for i in indexSet {
            CoreDataRepository.deleteRecognizedSpeech(recognizedSpeech: recognizedSpeeches[i])
        }
        recognizedSpeeches.remove(atOffsets: indexSet)
    }
}

class RecordList_Previews: PreviewProvider {
    static var previews: some View {
        let recognizedSpeech: RecognizedSpeech! = getRecognizedSpeechMock(audioFileName: "sample_ja", csvFileName: "sample_ja")
        let recognizedSpeechs: [RecognizedSpeech] = [recognizedSpeech]
        RecordList(recognizedSpeeches: .constant(recognizedSpeechs))
    }
}
