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

    @State private var showPrompt = false
    @State private var isDownloadModelPrompt = false
    @State private var isDownloading = false
    @State private var isLoading = false

    var body: some View {
        HStack {
            if recognizer.whisperModel.name == "\(modelSize.rawValue)-\(language.rawValue)" {
                Image(systemName: "checkmark.circle.fill")
                    .imageScale(.large)
            } else {
                Image(systemName: "circle")
                    .imageScale(.large)
            }
            Text(modelDisplayName)
                .font(.headline)
            Spacer()
            if modelSize != Size(rawValue: "tiny") {
                if isDownloading {
                    CircularProgressBar(progress: $progressValue)
                        .frame(width: 18, height: 18)
                } else {
                    if modelExists() {
                        Image(systemName: "checkmark.icloud.fill")
                    } else {
                        Image(systemName: "icloud.and.arrow.down")
                    }
                }
            }
        }
        .swipeActions(edge: .trailing) {
            /// show delete label when the following 3 cases are met simultaneously
            /// 1. model is not loading
            /// 2. model is not tiny
            /// 3. the model is already downloaded
            /// 4. the model is not selected
            if !isLoading,
               modelSize != Size(rawValue: "tiny"),
               modelExists(),
               recognizer.whisperModel.name != "\(modelSize.rawValue)-\(language.rawValue)"
            {
                Button(action: deleteModel) {
                    label: do {
                        Image(systemName: "trash.fill")
                    }
                }.tint(.red)
            }
        }
        .onTapGesture {
            guard recognizer.whisperModel.name != "\(modelSize.rawValue)-\(language.rawValue)" else {
                return
            }

            guard !isDownloading else {
                return
            }

            isDownloadModelPrompt = !modelExists()
            showPrompt = true
        }
        .alert(isPresented: $showPrompt) {
            isDownloadModelPrompt
                ? Alert(
                    title: Text("モデルをダウンロードしますか?"),
                    message: Text("通信容量にご注意ください。"),
                    primaryButton: .cancel(Text("キャンセル")),
                    secondaryButton: .default(Text("ダウンロード"), action: downloadModel)
                )
                : Alert(
                    title: Text("モデルを変更しますか？"),
                    primaryButton: .cancel(Text("キャンセル")),
                    secondaryButton: .default(Text("変更"), action: loadModel)
                )
        }
    }

    private func modelExists() -> Bool {
        WhisperModelRepository.modelExists(size: modelSize, language: language)
    }

    private func loadModel() {
        isLoading = true
        recognizer.whisperModel.free_model(callback: {})
        let whisperModel = WhisperModel(
            size: modelSize,
            language: language,
            completion: {}
        )
        whisperModel.load_model {
            isLoading = false
            if whisperModel.whisperContext == nil {
                Logger.error("model loading failed in loadModel")
            }
            recognizer.whisperModel = whisperModel

            defaultModelSize = modelSize
            defaultLanguage = language
        }
    }

    private func downloadModel() {
        isDownloading = true
        WhisperModelRepository.fetchWhisperModel(
            size: modelSize,
            language: language,
            update: { num in progressValue = CGFloat(num) }
        ) { result in
            switch result {
            case .success:
                isDownloading = false
            case let .failure(error):
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func deleteModel() {
        let flag = WhisperModelRepository.deleteWhisperModel(
            size: modelSize,
            language: language
        )
        if !flag {
            Logger.error("model deletion failed in deleteModel")
        }
        isDownloadModelPrompt = true
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
