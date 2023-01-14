import SwiftUI

struct ConfirmPane: View {
    let finishRecording: () -> Void
    let abortRecording: () -> Void

    @Binding var language: Language
    @Binding var title: String

    var body: some View {
        VStack {
            Text("録音を終了しますか？")
                .bold()
                .font(.title)
                .padding(.bottom, 40)

            VStack(alignment: .leading, spacing: 40) {
                TextField("タイトル", text: $title)
                    .font(.title3)
                VStack(alignment: .leading) {
                    Text("認識言語")
                    Picker("認識言語", selection: $language) {
                        ForEach(Language.allCases, id: \.self) { lang in
                            switch lang {
                            case Language.ja:
                                Text("日本語").tag(lang)
                            case Language.en:
                                Text("英語").tag(lang)
                            }
                        }
                    }
                    .pickerStyle(.segmented)
                }
                HStack(spacing: 30) {
                    Button("録音中止", action: abortRecording)
                        .foregroundColor(.red)
                    Spacer()
                    Button("終了", action: finishRecording)
                        .padding()
                        .accentColor(Color(.label))
                        .background(Color(.systemGray4))
                        .cornerRadius(5)
                        .colorInvert()
                }.padding(.top, 50)
            }
            .padding(.horizontal, 70)
        }
    }
}

struct ConfirmPane_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmPane(
            finishRecording: {},
            abortRecording: {},
            language: .constant(.ja),
            title: .constant("タイトル")
        )
    }
}
