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
                VStack(alignment: .leading) {
                    Text("認識モデル")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.secondary)
                    Text(defaultModelSize.displayName)
                        .font(.title)
                        .fontWeight(.medium)
                        .foregroundColor(Color.primary)
                }
                .padding()
                Spacer()
                Image(systemName: "chevron.right")
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
                VStack(alignment: .leading) {
                    Text("認識言語")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.secondary)
                    Text(NSLocalizedString(defaultRecognitionLanguage.displayName, comment: ""))
                        .font(.title)
                        .fontWeight(.medium)
                        .foregroundColor(Color.primary)
                }
                .padding()
                Spacer()
                Image(systemName: "chevron.right")
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
                RecognitionPresetPane(isRecognitionPresetSelectionPaneOpen: $isRecognitionPresetSelectionPaneOpen)
                    .environmentObject(recognizer)
            }
            .alert(isPresented: $isRecognizingAlertOpen) {
                Alert(
                    title: Text("現在はモデルを変更できません"),
                    message:
                    Text("録音は行えます"),
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
