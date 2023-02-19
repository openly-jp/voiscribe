import SwiftUI

@main
struct WhisperTestApp: App {
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

    var body: some View {
        if isLoading {
            Image("icon")
                .resizable()
                .frame(width: 60, height: 60)
                .onAppear {
                    DispatchQueue.global(qos: .userInteractive).async {
                        let whisperModel = WhisperModel(
                            size: defaultModelSize,
                            language: defaultModelLanguage,
                            completion: {}
                        )
                        whisperModel.load_model(callback:{
                            recognizer = WhisperRecognizer(whisperModel: whisperModel)
                            if recognizer == nil{
                                // Logger cannot be initialized on app start
                                print("recognizer initialization failed on app start")
                            }
                            isLoading = false
                        })
                    }
                }
            Text(APP_NAME)
        } else {
            HomeView()
                .environmentObject(recognizer!)
        }
    }
}
