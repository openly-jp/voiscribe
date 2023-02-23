import SwiftUI

struct LanguageSwitchItemView: View {
    @State private var showingAlert = false

    var body: some View {
        VStack {
            Button(action: {
                self.showingAlert = true
            }) {
                HStack {
                    Image(systemName: "globe")
                        .imageScale(.large)
                        .frame(width: 32)
                        .tint(Color(.label))
                    Text(NSLocalizedString("表示言語", comment: ""))
                        .font(.headline)
                        .tint(Color(.label))
                    Spacer()
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text(NSLocalizedString("警告", comment: "")),
                    message: Text(NSLocalizedString("言語選択の警告", comment: "")),
                    primaryButton: .destructive(Text(NSLocalizedString("閉じる", comment: ""))),
                    secondaryButton: .default(Text(NSLocalizedString("開く", comment: "")), action: {
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                        }
                    })
                )
            }
        }
    }
}

let switchLanguageMenuItem = MenuItem(view: AnyView(LanguageSwitchItemView()), subMenuItems: nil)
