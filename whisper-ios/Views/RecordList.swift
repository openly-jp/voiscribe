import SwiftUI

struct RecordList: View {
    @Binding var recognizingSpeechIds: [UUID]
    @Binding var recognizedSpeeches: [RecognizedSpeech]
    @Binding var isActives: [Bool]

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(Array(recognizedSpeeches.enumerated()), id: \.element.id) { idx, recognizedSpeech in
                        NavigationLink(
                            destination: LazyView(RecordDetails(
                                recognizedSpeech: recognizedSpeech,
                                isRecognizing: recognizingSpeechIds.contains(recognizedSpeech.id)
                            )),
                            isActive: $isActives[idx]
                        ) {
                            HStack{
                                Image(systemName: "mic.square.fill")
                                    .resizable()
                                    .frame(width: 30.0, height: 30.0)
                                    .padding()

                                VStack(alignment: .leading) {
                                    Text(recognizedSpeech.title).font(.headline)
                                    if recognizingSpeechIds.contains(recognizedSpeech.id) {
                                        Text("認識中").foregroundColor(.red)
                                    } else {
                                        if recognizedSpeech.transcriptionLines.count > 0 {
                                            Text(recognizedSpeech.transcriptionLines[0].text).lineLimit(1).font(.subheadline)
                                        } else {
                                            Text("認識結果なし")
                                                .foregroundColor(Color.red)
                                        }
                                    }
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
                RecognitionPane(
                    recognizingSpeechIds: $recognizingSpeechIds,
                    recognizedSpeeches: $recognizedSpeeches,
                    isActives: $isActives
                )
            }
        }

    }
    
    private func getLocaleDateString(date: Date) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateStyle = .medium
        dateFormatter.dateFormat = "yyyy年MM月dd日 HH:mm"

        return dateFormatter.string(from: date)
    }
    
    private func deleteRecognizedSpeech(indexSet: IndexSet) {
        for i in indexSet {
            CoreDataRepository.deleteRecognizedSpeech(recognizedSpeech: recognizedSpeeches[i])
        }
        recognizedSpeeches.remove(atOffsets: indexSet)
        isActives.remove(atOffsets: indexSet)
    }
}

class RecordList_Previews: PreviewProvider {
    static var previews: some View {
        let recognizedSpeech: RecognizedSpeech! = getRecognizedSpeechMock(audioFileName: "sample_ja", csvFileName: "sample_ja")
        let recognizedSpeechs: [RecognizedSpeech] = [recognizedSpeech]
        RecordList(
            recognizingSpeechIds: .constant([]),
            recognizedSpeeches: .constant(recognizedSpeechs),
            isActives: .constant(Array<Bool>(repeating: false, count: recognizedSpeechs.count))
        )
    }
}
