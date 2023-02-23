import SwiftUI

struct LanguageSwitchItemView: View {
    @State private var showingiOSAlert = false
    @State private var showingAlert = false
    var body: some View {
        VStack {
            Button(action: {
                showingAlert = true
                if !isRunningOnMacOS() {
                    self.showingiOSAlert = true
                }
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
        }
        .alert(isPresented: $showingAlert) {
            showingiOSAlert
                ? Alert(
                    title: Text(NSLocalizedString("警告", comment: "")),
                    message: Text(NSLocalizedString("言語選択の警告", comment: "")),
                    primaryButton: .default(Text(NSLocalizedString("閉じる", comment: ""))),
                    secondaryButton: .default(Text(NSLocalizedString("開く", comment: "")), action: {
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                        }
                    })
                )
                : Alert(
                    title: Text(NSLocalizedString("警告", comment: "")),
                    message: Text(NSLocalizedString("macでの言語選択の警告", comment: "")),
                    dismissButton: .default(Text(NSLocalizedString("閉じる", comment: "")))
                )
        }
    }

    private func isRunningOnMacOS() -> Bool {
        #if os(macOS) || targetEnvironment(macCatalyst)
            return true
        #else
            return false
        #endif
    }
}

let switchLanguageMenuItem = MenuItem(view: AnyView(LanguageSwitchItemView()), subMenuItems: nil)
