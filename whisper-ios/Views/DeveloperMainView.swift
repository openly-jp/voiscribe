import SwiftUI

struct DeveloperMainView: View {
    // This will be utilized as a developer main view
    @EnvironmentObject var recognizer: WhisperRecognizer

    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: StreamingRecognitionTestView()) {
                    Text("ストリーミング音声認識テスト")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Text("開発者メニュー"))
        }
    }
}

struct DeveloperMainView_Previews: PreviewProvider {
    static var previews: some View {
        DeveloperMainView()
    }
}
