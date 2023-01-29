import SwiftUI

let userDefaultModelSizeKey = "user-default-model-size"
let userDefaultModelLanguageKey = "user-default-model-language"
let userDefaultModelNeedsSubscriptionKey = "user-default-model-needs-subscription"

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
    @AppStorage(userDefaultModelSizeKey) var defaultModelSize: Size = .init(rawValue: "tiny")!
    @AppStorage(userDefaultModelLanguageKey) var defaultLanguage: Lang = .init(rawValue: "en")!
    @AppStorage(userDefaultModelNeedsSubscriptionKey) var dafaultNeedsSubscription: Bool = false
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
        }
        .onTapGesture(perform: {
            print("model_name", recognizer.whisperModel?.name)
            print("\(modelSize.rawValue)-\(language.rawValue)")

            if recognizer.whisperModel?.name != "\(modelSize.rawValue)-\(language.rawValue)" {
                self.showDialogue = true
            }
        })
        .alert(isPresented: $showDialogue) {
            Alert(title: Text("モデルを変更しますか？"),
                  message: Text("一部のモデルはダウンロードが行われます"),
                  primaryButton: .cancel(Text("キャンセル")),
                  secondaryButton: .default(Text("変更"), action: {
                      let isSucceed = changeModel()
                      if isSucceed {
                          defaultModelSize = modelSize
                          defaultLanguage = language
                          dafaultNeedsSubscription = needsSubscription
                      }
                  }))
        }
    }

    private func loadWhisperModelURL(whisperModelURL: URL) -> Void {
        do {
            try recognizer.load_model(whisperModelURL: whisperModelURL)
        } catch {
            print("model loading failed in loadModel")
        }
    }

    private func changeModel() -> Bool {
        do {
            if recognizer.whisperModel?.name != "\(modelSize.rawValue)-\(language.rawValue)" {
                let whisperModel = WhisperModel(size: modelSize, language: language, needsSubscription: needsSubscription, callBack: loadWhisperModelURL)
                recognizer.whisperModel = whisperModel
            }
        } catch {
            print("model loading failed")
            return false
        }
        return true
    }
}

let modeLoadSubMenuItems = [
    MenuItem(view: AnyView(ModelLoadSubMenuItemView(modelSize: Size(rawValue: "tiny")!, language: Lang(rawValue: "multi")!, needsSubscription: false, modelDisplayName: "Tiny")), subMenuItems: nil),
    MenuItem(view: AnyView(ModelLoadSubMenuItemView(modelSize: Size(rawValue: "tiny")!, language: Lang(rawValue: "en")!, needsSubscription: false, modelDisplayName: "Tiny(EN)")), subMenuItems: nil),
    MenuItem(view: AnyView(ModelLoadSubMenuItemView(modelSize: Size(rawValue: "base")!, language: Lang(rawValue: "multi")!, needsSubscription: false, modelDisplayName: "Base")), subMenuItems: nil),
    MenuItem(view: AnyView(ModelLoadSubMenuItemView(modelSize: Size(rawValue: "base")!, language: Lang(rawValue: "en")!, needsSubscription: false, modelDisplayName: "Base(EN)")), subMenuItems: nil),
    MenuItem(view: AnyView(ModelLoadSubMenuItemView(modelSize: Size(rawValue: "small")!, language: Lang(rawValue: "multi")!, needsSubscription: false, modelDisplayName: "Small")), subMenuItems: nil),
    MenuItem(view: AnyView(ModelLoadSubMenuItemView(modelSize: Size(rawValue: "small")!, language: Lang(rawValue: "en")!, needsSubscription: false, modelDisplayName: "Small(EN)")), subMenuItems: nil),
]
let modelLoadMenuItem = MenuItem(view: AnyView(ModelLoadMenuItemView()), subMenuItems: modeLoadSubMenuItems)
