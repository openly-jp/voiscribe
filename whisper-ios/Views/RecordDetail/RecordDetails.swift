import SwiftUI

struct RecordDetails: View {
    let recognizedSpeech: RecognizedSpeech
    let deleteRecognizedSpeech: (UUID) -> Void

    let isRecognizing: Bool
    func getLocaleDateString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateStyle = .medium
        dateFormatter.dateFormat = "yyyy年MM月dd日 HH:mm"

        return dateFormatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(getLocaleDateString(date: recognizedSpeech.createdAt))
                .foregroundColor(Color.gray)
                .padding(.horizontal)
            Title(recognizedSpeech: recognizedSpeech, isEditable: !isRecognizing)
            Rectangle()
                .frame(height: 2)
                .foregroundColor(Color.gray)
                .padding(.horizontal)
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
        }
    }
}

struct Title: View {
    var recognizedSpeech: RecognizedSpeech
    @State var editingTitle = ""
    @State var isEditing = false
    let isEditable: Bool
    @FocusState var isFocused: Bool

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
        let recognizedSpeech: RecognizedSpeech! = getRecognizedSpeechMock(audioFileName: "sample_ja", csvFileName: "sample_ja")
        NavigationView {
            RecordDetails(
                recognizedSpeech: recognizedSpeech,
                deleteRecognizedSpeech: { _ in },
                isRecognizing: false
            )
            .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro Max"))
        }

        NavigationView {
            RecordDetails(
                recognizedSpeech: recognizedSpeech,
                deleteRecognizedSpeech: { _ in },
                isRecognizing: false
            )
            .previewDevice(PreviewDevice(rawValue: "iPad Pro (12.9-inch) (4th generation)"))
            .previewDisplayName("ipad")
        }

        NavigationView {
            RecordDetails(
                recognizedSpeech: recognizedSpeech,
                deleteRecognizedSpeech: { _ in },
                isRecognizing: true
            )
            .previewDisplayName("Record Details (recognizing)")
        }
    }
}
