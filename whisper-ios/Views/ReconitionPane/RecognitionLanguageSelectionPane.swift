import SwiftUI

struct RecognitionLanguageSelectionPane: View {
    var body: some View {
        VStack(alignment: .leading) {
            Spacer().frame(height: 30)
            HStack {
                Text("認識言語選択")
                    .font(.title)
                    .fontWeight(.bold)
                    // this force the alignment center
                    .frame(maxWidth: .infinity)
            }

            ForEach(Language.allCases) { language in
                RecognitionLanguageSelectionRow(language: language)
                Divider()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct RecognitionLanguageSelectionRow: View {
    let language: Language
    @AppStorage(UserDefaultASRLanguageKey) var defaultLanguageRawValue = Language.en.rawValue

    var body: some View {
        HStack {
            Image(systemName: defaultLanguageRawValue == language.rawValue ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .offset(x: 5)
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .green)
            Text(language.displayName)
                .font(.title2)
                .fontWeight(.medium)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.leading)
        // this enable user to tap on Spacer
        .contentShape(Rectangle())
        .onTapGesture {
            if defaultLanguageRawValue != language.rawValue {
                defaultLanguageRawValue = language.rawValue
            }
        }
    }
}

struct RecognitionLanguageSelectionPane_Previews: PreviewProvider {
    static var previews: some View {
        RecognitionLanguageSelectionPane()
    }
}
