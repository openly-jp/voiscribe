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
        }
        return false
    }

    func setRecordDownloadedModels(size: String, lang: String, isDownloaded: Bool) {
        if size == "tiny" {
            if lang == "multi" {
                isDownloadedTinyMulti = isDownloaded
            } else {
                isDownloadedTinyEn = isDownloaded
            }
        } else if size == "base" {
            if lang == "multi" {
                isDownloadedBaseMulti = isDownloaded
            } else {
                isDownloadedBaseEn = isDownloaded
            }
        } else if size == "small" {
            if lang == "multi" {
                isDownloadedSmallMulti = isDownloaded
            } else {
                isDownloadedSmallEn = isDownloaded
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

struct ModelLoadSubMenuItemView: View {
    @EnvironmentObject var recognizer: WhisperRecognizer
    @AppStorage(userDefaultModelPathKey) var defaultModelPath = URL(string: Bundle.main
        .path(forResource: "ggml-tiny.en", ofType: "bin")!)!
    @AppStorage(userDefaultModelSizeKey) var defaultModelSize: Size = .init(rawValue: "tiny")!
    @AppStorage(userDefaultModelLanguageKey) var defaultLanguage: Lang = .init(rawValue: "en")!
    @AppStorage(userDefaultModelNeedsSubscriptionKey) var dafaultNeedsSubscription: Bool = false
    @ObservedObject var recordDownloadedModels = RecordDownloadedModels()

    let modelSize: Size
    let language: Lang
    let needsSubscription: Bool
    let modelDisplayName: String
    @State private var showPrompt = false
    @State private var showDownloadModelPrompt = false
    @State private var showChangeModelPrompt = false

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
            if recordDownloadedModels.getRecordDownloadedModels(size: modelSize.rawValue, lang: language.rawValue) {
                Image(systemName: "checkmark.icloud.fill")
                    .imageScale(.large)
            } else {
                Image(systemName: "icloud.and.arrow.down")
                    .imageScale(.large)
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
                print("showDownloadModelPrompt", showDownloadModelPrompt)
                print("showChangeModelPrompt", showChangeModelPrompt)
            }
        })
        .alert(isPresented: $showPrompt) {
            if self.showChangeModelPrompt {
                return Alert(title: Text("モデルを変更しますか？"),
                             primaryButton: .cancel(Text("キャンセル")),
                             secondaryButton: .default(Text("変更"), action: {
                                 let isSucceed: Bool
                                 do { isSucceed = try loadModel() }
                                 catch { isSucceed = false }
                                 if isSucceed {
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
                                 downloadModel()
                             }))
            }
        }
    }

    private func loadModel() throws -> Bool {
        let whisperModel = WhisperModel(
            size: modelSize,
            language: language,
            needsSubscription: needsSubscription
        )
        do {
            try recognizer.load_model(whisperModel: whisperModel)
        } catch {
            print("load model failed in ModelLoadMenuItems")
            return false
        }
        return true
    }

    private func downloadModel() {
        let whisperModel = WhisperModel(
            size: modelSize,
            language: language,
            needsSubscription: needsSubscription
        )
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
]
let modelLoadMenuItem = MenuItem(view: AnyView(ModelLoadMenuItemView()), subMenuItems: modeLoadSubMenuItems)
