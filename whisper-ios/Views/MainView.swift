import SwiftUI

struct MainView: View {
    @State var recognizingSpeechIds: [UUID]
    @State var recognizedSpeeches: [RecognizedSpeech]
    @State var isActives: [Bool]

    init() {
        let initialRecognizedSpeeches = CoreDataRepository.getAllRecognizedSpeeches()
        recognizingSpeechIds = []
        recognizedSpeeches = initialRecognizedSpeeches
        isActives = [Bool](repeating: false, count: initialRecognizedSpeeches.count)
    }

    var body: some View {
        VStack(spacing: 0) {
            if recognizedSpeeches.count == 0 {
                Spacer()
                initialPage
                Spacer()
            } else {
                recordList
            }
            Spacer()
            RecognitionPane(
                recognizingSpeechIds: $recognizingSpeechIds,
                recognizedSpeeches: $recognizedSpeeches,
                isActives: $isActives
            )
        }
    }

    var initialPage: some View {
        VStack(spacing: 5) {
            Text("音声認識をはじめましょう")
                .font(.title2)
                .bold()
                .padding(10)
            Image("initialPage")
                .resizable()
                .scaledToFill()
                .frame(width: 220, height: 220)
            Text("下のボタンから音声の録音を開始しましょう。\n認識結果は一覧から閲覧可能です。")
                .multilineTextAlignment(.center)
                .padding(10)
        }
    }

    var recordList: some View {
        List {
            ForEach(Array(recognizedSpeeches.enumerated()), id: \.element.id) { idx, recognizedSpeech in
                NavigationLink(
                    destination: LazyView(RecordDetails(
                        recognizedSpeech: recognizedSpeech,
                        isRecognizing: recognizingSpeechIds.contains(recognizedSpeech.id)
                    )),
                    isActive: $isActives[idx]
                ) {
                    HStack {
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
                                    HStack(spacing: 2) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                        Text("認識結果なし")
                                    }.foregroundColor(Color.red)
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
    }

    private func getLocaleDateString(date: Date) -> String {
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

class MainView_Previews: PreviewProvider {
    static var previews: some View {
        let recognizedSpeech: RecognizedSpeech! = getRecognizedSpeechMock(audioFileName: "sample_ja", csvFileName: "sample_ja")
        let recognizedSpeechs: [RecognizedSpeech] = [recognizedSpeech]
        Group {
            MainView()
            .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro Max"))
            .previewDisplayName("iphone")

            MainView()
            .previewDevice(PreviewDevice(rawValue: "iPad Pro (12.9-inch) (4th generation)"))
            .previewDisplayName("ipad")

            MainView()
            .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro Max"))
            .previewDisplayName("iphone no record")
        }
    }
}
