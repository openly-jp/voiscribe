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
    @AppStorage(UserDefaultASRLanguageKey) var defaultLanguageRawValue = Language.en.rawValue

    var body: some View {
        HStack {
            if defaultLanguageRawValue == language.rawValue {
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
            if defaultLanguageRawValue != language.rawValue {
                defaultLanguageRawValue = language.rawValue
            }
        })
    }
}

let languageSelectSubMenuItems = [
    MenuItem(view: AnyView(LanguageSelectSubMenuItemView(language: Language.en, languageDisplayName: "英語")), subMenuItems: nil),
    MenuItem(view: AnyView(LanguageSelectSubMenuItemView(language: Language.ja, languageDisplayName: "日本語")), subMenuItems: nil),
]

let languageSelectMenuItem = MenuItem(view: AnyView(LanguageSelectMenuItemView()), subMenuItems: languageSelectSubMenuItems)
