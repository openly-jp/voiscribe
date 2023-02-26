import FirebaseCrashlytics
import SwiftUI

struct SettingMenuItemView: View {
    var body: some View {
        HStack {
            Image(systemName: "character.book.closed.fill")
                .imageScale(.large)
                .frame(width: 32)
            Text("設定")
                .font(.headline)
            Spacer()
        }
    }
}

struct CrashlyticsOptInSubMenuItemView: View {
    @AppStorage("CrashlyticsOptIn") var optInEnabled: Bool = true

    var body: some View {
        Button(action: {
            optInEnabled.toggle()
            Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(optInEnabled)
        }) {
            HStack {
                Image(systemName: optInEnabled ? "checkmark.circle.fill" : "circle")
                    .imageScale(.large)
                    .tint(Color(.label))
                Text("クラッシュレポート")
                    .font(.headline)
                    .tint(Color(.label))
                Spacer()
            }
        }
    }
}

let settingSubMenuItems = [
    MenuItem(view: AnyView(CrashlyticsOptInSubMenuItemView()), subMenuItems: nil),
]

let settingMenuItem = MenuItem(
    view: AnyView(SettingMenuItemView()),
    subMenuItems: settingSubMenuItems
)
