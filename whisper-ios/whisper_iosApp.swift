import SwiftUI

@main
struct WhisperTestApp: App {
    init() {}

    var body: some Scene {
        WindowGroup {
            StartView()
        }
    }
}

struct StartView: View {
    @State var isLoading: Bool = true
    @State var recognizer: WhisperRecognizer?
    @AppStorage(userDefaultModelSize) var defaultModelSize = Size(rawValue: "tiny")!
    @AppStorage(userDefaultModelLanguage) var defaultModelLanguage = Lang(rawValue: "en")!
    @AppStorage(userDefaultModelNeedsSubscription) var defaultModelNeedsSubscription = false

    var body: some View {
        if isLoading {
            Image("icon")
                .resizable()
                .frame(width: 60, height: 60)
                .onAppear {
                    DispatchQueue.global(qos: .userInteractive).async {
                        let whisperModel = WhisperModel(size: defaultModelSize, language: defaultModelLanguage, needsSubscription: defaultModelNeedsSubscription)
                        recognizer = WhisperRecognizer(whisperModel: whisperModel)
                        isLoading = false
                    }
                }
            Text(APP_NAME)
        } else {
            HomeView()
                .environmentObject(recognizer!)
        }
    }
}
