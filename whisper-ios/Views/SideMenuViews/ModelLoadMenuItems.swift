import SwiftUI

let userDefaultModelPathKey = "use-defalut-model-path-key"
let userDefaultModelSizeKey = "user-default-model-size"
let userDefaultModelLanguageKey = "user-default-model-language"
let userDefaultModelNeedsSubscriptionKey = "user-default-model-needs-subscription"

class RecordDownloadedModels: ObservableObject {
    @AppStorage("is-downloaded-tiny-multi") var isDownloadedTinyMulti = true
    @AppStorage("is-downloaded-tiny-en") var isDownloadedTinyEn = true
    @AppStorage("is-downloaded-base-multi") var isDownloadedBaseMulti = false
    @AppStorage("is-downloaded-base-en") var isDownloadedBaseEn = false
    @AppStorage("is-downloaded-small-multi") var isDownloadedSmallMulti = false
    @AppStorage("is-downloaded-small-en") var isDownloadedSmallEn = false
    @AppStorage("is-downloaded-medium-multi") var isDownloadedMediumMulti = false
    @AppStorage("is-downloaded-medium-en") var isDownloadedMediumEn = false

    func getRecordDownloadedModels(size: String, lang: String) -> Bool {
        if size == "tiny" {
            if lang == "multi" {
                return isDownloadedTinyMulti
            } else {
                return isDownloadedTinyEn
            }
        } else if size == "base" {
            if lang == "multi" {
                return isDownloadedBaseMulti
            } else {
                return isDownloadedBaseEn
            }
        } else if size == "small" {
            if lang == "multi" {
                return isDownloadedSmallMulti
            } else {
                return isDownloadedSmallEn
            }
        } else if size == "medium" {
            if lang == "multi" {
                return isDownloadedMediumMulti
            } else {
                return isDownloadedMediumEn
            }
        }
        return false
    }

    func setRecordDownloadedModels(size: String, lang: String, isDownloaded: Bool) {
        DispatchQueue.main.async {
            if size == "tiny" {
                if lang == "multi" {
                } else {
                    self.isDownloadedTinyEn = isDownloaded
                }
            } else if size == "base" {
                if lang == "multi" {
                    self.isDownloadedBaseMulti = isDownloaded
                } else {
                    self.isDownloadedBaseEn = isDownloaded
                }
            } else if size == "small" {
                if lang == "multi" {
                    self.isDownloadedSmallMulti = isDownloaded
                } else {
                    self.isDownloadedSmallEn = isDownloaded
                }
            } else if size == "medium" {
                if lang == "multi" {
                    self.isDownloadedMediumMulti = isDownloaded
                } else {
                    self.isDownloadedMediumEn = isDownloaded
                }
            }
        }
    }
}

class RecordLoadModels: ObservableObject {
    @AppStorage("is-loaded-tiny-multi") var isLoadingTinyMulti = true
    @AppStorage("is-loaded-tiny-en") var isLoadingTinyEn = true
    @AppStorage("is-loaded-base-multi") var isLoadingBaseMulti = false
    @AppStorage("is-loaded-base-en") var isLoadingBaseEn = false
    @AppStorage("is-loaded-small-multi") var isLoadingSmallMulti = false
    @AppStorage("is-loaded-small-en") var isLoadingSmallEn = false
    @AppStorage("is-loaded-medium-multi") var isLoadingMediumMulti = false
    @AppStorage("is-loaded-medium-en") var isLoadingMediumEn = false

    func getRecordLoadModels(size: String, lang: String) -> Bool {
        if size == "tiny" {
            if lang == "multi" {
                return isLoadingTinyMulti
            } else {
                return isLoadingTinyEn
            }
        } else if size == "base" {
            if lang == "multi" {
                return isLoadingBaseMulti
            } else {
                return isLoadingBaseEn
            }
        } else if size == "small" {
            if lang == "multi" {
                return isLoadingSmallMulti
            } else {
                return isLoadingSmallEn
            }
        } else if size == "medium" {
            if lang == "multi" {
                return isLoadingMediumMulti
            } else {
                return isLoadingMediumEn
            }
        }
        return false
    }

