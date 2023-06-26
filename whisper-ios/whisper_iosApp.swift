import PartialSheet
import SwiftUI

@main
struct VoiscribeApp: App {
    var body: some Scene {
        WindowGroup {
            StartView()
        }
    }
}

struct StartView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State var isLoading = true
    @State var recognitionManager: RecognitionManager?

    init() {
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
                .environmentObject(recognitionManager!)
                .attachPartialSheetToRoot()
                .onChange(of: scenePhase) { phase in
                    if phase == .background, recognitionManager!.isRecognizing {
                        sendBackgroundAlertNotification()
                    }
                }
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
                    .onAppear { recognitionManager = RecognitionManager { isLoading = false } }
                Spacer().frame(height: 15)
                Text(APP_NAME)
                    .foregroundColor(.white)
            }
        }
    }
}
