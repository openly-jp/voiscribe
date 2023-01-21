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
    @AppStorage(UserDefaultASRModelNameKey) var defaultModelName = "ggml-tiny.en"

    var body: some View {
        if isLoading {
            Image("icon")
                .resizable()
                .frame(width: 60, height: 60)
                .onAppear {
                    DispatchQueue.global(qos: .userInteractive).async {
                        recognizer = WhisperRecognizer(modelName: defaultModelName)
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
