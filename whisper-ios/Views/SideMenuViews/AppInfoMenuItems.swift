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

struct AppInfoSubMenuItemView: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
        }
    }
}

let AppInfoSubMenuItems = [
    MenuItem(view: AnyView(
        Link("利用規約", destination: URL(string: "https://openly.jp/company/voiscribe")!)
            .tint(Color(.label))
            .font(.headline)
    ), subMenuItems: nil),
    MenuItem(view: AnyView(
        Link("プライバシーポリシー", destination: URL(string: "https://openly.jp/company/privacy-policy")!)
            .tint(Color(.label))
            .font(.headline)
    ), subMenuItems: nil),
    MenuItem(view: AnyView(
        NavigationLink(destination: LicenseView()) {
            AppInfoSubMenuItemView(title: NSLocalizedString("ライセンス", comment: ""))
        }
    ), subMenuItems: nil),
]

let appInfoMenuItem = MenuItem(view: AnyView(AppInfoMenuItemView()), subMenuItems: AppInfoSubMenuItems)
