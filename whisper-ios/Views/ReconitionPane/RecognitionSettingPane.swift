import SwiftUI

struct RecognitionSettingPane: View {
    @AppStorage(userDefaultModelSizeKey) var defaultModelSize = Size(rawValue: "tiny")!
    @AppStorage(UserDefaultASRLanguageKey) var defaultLanguageRawValue = Language.en.rawValue

    let startAction: () -> Void
    let itemMinHeight: CGFloat = 50
    let itemCornerRadius: CGFloat = 20
    let itemColor = Color(uiColor: .systemGray5).opacity(0.8)

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
                isRecognitionPresetSelectionPaneOpen = true
            }
            HStack {
                Group {
                    VStack(alignment: .leading) {
                        Text("認識言語")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.secondary)
                        Text(Language(rawValue: defaultLanguageRawValue)!.displayName)
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
                isRecognitionPresetSelectionPaneOpen = true
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
