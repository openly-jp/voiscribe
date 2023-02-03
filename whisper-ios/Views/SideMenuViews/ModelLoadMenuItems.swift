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
    @State private var showDialogue = false

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
            if modelSize.rawValue == "tiny" {
                if language.rawValue == "en" {
                    if recordDownloadedModels.isDownloadedTinyEn {
                        Image(systemName: "icloud.and.arrow.down")
                            .imageScale(.large)
                    } else {
                        Image(systemName: "checkmark.icloud.fill")
                            .imageScale(.large)
                    }
                } else {
                    if recordDownloadedModels.isDownloadedTinyMulti {
                        Image(systemName: "icloud.and.arrow.down")
                            .imageScale(.large)
                    } else {
                        Image(systemName: "checkmark.icloud.fill")
                            .imageScale(.large)
                    }
                }
            } else if modelSize.rawValue == "base" {
                if language.rawValue == "en" {
                    if recordDownloadedModels.isDownloadedBaseEn {
                        Image(systemName: "icloud.and.arrow.down")
                            .imageScale(.large)
                    } else {
                        Image(systemName: "checkmark.icloud.fill")
                            .imageScale(.large)
                    }
                } else {
                    if recordDownloadedModels.isDownloadedBaseMulti {
                        Image(systemName: "icloud.and.arrow.down")
                            .imageScale(.large)
                    } else {
                        Image(systemName: "checkmark.icloud.fill")
                            .imageScale(.large)
                    }
                }
            } else {
                if language.rawValue == "en" {
                    if recordDownloadedModels.isDownloadedSmallEn {
                        Image(systemName: "icloud.and.arrow.down")
                            .imageScale(.large)
                    } else {
                        Image(systemName: "checkmark.icloud.fill")
                            .imageScale(.large)
                    }
                } else {
                    if recordDownloadedModels.isDownloadedSmallMulti {
                        Image(systemName: "icloud.and.arrow.down")
                            .imageScale(.large)
                    } else {
                        Image(systemName: "checkmark.icloud.fill")
                            .imageScale(.large)
                    }
                }
            }
        }
        .onTapGesture(perform: {
            if recognizer.whisperModel?.name != "\(modelSize.rawValue)-\(language.rawValue)" {
                self.showDialogue = true
            }
        })
        .alert(isPresented: $showDialogue) {
            Alert(title: Text("モデルを変更しますか？"),
                  message: Text("一部のモデルはダウンロードが行われます"),
                  primaryButton: .cancel(Text("キャンセル")),
                  secondaryButton: .default(Text("変更"), action: {
                      let isSucceed: Bool
                      do { isSucceed = try changeModel() }
                      catch { isSucceed = false }
                      if isSucceed {
                          defaultModelPath = (recognizer.whisperModel?.localPath)!
                          defaultModelSize = modelSize
                          defaultLanguage = language
                          dafaultNeedsSubscription = needsSubscription
                      }
                  }))
        }
    }

    private func changeModel() throws -> Bool {
        if recognizer.whisperModel?.name != "\(modelSize.rawValue)-\(language.rawValue)" {
            do {
                let whisperModel = try WhisperModel(
                    size: modelSize,
                    language: language,
                    needsSubscription: needsSubscription,
                    callback: recognizer.load_model_path
                )
                recognizer.whisperModel = whisperModel
            } catch {
                print("changeModel failed")
                return false
            }
            return true
        } else {
            return false
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
]
let modelLoadMenuItem = MenuItem(view: AnyView(ModelLoadMenuItemView()), subMenuItems: modeLoadSubMenuItems)
