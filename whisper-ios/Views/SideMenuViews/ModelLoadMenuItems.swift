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

struct CircularProgressBar: View {
    @Binding var progress: CGFloat

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                // Specify to draw the border line
                .stroke(lineWidth: 4.0)
                .opacity(0.3)
                .foregroundColor(.gray)

            // Circle to indicate progress
            Circle()
                // Draw a circle by specifying the start and end points
                // Specify normalized values in the range of 0.0-1.0 for the start and end points
                .trim(from: 0.0, to: min(progress, 1.0))
                // Specify the shape of the line's end and other parameters
                .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .foregroundColor(.blue)
                // The default origin is not at the 12 o'clock position of the clock, so rotate it
                .rotationEffect(Angle(degrees: 270.0))
        }
    }
}

struct ModelLoadSubMenuItemView: View {
    @EnvironmentObject var recognizer: WhisperRecognizer
    @AppStorage(userDefaultModelSizeKey) var defaultModelSize: Size = .init(rawValue: "tiny")!
    @AppStorage(userDefaultModelLanguageKey) var defaultLanguage: Lang = .init(rawValue: "en")!
    @State var progressValue: CGFloat = 0.0

    let modelSize: Size
    let language: Lang
    let modelDisplayName: String
    @State private var showPrompt = false
    @State private var showDownloadModelPrompt = false
    @State private var showChangeModelPrompt = false
    @State private var isDownloading = false
    @State private var isLoading = false

    func updateProgress(num: Float) {
        progressValue = CGFloat(num)
    }

    func deleteModel() {
        let flag = WhisperModelRepository.deleteWhisperModel(
            size: modelSize,
            language: language
        )
        if flag {
            showDownloadModelPrompt = true
            showChangeModelPrompt = false
            isDownloading = false
        } else {
            print("model deletion failed in deleteModel")
        }
    }

    var body: some View {
        HStack {
            if recognizer.whisperModel?.name == "\(modelSize.rawValue)-\(language.rawValue)" {
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
               recognizer.whisperModel?.name != "\(modelSize.rawValue)-\(language.rawValue)"
            {
                Button(action: deleteModel) {
                    label: do {
                        Image(systemName: "trash.fill")
                    }
                }.tint(.red)
            }
        }
        .onTapGesture(perform: {
            if recognizer.whisperModel?.name != "\(modelSize.rawValue)-\(language.rawValue)" {
                self.showPrompt = true
                if !modelExists() {
                    self.showDownloadModelPrompt = true
                } else {
                    self.showChangeModelPrompt = true
                }
            }
        })
        .alert(isPresented: $showPrompt) {
            if self.showChangeModelPrompt {
                return Alert(title: Text("モデルを変更しますか？"),
                             primaryButton: .cancel(Text("キャンセル")),
                             secondaryButton: .default(Text("変更"), action: {
                                 loadModel(callback: {
                                     isLoading = false
                                     defaultModelSize = modelSize
                                     defaultLanguage = language
                                 })
                             }))
            } else {
                return Alert(title: Text("モデルをダウンロードしますか?"),
                             message: Text("通信容量にご注意ください。"),
                             primaryButton: .cancel(Text("キャンセル")),
                             secondaryButton: .default(Text("ダウンロード"), action: {
                                 isDownloading = true
                                 downloadModel()
                             }))
            }
        }
    }

    private func modelExists() -> Bool {
        WhisperModelRepository.modelExists(size: modelSize, language: language)
    }

    private func loadModel(callback: @escaping () -> Void) {
        recognizer.whisperModel?.free_model(callback: {})
        let whisperModel = WhisperModel(
            size: modelSize,
            language: language,
            completion: {}
        )
        whisperModel.load_model {
            if isLoading {
                isLoading = false
            }
            if whisperModel.whisperContext == nil {
                Logger.error("model loading failed in loadModel")
            }
            Logger.info("model successfully loaded")
            recognizer.whisperModel = whisperModel
            Logger.info("whisperModel is loaded on recognizer")
            callback()
        }
    }

    private func downloadModel() {
        WhisperModelRepository
            .fetchWhisperModel(size: modelSize, language: language,
                               update: updateProgress) { result in
                switch result {
                case .success:
                    isDownloading = false
                    showDownloadModelPrompt = false
                    showChangeModelPrompt = true
                case let .failure(error):
                    print("Error: \(error.localizedDescription)")
                }
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
