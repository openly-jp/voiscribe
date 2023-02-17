import SwiftUI
import UIKit

struct ShareButton: View {
    let transcription: String
    @State var isShareSheetOpen = false

    var body: some View {
        Button(action: openShareSheet) {
            Image(systemName: "square.and.arrow.up")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
        }
        .foregroundColor(Color(.secondaryLabel))
        .sheet(isPresented: $isShareSheetOpen) {
            ActivityView(text: transcription)
        }
    }

    func openShareSheet() {
        isShareSheetOpen = true
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context _: UIViewControllerRepresentableContext<ActivityView>)
        -> UIActivityViewController
    {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(
        _: UIActivityViewController,
        context _: UIViewControllerRepresentableContext<ActivityView>
    ) {}
}

struct ShareText: Identifiable {
    let id = UUID()
    let text: String
}

struct ShareButton_Previews: PreviewProvider {
    static var previews: some View {
        ShareButton(transcription: "認識結果です。共有します。")
    }
}