    func setRecordLoadModels(size: String, lang: String, isLoading: Bool) {
        DispatchQueue.main.async {
            if size == "tiny" {
                if lang == "multi" {
                } else {
                    self.isLoadingTinyEn = isLoading
                }
            } else if size == "base" {
                if lang == "multi" {
                    self.isLoadingBaseMulti = isLoading
                } else {
                    self.isLoadingBaseEn = isLoading
                }
            } else if size == "small" {
                if lang == "multi" {
                    self.isLoadingSmallMulti = isLoading
                } else {
                    self.isLoadingSmallEn = isLoading
                }
            } else if size == "medium" {
                if lang == "multi" {
                    self.isLoadingMediumMulti = isLoading
                } else {
                    self.isLoadingMediumEn = isLoading
                }
            }
        }
    }
}

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
    @AppStorage(userDefaultModelPathKey) var defaultModelPath = URL(string: Bundle.main
        .path(forResource: "ggml-tiny.en", ofType: "bin")!)!
    @AppStorage(userDefaultModelSizeKey) var defaultModelSize: Size = .init(rawValue: "tiny")!
    @AppStorage(userDefaultModelLanguageKey) var defaultLanguage: Lang = .init(rawValue: "en")!
    @AppStorage(userDefaultModelNeedsSubscriptionKey) var dafaultNeedsSubscription: Bool = false
    @ObservedObject var recordDownloadedModels = RecordDownloadedModels()
    @ObservedObject var recordLoadModels = RecordLoadModels()
    @State var progressValue: CGFloat = 0.0

    let modelSize: Size
    let language: Lang
    let needsSubscription: Bool
    let modelDisplayName: String
    @State private var showPrompt = false
    @State private var showDownloadModelPrompt = false
    @State private var showChangeModelPrompt = false
    @State private var isDownloading = false

    func updateProgress(num: Float) {
        progressValue = CGFloat(num)
    }

    func deleteModel() {
        let flag = WhisperModelRepository.deleteWhisperModel(
            size: modelSize,
            language: language,
            needsSubscription: needsSubscription
        )
        if flag {
            showDownloadModelPrompt = true
            showChangeModelPrompt = false
            isDownloading = false
            recordDownloadedModels.setRecordDownloadedModels(
                size: modelSize.rawValue,
                lang: language.rawValue,
                isDownloaded: false
            )
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
                    if recordDownloadedModels.getRecordDownloadedModels(
                        size: modelSize.rawValue,
                        lang: language.rawValue
                    ) {
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
            if !recordLoadModels.getRecordLoadModels(size: modelSize.rawValue, lang: language.rawValue),
               modelSize != Size(rawValue: "tiny"),
               recordDownloadedModels.getRecordDownloadedModels(size: modelSize.rawValue,
                                                                lang: language.rawValue),
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
                if !recordDownloadedModels
                    .getRecordDownloadedModels(size: modelSize.rawValue, lang: language.rawValue)
                {
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
                                 recordLoadModels.setRecordLoadModels(size: modelSize.rawValue,
                                                                      lang: language.rawValue,
                                                                      isLoading: true)
                                 let isSucceed: Bool
                                 do { isSucceed = try loadModel() }
                                 catch { isSucceed = false }
                                 if isSucceed {
                                     recordLoadModels.setRecordLoadModels(
                                         size: modelSize.rawValue,
                                         lang: language.rawValue,
                                         isLoading: false
                                     )
                                     defaultModelPath = (recognizer.whisperModel?.localPath)!
                                     defaultModelSize = modelSize
                                     defaultLanguage = language
                                     dafaultNeedsSubscription = needsSubscription
                                 }
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

    private func loadModel() throws -> Bool {
        let whisperModel = WhisperModel(
            size: modelSize,
            language: language,
            needsSubscription: needsSubscription,
            completion: {}
        )
        do {
            try recognizer.load_model(whisperModel: whisperModel)
            isDownloading = false
        } catch {
            print("load model failed in ModelLoadMenuItems")
            return false
        }
        return true
    }

    private func downloadModel() {
        WhisperModelRepository
            .fetchWhisperModel(size: modelSize, language: language, needsSubscription: needsSubscription,
                               update: updateProgress) { result in
                switch result {
                case .success:
                    isDownloading = false
                    showDownloadModelPrompt = false
                    showChangeModelPrompt = true
                    recordDownloadedModels.setRecordDownloadedModels(
                        size: modelSize.rawValue,
                        lang: language.rawValue,
                        isDownloaded: true
                    )
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
            needsSubscription: false,
            modelDisplayName: "Tiny"
        )),
        subMenuItems: nil
    ),
    MenuItem(
        view: AnyView(ModelLoadSubMenuItemView(
            modelSize: Size(rawValue: "tiny")!,
            language: Lang(rawValue: "en")!,
            needsSubscription: false,
            modelDisplayName: "Tiny(EN)"
        )),
        subMenuItems: nil
    ),
    MenuItem(
        view: AnyView(ModelLoadSubMenuItemView(
            modelSize: Size(rawValue: "base")!,
            language: Lang(rawValue: "multi")!,
            needsSubscription: false,
            modelDisplayName: "Base"
        )),
        subMenuItems: nil
    ),
    MenuItem(
        view: AnyView(ModelLoadSubMenuItemView(
            modelSize: Size(rawValue: "base")!,
            language: Lang(rawValue: "en")!,
            needsSubscription: false,
            modelDisplayName: "Base(EN)"
        )),
        subMenuItems: nil
    ),
    MenuItem(
        view: AnyView(ModelLoadSubMenuItemView(
            modelSize: Size(rawValue: "small")!,
            language: Lang(rawValue: "multi")!,
            needsSubscription: false,
            modelDisplayName: "Small"
        )),
        subMenuItems: nil
    ),
    MenuItem(
        view: AnyView(ModelLoadSubMenuItemView(
            modelSize: Size(rawValue: "small")!,
            language: Lang(rawValue: "en")!,
            needsSubscription: false,
            modelDisplayName: "Small(EN)"
        )),
        subMenuItems: nil
    ),
    MenuItem(
        view: AnyView(ModelLoadSubMenuItemView(
            modelSize: Size(rawValue: "medium")!,
            language: Lang(rawValue: "multi")!,
            needsSubscription: false,
            modelDisplayName: "Medium"
        )),
        subMenuItems: nil
    ),
    MenuItem(
        view: AnyView(ModelLoadSubMenuItemView(
            modelSize: Size(rawValue: "medium")!,
            language: Lang(rawValue: "en")!,
            needsSubscription: false,
            modelDisplayName: "Medium(EN)"
        )),
        subMenuItems: nil
    ),
]
let modelLoadMenuItem = MenuItem(view: AnyView(ModelLoadMenuItemView()), subMenuItems: modeLoadSubMenuItems)
