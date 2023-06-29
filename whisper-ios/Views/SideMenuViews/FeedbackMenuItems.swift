import SwiftUI

struct FeedbackMenuItemView: View {
    var body: some View {
        HStack {
            Image(systemName: "list.bullet.clipboard.fill")
                .imageScale(.large)
                .frame(width: 32)
            Link(
                "フィードバック",
                destination: URL(
                    string: "https://docs.google.com/forms/d/e/1FAIpQLSenR12P7JP6EYw_881j_5jxiRYeULsApx9Mp6-Vb5a-DhAm2w/viewform?usp=sf_link"
                )!
            )
            .tint(Color(.label))
            .font(.headline)
            Spacer()
        }
    }
}

let feedbackMenuItem = MenuItem(view: AnyView(FeedbackMenuItemView()), subMenuItems: nil)
