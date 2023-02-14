import SafariServicesUI
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
    }
}

let AppInfoMenuSubItems = [
    MenuItem(view: AnyView(
        Link("利用規約", destination: URL(string: "https://openly.jp/company/voiscribe")!)
            .openURLInSafariView()
    ), subMenuItems: nil),
    MenuItem(view: AnyView(
        Link("プライバシーポリシー", destination: URL(string: "https://openly.jp/company/privacy-policy")!)
            .openURLInSafariView()
    ), subMenuItems: nil),
    MenuItem(view: AnyView(
        NavigationLink(destination: LicenseView()) {
            AppInfoMenuItemViewSubMenuItemView(title: "ライセンス")
        }
    ), subMenuItems: nil),
]

let appInfoMenuItem = MenuItem(view: AnyView(AppInfoMenuItemView()), subMenuItems: AppInfoMenuSubItems)
