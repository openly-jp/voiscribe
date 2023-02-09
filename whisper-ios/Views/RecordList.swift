import SwiftUI

struct RecordList: View {
    @Binding var recognizingSpeechIds: [UUID]
    @Binding var recognizedSpeeches: [RecognizedSpeech]
    @Binding var isRecordDetailActives: [Bool]

    var body: some View {
        VStack {
            if recognizedSpeeches.count == 0 {
                Spacer()
                initialPage
                Spacer()
            } else {
                recordList
            }
            RecognitionPane(
                recognizingSpeechIds: $recognizingSpeechIds,
                recognizedSpeeches: $recognizedSpeeches,
                isRecordDetailActives: $isRecordDetailActives
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
                        deleteRecognizedSpeech: deleteRecognizedSpeech,
                        isRecognizing: recognizingSpeechIds.contains(recognizedSpeech.id)
                    )),
                    isActive: $isRecordDetailActives[idx]
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
            .onDelete(perform: deleteRecognizedSpeeches)
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

    private func deleteRecognizedSpeeches(indexSet: IndexSet) {
        for i in indexSet {
            deleteRecognizedSpeech(at: i)
        }
    }

    private func deleteRecognizedSpeech(at i: Int) {
        // RecognizedSpeech is inserted to recognizedSpeeches array right after
        // finishing recording, but saved to coredata after ASR is completed.
        if recognizingSpeechIds.contains(recognizedSpeeches[i].id) {
            recognizingSpeechIds.removeAll { id in id == recognizedSpeeches[i].id }
        } else {
            CoreDataRepository.deleteRecognizedSpeech(recognizedSpeech: recognizedSpeeches[i])
        }

        do {
            // TODO: fix this (issue #25)
            let fileName = recognizedSpeeches[i].audioFileURL.lastPathComponent
            let url = getURLByName(fileName: fileName)
            try FileManager.default.removeItem(at: url)
        } catch {
            Logger.error("Failed to remove audio file.")
        }
        recognizedSpeeches.remove(at: i)
        isRecordDetailActives.remove(at: i)
    }

    private func deleteRecognizedSpeech(id: UUID) {
        let at = recognizedSpeeches.firstIndex { rs in rs.id == id }
        if let at {
            deleteRecognizedSpeech(at: at)
        }
    }
}

class RecordList_Previews: PreviewProvider {
    static var previews: some View {
        let recognizedSpeech: RecognizedSpeech! = getRecognizedSpeechMock(
            audioFileName: "sample_ja",
            csvFileName: "sample_ja"
        )
        let recognizedSpeechs: [RecognizedSpeech] = [recognizedSpeech]
        Group {
            RecordList(
                recognizingSpeechIds: .constant([]),
                recognizedSpeeches: .constant(recognizedSpeechs),
                isRecordDetailActives: .constant([Bool](repeating: false, count: recognizedSpeechs.count))
            )
            .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro Max"))
            .previewDisplayName("iphone")

            RecordList(
                recognizingSpeechIds: .constant([]),
                recognizedSpeeches: .constant(recognizedSpeechs),
                isRecordDetailActives: .constant([Bool](repeating: false, count: recognizedSpeechs.count))
            )
            .previewDevice(PreviewDevice(rawValue: "iPad Pro (12.9-inch) (4th generation)"))
            .previewDisplayName("ipad")

            RecordList(
                recognizingSpeechIds: .constant([]),
                recognizedSpeeches: .constant([]),
                isRecordDetailActives: .constant([])
            )
            .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro Max"))
            .previewDisplayName("iphone no record")
        }
    }
}
