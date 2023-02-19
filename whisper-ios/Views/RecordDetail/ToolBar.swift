import AVFoundation
import SwiftUI
import UIKit

struct ToolBar: ToolbarContent {
    let recognizedSpeech: RecognizedSpeech
    let deleteRecognizedSpeech: (UUID) -> Void

    let allTranscription: String
    @Binding var isEditing: Bool

    @State var isOpenDeleteAlert: Bool = false
    @State var isOpenShareSheetm4a: Bool = false
    @State var isOpenShareSheettxt: Bool = false
    @Environment(\.presentationMode) var presentationMode

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if !isEditing {
                Button {
                    isEditing = true
                } label: {
                    Image(systemName: "highlighter")
                        .foregroundColor(Color(.label))
                }
                
                Menu {
                    Button(
                        action: { isOpenShareSheettxt = true },
                        label: {
                            Label("テキストを共有", systemImage: "textformat.alt")
                        }
                    )
                    Button(
                        action: { isOpenShareSheetm4a = true },
                        label: {
                            Label("音声を共有", systemImage: "waveform")
                        }
                    )
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(Color(.label))
                }
                .sheet(isPresented: $isOpenShareSheettxt) {
                    ActivityViewTXT(text: allTranscription)
                }
                .sheet(isPresented: $isOpenShareSheetm4a) {
                    ActivityViewM4A(recognizedSpeech: recognizedSpeech)
                }

                Menu {
                    Button(
                        action: { UIPasteboard.general.string = allTranscription },
                        label: {
                            Label("テキストをコピー", systemImage: "doc.on.doc")
                        }
                    )
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
                }
                .alert(isPresented: $isOpenDeleteAlert) {
                    Alert(
                        title: Text("削除しますか？"),
                        message: Text("データは完全に失われます。本当に削除しますか？"),
                        primaryButton: .cancel(Text("キャンセル")) { isOpenDeleteAlert = false },
                        secondaryButton: .destructive(Text("削除")) {
                            deleteRecognizedSpeech(recognizedSpeech.id)
                            presentationMode.wrappedValue.dismiss()
                            isOpenDeleteAlert = false
                        }
                    )
                }
            }
        }
    }
}

struct ActivityViewTXT: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context _: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_: UIActivityViewController, context _: Context) {}
}

struct ActivityViewM4A: UIViewControllerRepresentable {
    let recognizedSpeech: RecognizedSpeech

    func makeUIViewController(context _: Context) -> UIActivityViewController {
        let fileURL = getURLByName(fileName: "\(recognizedSpeech.id.uuidString).m4a")

        return UIActivityViewController(activityItems: ["audio file", fileURL], applicationActivities: nil)
    }

    func updateUIViewController(_: UIActivityViewController, context _: Context) {}
}

struct EditingToolbar: ToolbarContent {
    @Binding var isEditing: Bool
    let hasContentEdited: Bool
    @FocusState var focusedTranscriptionLineId: UUID?
    @State var isOpenCancelAlert: Bool = false
    let updateTranscriptionLines: () -> Void

    var body: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                if isEditing {
                    Button("キャンセル") {
                        if hasContentEdited { isOpenCancelAlert = true }
                        else { isEditing = false; focusedTranscriptionLineId = nil }
                    }.alert(isPresented: $isOpenCancelAlert) {
                        Alert(
                            title: Text("変更を破棄しますか？"),
                            message: Text("変更は完全に失われます。変更を破棄しますか？"),
                            primaryButton: .cancel(Text("キャンセル")) { isOpenCancelAlert = false },
                            secondaryButton: .destructive(Text("変更を破棄")) {
                                isOpenCancelAlert = false
                                isEditing = false
                                focusedTranscriptionLineId = nil
                            }
                        )
                    }
                }
            }

            ToolbarItem(placement: .principal) {
                if isEditing {
                    Text("書き起こし編集")
                        .foregroundColor(Color(.label))
                        .font(.title3)
                        .bold()
                        .padding()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditing {
                    Button("保存") {
                        updateTranscriptionLines()

                        isEditing = false
                        focusedTranscriptionLineId = nil
                    }
                }
            }
        }
    }
}
