import SwiftUI

let UserModeNumKey = "user-mode-num"

struct DeveloperMenuItemView: View {
    var body: some View {
        HStack {
            Image(systemName: "person.badge.shield.checkmark.fill")
                .imageScale(.large)
                .frame(width: 32)
            Text("開発者")
                .font(.headline)
            Spacer()
        }
    }
}

struct UserModeSubMenuItemView: View {
    @AppStorage(UserModeNumKey) var currentUserModeNum = 0
    let userModeNum: Int
    let userModeDisplayName: String

    var body: some View {
        HStack {
            if currentUserModeNum == userModeNum {
                Image(systemName: "checkmark.circle.fill")
                    .imageScale(.large)
            } else {
                Image(systemName: "circle")
                    .imageScale(.large)
            }
            Text(userModeDisplayName)
                .font(.headline)
            Spacer()
        }
        .onTapGesture(perform: {
            if currentUserModeNum != userModeNum {
                currentUserModeNum = userModeNum
            }
        })
    }
}

let developerSubMenuItems = [
    MenuItem(view: AnyView(UserModeSubMenuItemView(userModeNum: 0, userModeDisplayName: "ユーザー画面")), subMenuItems: nil),
    MenuItem(view: AnyView(UserModeSubMenuItemView(userModeNum: 1, userModeDisplayName: "開発者画面")), subMenuItems: nil),
]

let developerMenuItem = MenuItem(view: AnyView(DeveloperMenuItemView()), subMenuItems: developerSubMenuItems)
