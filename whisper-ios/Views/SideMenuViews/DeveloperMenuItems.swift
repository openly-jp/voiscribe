import SwiftUI

let UserModeNumKey = "user-mode-num"
let PromptingActiveKey = "prompting-active"
let RemainingAudioConcatActiveKey = "remaining-audio-concat-active"

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

struct PromptingActiveSubMenuItemView: View {
    @AppStorage(PromptingActiveKey) var promptingActive = true

    var body: some View {
        HStack {
            if promptingActive {
                Image(systemName: "checkmark.circle.fill")
                    .imageScale(.large)
            } else {
                Image(systemName: "circle")
                    .imageScale(.large)
            }
            Text("プロンプティング有効")
                .font(.headline)
            Spacer()
        }
        .onTapGesture(perform: {
            promptingActive = !promptingActive
        })
    }
}

struct RemainingAudioConcatActiveSubMenuItemView: View {
    @AppStorage(RemainingAudioConcatActiveKey) var remainingAudioConcatActive = true

    var body: some View {
        HStack {
            if remainingAudioConcatActive {
                Image(systemName: "checkmark.circle.fill")
                    .imageScale(.large)
            } else {
                Image(systemName: "circle")
                    .imageScale(.large)
            }
            Text("直前音声の結合")
                .font(.headline)
            Spacer()
        }
        .onTapGesture(perform: {
            remainingAudioConcatActive = !remainingAudioConcatActive
        })
    }
}

let developerSubMenuItems = [
    MenuItem(
        view: AnyView(UserModeSubMenuItemView(userModeNum: 0,
                                              userModeDisplayName: NSLocalizedString("ユーザー画面", comment: ""))),
        subMenuItems: nil
    ),
    MenuItem(
        view: AnyView(UserModeSubMenuItemView(userModeNum: 1,
                                              userModeDisplayName: NSLocalizedString("開発者画面", comment: ""))),
        subMenuItems: nil
    ),
    MenuItem(view: AnyView(PromptingActiveSubMenuItemView()), subMenuItems: nil),
    MenuItem(view: AnyView(RemainingAudioConcatActiveSubMenuItemView()), subMenuItems: nil),
]

let developerMenuItem = MenuItem(view: AnyView(DeveloperMenuItemView()), subMenuItems: developerSubMenuItems)
