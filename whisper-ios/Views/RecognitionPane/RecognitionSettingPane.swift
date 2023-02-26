import SwiftUI

struct RecognitionSettingPane: View {
    @EnvironmentObject var recognizer: WhisperRecognizer

    @AppStorage(userDefaultModelSizeKey) var defaultModelSize = Size()
    @AppStorage(userDefaultRecognitionLanguageKey) var defaultRecognitionLanguage = Language()

    let startAction: () -> Void
    let itemMinHeight: CGFloat = 50
    let itemCornerRadius: CGFloat = 20
    let itemColor = Color(uiColor: .systemGray5).opacity(0.8)

    @State var isRecognizingAlertOpen = false
    @State var isRecognitionPresetSelectionPaneOpen = false

    var body: some View {
        VStack(alignment: .center) {
            HStack {
                Group {
                    VStack(alignment: .leading) {
                        Text("モデル")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.secondary)
                        Text(defaultModelSize.displayName)
                            .font(.title)
                            .fontWeight(.medium)
                            .foregroundColor(Color.primary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
            }
            .frame(
                maxWidth: .infinity,
                minHeight: itemMinHeight,
                alignment: .leading
            )
            // this enable user to tap on Spacer
            .contentShape(Rectangle())
            .background(itemColor.clipShape(RoundedRectangle(cornerRadius: itemCornerRadius)))
            .padding(.horizontal)
            .onTapGesture {
                if recognizer.isRecognizing {
                    isRecognizingAlertOpen = true
                } else {
                    isRecognitionPresetSelectionPaneOpen = true
                }
            }
            HStack {
                Group {
                    VStack(alignment: .leading) {
                        Text("認識言語")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.secondary)
                        Text(defaultRecognitionLanguage.displayName)
                            .font(.title)
                            .fontWeight(.medium)
                            .foregroundColor(Color.primary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
            }
            .frame(
                maxWidth: .infinity,
                minHeight: itemMinHeight,
                alignment: .leading
            )
            // this enable user to tap on Spacer
            .contentShape(Rectangle())
            .background(itemColor.clipShape(RoundedRectangle(cornerRadius: itemCornerRadius)))
            .padding(.horizontal)
            .onTapGesture {
                if recognizer.isRecognizing {
                    isRecognizingAlertOpen = true
                } else {
                    isRecognitionPresetSelectionPaneOpen = true
                }
            }
            Button(action: {
                startAction()
            }) {
                Text("録音開始")
                    .font(.title3)
                    .frame(
                        maxWidth: .infinity
                    )
            }
            .buttonStyle(.borderedProminent)
            .padding()
            .sheet(isPresented: $isRecognitionPresetSelectionPaneOpen) {
                RecognitionPresetPane()
            }
            .alert(isPresented: $isRecognizingAlertOpen) {
                Alert(
                    title: Text("認識中はモデルを変更できません。"),
                    message:
                    Text("現在の認識終了後にモデルを変更してください。"),
                    dismissButton: .default(Text("了解"))
                )
            }
        }
    }
}

struct RecognitionSettingSheet_Previews: PreviewProvider {
    static var previews: some View {
        RecognitionSettingPane(
            startAction: {}
        )
    }
}
