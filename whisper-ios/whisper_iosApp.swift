import PartialSheet
import SwiftUI

@main
struct VoiscribeApp: App {
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            StartView()
                .onChange(of: scenePhase) { phase in
                    if phase == .background {
                        if numRecognitionTasks > 0 {
                            sendBackgroundAlertNotification()
                        }
                    }
                }
        }
    }
}

struct StartView: View {
    @State var isLoading: Bool
    @State var recognizer: WhisperRecognizer?

    @AppStorage var defaultRecognitionLanguage: RecognitionLanguage
    @AppStorage var defaultModelSize: Size

    init() {
        isLoading = true
        _defaultModelSize = AppStorage(wrappedValue: Size(), userDefaultModelSizeKey)
        _defaultRecognitionLanguage = AppStorage(wrappedValue: RecognitionLanguage(), userDefaultRecognitionLanguageKey)

        for modelSize in Size.allCases {
            ModelLanguage.allCases.map { modelLanguage in
                let isDownloadingKey = "\(userDefaultWhisperModelDownloadingPrefix)-\(modelSize)-\(modelLanguage)"
                UserDefaults.standard.set(false, forKey: isDownloadingKey)
            }
        }
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.requestAuthorization(options: .alert, completionHandler: { _, _ in })
    }

    var body: some View {
        if isLoading {
            splashScreen
        } else {
            HomeView()
                .environmentObject(recognizer!)
                .attachPartialSheetToRoot()
        }
    }
    
    var splashScreen: some View {
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
                                recognitionLanguage: defaultRecognitionLanguage
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
    }
}
