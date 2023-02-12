import SwiftUI

struct AppInfoMenuItemView: View {
    var body: some View {
        HStack {
            Image(systemName: "info.circle.fill")
                .imageScale(.large)
                .frame(width: 32)
            Text("アプリ情報")
                .font(.headline)
            Spacer()
        }
    }
}

struct AppInfoMenuItemViewSubMenuItemView: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
        }
        .onTapGesture(perform: {})
    }
}

let AppInfoMenuSubItems = [
    MenuItem(view: AnyView(AppInfoMenuItemViewSubMenuItemView(title: "利用規約")), subMenuItems: nil),
    MenuItem(view: AnyView(AppInfoMenuItemViewSubMenuItemView(title: "プライバシーポリシー")), subMenuItems: nil),
    MenuItem(view: AnyView(AppInfoMenuItemViewSubMenuItemView(title: "ライセンス")), subMenuItems: nil),
    MenuItem(view: AnyView(AppInfoMenuItemViewSubMenuItemView(title: "バージョン")), subMenuItems: nil),
]

let appInfoMenuItem = MenuItem(view: AnyView(AppInfoMenuItemView()), subMenuItems: AppInfoMenuSubItems)
