import SwiftUI

struct LanguageSelectMenuItemView: View {
    var body: some View {
        HStack {
            Image(systemName: "character.book.closed.fill")
                .imageScale(.large)
                .frame(width: 32)
            Text("認識言語")
                .font(.headline)
            Spacer()
        }
    }
}

struct LanguageSelectSubMenuItemView: View {
    let language: Language
    let languageDisplayName: String
    @AppStorage(userDefaultRecognitionLanguageKey) var defaultRecognitionLanguage = Language()

    var body: some View {
        HStack {
            if defaultRecognitionLanguage == language {
                Image(systemName: "checkmark.circle.fill")
                    .imageScale(.large)
            } else {
                Image(systemName: "circle")
                    .imageScale(.large)
            }
            Text(languageDisplayName)
                .font(.headline)
            Spacer()
        }
        .onTapGesture(perform: {
            if defaultRecognitionLanguage != language {
                defaultRecognitionLanguage = language
            }
        })
    }
}

let languageSelectSubMenuItems = [
    MenuItem(
        view: AnyView(LanguageSelectSubMenuItemView(language: Language.en,
                                                    languageDisplayName: NSLocalizedString("英語", comment: ""))),
        subMenuItems: nil
    ),
    MenuItem(
        view: AnyView(LanguageSelectSubMenuItemView(language: Language.ja,
                                                    languageDisplayName: NSLocalizedString("日本語", comment: ""))),
        subMenuItems: nil
    ),
]

let languageSelectMenuItem = MenuItem(
    view: AnyView(LanguageSelectMenuItemView()),
    subMenuItems: languageSelectSubMenuItems
)
