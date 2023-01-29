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
    @AppStorage(userDefaultModelSizeKey) var defaultModelSize = Size(rawValue: "tiny")!
    @AppStorage(userDefaultModelLanguageKey) var defaultModelLanguage = Lang(rawValue: "en")!
    @AppStorage(userDefaultModelNeedsSubscriptionKey) var defaultModelNeedsSubscription = false

    var body: some View {
        if isLoading {
            Image("icon")
                .resizable()
                .frame(width: 60, height: 60)
                .onAppear {
                    DispatchQueue.global(qos: .userInteractive).async {
                        let whisperModel = WhisperModel(
                            localPath: URL(string: Bundle.main.path(forResource: "ggml-tiny.en", ofType: "bin")!),
                            size: defaultModelSize,
                            language: defaultModelLanguage, needsSubscription: false)
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
