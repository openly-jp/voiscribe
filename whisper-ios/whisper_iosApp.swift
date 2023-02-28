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
        for modelSize in Size.allCases {
            for modelLang in [Lang.en, Lang.multi] {
                let isDownloadingKey = "\(userDefaultWhisperModelDownloadingPrefix)-\(modelSize)-\(modelLang)"
                UserDefaults.standard.set(false, forKey: isDownloadingKey)
            }
        }
    }

    var body: some View {
        if isLoading {
            ZStack {
                VStack {
                    Image("loadingscreen")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 2048)
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
                }
                VStack {
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
