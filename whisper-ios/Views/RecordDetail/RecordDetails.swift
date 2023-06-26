import SwiftUI

struct RecordDetails: View {
    let recognizedSpeech: RecognizedSpeech
    let deleteRecognizedSpeech: (UUID) -> Void

    @EnvironmentObject var recognitionManager: RecognitionManager

    var isRecognizing: Bool { recognitionManager.isRecognizing(recognizedSpeech.id) }

    func getLocaleDateString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: NSLocalizedString("ロケール", comment: ""))
        dateFormatter.dateStyle = .medium
        dateFormatter.dateFormat = NSLocalizedString("日付フォーマット", comment: "")

        return dateFormatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(getLocaleDateString(date: recognizedSpeech.createdAt))
                .foregroundColor(Color.gray)
                .padding(.horizontal)

            if isRecognizing {
                RecognizingTitleBar(
                    recognizer: recognitionManager.getRecognizer(recognizedSpeech.id),
                    recognizedSpeech: recognizedSpeech
                )
            } else {
                StandardTitleBar(recognizedSpeech: recognizedSpeech)
            }

            if !isRecognizing, recognizedSpeech.transcriptionLines.count == 0 {
                Spacer()
                NoRecognitionView()
                Spacer()
            } else {
                RecognitionPlayer(
                    recognizedSpeech: recognizedSpeech,
                    deleteRecognizedSpeech: deleteRecognizedSpeech,
                    isRecognizing: isRecognizing
                )
            }
        }.navigationBarTitleDisplayMode(.inline)
    }
}

struct RecognizingTitleBar: View {
    @ObservedObject var recognizer: WhisperRecognizer
    let recognizedSpeech: RecognizedSpeech

    var progressString: String {
        String(format: "%d", Int(recognizer.progressRate * 100))
    }

    var body: some View {
        VStack {
            HStack(alignment: .bottom) {
                Title(recognizedSpeech: recognizedSpeech, isEditable: false)
                Spacer()
                Text("認識中...(\(progressString)%終了)")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            }
            ProgressView(value: recognizer.progressRate)
                .padding(.horizontal)
        }
    }
}

struct StandardTitleBar: View {
    let recognizedSpeech: RecognizedSpeech

    var body: some View {
        VStack {
            HStack(alignment: .bottom) {
                Title(recognizedSpeech: recognizedSpeech, isEditable: true)
                Spacer()
            }
            ProgressView(value: 0).padding(.horizontal)
        }
    }
}

struct Title: View {
    var recognizedSpeech: RecognizedSpeech
    @State var editingTitle = ""
    @State var isEditing = false
    let isEditable: Bool
    @FocusState var isFocused: Bool

    @State var isNotEditableAlertOpen = false

    var body: some View {
        if isEditable, isEditing {
            TextField(editingTitle, text: $editingTitle)
                .focused($isFocused)
                .font(.title.weight(.bold))
                .padding(.horizontal)
                .submitLabel(.done)
                .onSubmit {
                    isEditing = false
                    recognizedSpeech.title = editingTitle
                    isFocused = false

                    RecognizedSpeechData.update(recognizedSpeech)
                }
        } else if isEditable {
            Text(recognizedSpeech.title)
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal)
                .padding(1)
                .onTapGesture {
                    editingTitle = recognizedSpeech.title
                    isEditing = true
                    isFocused = true
                }
        } else {
            // when recognition is on going, RecognizedSpeech hasn't saved to coredata yet
            // to avoid crash, prohibit to edit title
            Text(recognizedSpeech.title)
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal)
                .padding(1)
                .onTapGesture {
                    isNotEditableAlertOpen = true
                }
                .alert(isPresented: $isNotEditableAlertOpen) {
                    Alert(title: Text("認識中は編集できません"),
                          message: Text("認識終了後に再度お試しください"),
                          dismissButton: .default(Text("了解")))
                }
        }
    }
}

struct NoRecognitionView: View {
    var body: some View {
        Group {
            HStack { Spacer(); Text("申し訳ございません。"); Spacer() }
            HStack { Spacer(); Text("認識結果がありません。"); Spacer() }
            HStack { Spacer(); Text("もう一度認識をお願いいたします。"); Spacer() }
        }
    }
}

class RecordDetails_Previews: PreviewProvider {
    static var previews: some View {
        let recognizedSpeech: RecognizedSpeech! = getRecognizedSpeechMock(
            audioFileName: "sample_ja",
            csvFileName: "sample_ja"
        )
        NavigationView {
            RecordDetails(
                recognizedSpeech: recognizedSpeech,
                deleteRecognizedSpeech: { _ in }
            )
        }
        .previewDevice(PreviewDevice(rawValue: "iPhone 12 mini"))
        .previewDisplayName("iPhone 12")

        NavigationView {
            RecordDetails(
                recognizedSpeech: recognizedSpeech,
                deleteRecognizedSpeech: { _ in }
            )
        }
        .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro Max"))
        .previewDisplayName("iPhone 14")

        NavigationView {
            RecordDetails(
                recognizedSpeech: recognizedSpeech,
                deleteRecognizedSpeech: { _ in }
            )
        }
        .previewDevice(PreviewDevice(rawValue: "iPad Pro (12.9-inch) (4th generation)"))
        .previewDisplayName("ipad")

        NavigationView {
            RecordDetails(
                recognizedSpeech: recognizedSpeech,
                deleteRecognizedSpeech: { _ in }
            )
        }
        .previewDisplayName("Record Details (recognizing)")
    }
}
