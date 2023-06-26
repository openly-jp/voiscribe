import AVFoundation
import SwiftUI

struct MainView: View {
    @State var recognizedSpeeches: [RecognizedSpeech]
    @State var isRecordDetailActives: [Bool]
    @EnvironmentObject var recognitionManager: RecognitionManager

    init() {
        let initialRecognizedSpeeches = CoreDataRepository.getAllRecognizedSpeeches()
        recognizedSpeeches = initialRecognizedSpeeches
        isRecordDetailActives = [Bool](repeating: false, count: initialRecognizedSpeeches.count)

        let session = AVAudioSession.sharedInstance()
        try! session.setCategory(
            .playAndRecord,
            mode: .default,
            options: [.mixWithOthers, .defaultToSpeaker, .allowBluetooth]
        )
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
            Text(NSLocalizedString("はじめの指示", comment: ""))
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
                        deleteRecognizedSpeech: deleteRecognizedSpeech
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
                            if recognitionManager.isRecognizing(recognizedSpeech.id) {
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
        dateFormatter.dateFormat = NSLocalizedString("日付フォーマット", comment: "")

        return dateFormatter.string(from: date)
    }

    private func deleteRecognizedSpeeches(indexSet: IndexSet) {
        for i in indexSet {
            deleteRecognizedSpeech(at: i)
        }
    }

    private func deleteRecognizedSpeech(at i: Int) {
        func cleanUp() {
            CoreDataRepository.deleteRecognizedSpeech(recognizedSpeech: recognizedSpeeches[i])
            do {
                // TODO: fix this (issue #25)
                let fileName = recognizedSpeeches[i].audioFileURL.lastPathComponent
                let url = getURLByName(fileName: fileName)
                try FileManager.default.removeItem(at: url)
            } catch {
                Logger.error("Failed to remove audio file.")
            }
        }

        if recognitionManager.isRecognizing(recognizedSpeeches[i].id) {
            recognitionManager.abortRecognition(
                recognizingSpeech: recognizedSpeeches[i],
                cleanUp: cleanUp
            )
        } else {
            cleanUp()
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

class MainView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MainView()
                .previewDevice(PreviewDevice(rawValue: "iPad Air (4th generation"))
                .previewDisplayName("ipad air")

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
