import FirebaseCrashlytics
import SwiftUI

let userDefaultModelSizeKey = "user-default-model-size"
let userDefaultModelLanguageKey = "user-default-model-language"

struct ModelLoadMenuItemView: View {
    var body: some View {
        HStack {
            Image(systemName: "hearingdevice.ear.fill")
                .imageScale(.large)
                .frame(width: 32)
            Text("認識モデル")
                .font(.headline)
            Spacer()
        }
    }
}

// https://dev.classmethod.jp/articles/ios-circular-progress-bar-with-swiftui/
struct CircularProgressBar: View {
    @Binding var progress: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 4.0)
                .opacity(0.3)
                .foregroundColor(.gray)

            Circle()
                .trim(from: 0.0, to: min(progress, 1.0))
                .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .foregroundColor(.blue)
                .rotationEffect(Angle(degrees: 270.0))
        }
    }
}

struct ModelLoadSubMenuItemView: View {
    @EnvironmentObject var recognizer: WhisperRecognizer
    @AppStorage(userDefaultModelSizeKey) var defaultModelSize = Size(rawValue: "tiny")!
    @AppStorage(userDefaultModelLanguageKey) var defaultLanguage = Lang(rawValue: "en")!
    @State var progressValue: CGFloat = 0.0

    let modelSize: Size
    let language: Lang
    let modelDisplayName: String
    @ObservedObject var whisperModel: WhisperModel

    @State private var showPrompt = false
    @State private var isDownloading = false
    @State private var isLoading = false

    init(modelSize: Size, language: Lang, modelDisplayName: String) {
        self.modelSize = modelSize
        self.language = language
        self.modelDisplayName = modelDisplayName

        whisperModel = WhisperModel(size: modelSize, language: language)
    }

    var body: some View {
        HStack {
            if isModelSelected {
                Image(systemName: "checkmark.circle.fill")
                    .imageScale(.large)
            } else {
                Image(systemName: "circle")
                    .imageScale(.large)
            }
            Text(modelDisplayName)
                .font(.headline)
            Spacer()
            if modelSize != .tiny {
                if isDownloading {
                    CircularProgressBar(progress: $progressValue)
                        .frame(width: 18, height: 18)
                } else {
                    if whisperModel.isDownloaded {
                        Image(systemName: "checkmark.icloud.fill")
                    } else {
                        Image(systemName: "icloud.and.arrow.down")
                    }
                }
            }
        }
        .swipeActions(edge: .trailing) {
            if !isLoading,
               modelSize != .tiny,
               whisperModel.isDownloaded,
               !isModelSelected
            {
                Button(action: deleteModel) { Image(systemName: "trash.fill") }
                    .tint(.red)
            }
        }
        .onTapGesture {
            guard !isModelSelected else {
                return
            }

            guard !isDownloading else {
                return
            }

            showPrompt = true
        }
        .alert(isPresented: $showPrompt) {
            whisperModel.isDownloaded
                ? Alert(
                    title: Text("モデルを変更しますか？"),
                    primaryButton: .cancel(Text("キャンセル")),
                    secondaryButton: .default(Text("変更"), action: loadModel)
                )
                : Alert(
                    title: Text("モデルをダウンロードしますか?"),
                    message: Text("通信容量にご注意ください。"),
                    primaryButton: .cancel(Text("キャンセル")),
                    secondaryButton: .default(Text("ダウンロード"), action: downloadModel)
                )
        }
    }

    var isModelSelected: Bool {
        recognizer.whisperModel.size == modelSize && recognizer.whisperModel.language == language
    }

    private func loadModel() {
        assert(whisperModel.isDownloaded)

        recognizer.whisperModel.freeModel()
        recognizer.whisperModel = whisperModel

        isLoading = true
        whisperModel.loadModel { err in
            isLoading = false

            if let err {
                Crashlytics.crashlytics().record(error: err)
                return
            }

            defaultModelSize = modelSize
            defaultLanguage = language
        }
    }

    private func downloadModel() {
        isDownloading = true
        whisperModel.downloadModel { err in
            isDownloading = false
            if let err {
                Crashlytics.crashlytics().record(error: err)
            }
        } updateCallback: { num in
            progressValue = CGFloat(num)
        }
    }

    func deleteModel() {
        do {
            try whisperModel.deleteModel()
        } catch {
            Crashlytics.crashlytics().record(error: error)
        }
    }
}

let modeLoadSubMenuItems = [
    MenuItem(
        view: AnyView(ModelLoadSubMenuItemView(
            modelSize: Size(rawValue: "tiny")!,
            language: Lang(rawValue: "multi")!,
            modelDisplayName: "Tiny"
        )),
        subMenuItems: nil
    ),
    MenuItem(
        view: AnyView(ModelLoadSubMenuItemView(
            modelSize: Size(rawValue: "tiny")!,
            language: Lang(rawValue: "en")!,
            modelDisplayName: "Tiny(EN)"
        )),
        subMenuItems: nil
    ),
    MenuItem(
        view: AnyView(ModelLoadSubMenuItemView(
            modelSize: Size(rawValue: "base")!,
            language: Lang(rawValue: "multi")!,
            modelDisplayName: "Base"
        )),
        subMenuItems: nil
    ),
    MenuItem(
        view: AnyView(ModelLoadSubMenuItemView(
            modelSize: Size(rawValue: "base")!,
            language: Lang(rawValue: "en")!,
            modelDisplayName: "Base(EN)"
        )),
        subMenuItems: nil
    ),
    MenuItem(
        view: AnyView(ModelLoadSubMenuItemView(
            modelSize: Size(rawValue: "small")!,
            language: Lang(rawValue: "multi")!,
            modelDisplayName: "Small"
        )),
        subMenuItems: nil
    ),
    MenuItem(
        view: AnyView(ModelLoadSubMenuItemView(
            modelSize: Size(rawValue: "small")!,
            language: Lang(rawValue: "en")!,
            modelDisplayName: "Small(EN)"
        )),
        subMenuItems: nil
    ),
    MenuItem(
        view: AnyView(ModelLoadSubMenuItemView(
            modelSize: Size(rawValue: "medium")!,
            language: Lang(rawValue: "multi")!,
            modelDisplayName: "Medium"
        )),
        subMenuItems: nil
    ),
    MenuItem(
        view: AnyView(ModelLoadSubMenuItemView(
            modelSize: Size(rawValue: "medium")!,
            language: Lang(rawValue: "en")!,
            modelDisplayName: "Medium(EN)"
        )),
        subMenuItems: nil
    ),
]
let modelLoadMenuItem = MenuItem(view: AnyView(ModelLoadMenuItemView()), subMenuItems: modeLoadSubMenuItems)
