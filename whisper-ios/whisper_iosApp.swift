import Firebase
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_: UIApplication,
                     didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool
    {
        FirebaseApp.configure()
        return true
    }
}

@main
struct WhisperTestApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
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
        }
    }
}
