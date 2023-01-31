import SwiftUI

struct ToolBar: ToolbarContent {
    let recognizedSpeech: RecognizedSpeech
    @Binding var recognizedSpeeches: [RecognizedSpeech]

    let allTranscription: String
    @Binding var isEditing: Bool

    @State var isOpenDeleteAlert: Bool = false
    @Environment(\.presentationMode) var presentationMode

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button {
                isEditing = true
            } label: {
                Image(systemName: "highlighter")
                    .foregroundColor(Color(.label))
            }

            Menu {
                Button {
                    UIPasteboard.general.string = allTranscription
                } label: {
                    Label("全文をコピー", systemImage: "doc.on.doc")
                }
                Button(
                    role: .destructive,
                    action: { isOpenDeleteAlert = true },
                    label: {
                        Label("削除", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                )
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(Color(.label))
                    .rotationEffect(.degrees(90))
            }.alert(isPresented: $isOpenDeleteAlert) {
                Alert(
                    title: Text("削除しますか？"),
                    message: Text("データは完全に失われます。本当に削除しますか？"),
                    primaryButton: .cancel(Text("キャンセル")) { isOpenDeleteAlert = false },
                    secondaryButton: .destructive(Text("削除")) {
                        if let removeIdx = recognizedSpeeches.firstIndex(where: { $0.id == recognizedSpeech.id }) {
                            recognizedSpeeches.remove(at: removeIdx)
                            CoreDataRepository.deleteRecognizedSpeech(recognizedSpeech: recognizedSpeech)
                            presentationMode.wrappedValue.dismiss()
                        }
                        isOpenDeleteAlert = false
                    }
                )
            }
        }
    }
}
