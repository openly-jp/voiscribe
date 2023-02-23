import SwiftUI

struct LanguageSwitchItemView: View {
    var body: some View {
        Link(destination: URL(string: UIApplication.openSettingsURLString)!, label: {
            HStack {
                Image(systemName: "globe")
                    .tint(Color(.black))
                    .imageScale(.large)
                    .frame(width: 32)
                Text(NSLocalizedString("表示言語", comment: ""))
                    .font(.headline)
                    .tint(Color(.label))
                Spacer()
            }
        })
    }
}

let switchLanguageMenuItem = MenuItem(view: AnyView(LanguageSwitchItemView()), subMenuItems: nil)
