import SwiftUI

@main
struct whisperTestApp: App {
    init() {
        #if DEBUG
        var injectionBundlePath = "/Applications/InjectionIII.app/Contents/Resources"
        #if targetEnvironment(macCatalyst)
        injectionBundlePath = "\(injectionBundlePath)/macOSInjection.bundle"
        #elseif os(iOS)
        injectionBundlePath = "\(injectionBundlePath)/iOSInjection.bundle"
        #endif
        Bundle(path: injectionBundlePath)?.load()
        #endif
    }
    var body: some Scene {
        WindowGroup {
            startView()
        }
    }
}

struct startView: View {
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
            Text("Whisper iOS")
        } else {
            HomeView()
                .environmentObject(recognizer!)
        }
    }
}
