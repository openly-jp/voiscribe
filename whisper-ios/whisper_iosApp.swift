import PartialSheet
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
    @State var isLoading: Bool
    @State var recognizer: WhisperRecognizer?

    @AppStorage var defaultModelSize: Size
    @AppStorage var defaultModelLanguage: Lang

    init() {
        isLoading = true
        _defaultModelSize = AppStorage(wrappedValue: Size(), userDefaultModelSizeKey)
        _defaultModelLanguage = AppStorage(wrappedValue: Lang(), userDefaultModelLanguageKey)
    }

    var body: some View {
        if isLoading {
            ZStack {
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0, green: 0.549, blue: 0.8352),
                            Color(red: 0.15, green: 0.3333, blue: 0.6666),
                            Color(red: 0.3725, green: 0.0901, blue: 0.3019),
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                }
                VStack {
                    Image("iconwhite")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 128)
                        .onAppear {
                            DispatchQueue.global(qos: .userInteractive).async {
                                let whisperModel = WhisperModel(
                                    size: defaultModelSize,
                                    language: defaultModelLanguage
                                )
                                whisperModel.loadModel { err in
                                    if let err { Logger.error(err); return }

                                    recognizer = try! WhisperRecognizer(whisperModel: whisperModel)
                                    isLoading = false
                                }
                            }
                        }
                    Spacer().frame(height: 15)
                    Text(APP_NAME)
                        .foregroundColor(.white)
                }
            }
        } else {
            HomeView()
                .environmentObject(recognizer!)
                .attachPartialSheetToRoot()
        }
    }
}
