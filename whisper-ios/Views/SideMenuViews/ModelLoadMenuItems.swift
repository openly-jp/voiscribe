import SwiftUI

let userDefaultModelSize: String = "modelSize"
let userDefaultModelLanguage: String = "modelLanguage"
let userDefaultModelNeedsSubscription: String = "modelNeedsSubscription"

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
    @AppStorage(userDefaultModelSize) var modelSize: Size = .init(rawValue: "tiny")!
    @AppStorage(userDefaultModelLanguage) var language: Lang = .init(rawValue: "en")!
    @AppStorage(userDefaultModelNeedsSubscription) var needsSubscription: Bool = false
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
            if recognizer.whisperModel?.name == "\(modelSize.rawValue)-\(language.rawValue)" {
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
                          self.modelSize = self.WhisperRecognizer.whisperModel?.size!
                          self.language = self.WhisperRecognizer.whisperModel?.language!
                          self.needsSubscription = self.WhisperRecognizer.whisperModel?.needsSubscription!
                      }
                  }))
        }
    }

    private func changeModel() -> Bool {
        do {
            if recognizer.whisperModel?.name != "\(modelSize.rawValue)-\(language.rawValue)" {
                let whisperModel = WhisperModel(size: modelSize, language: language, needsSubscription: needsSubscription)
                try recognizer.load_model(whisperModel: whisperModel)
            }
        } catch {
            return false
        }
        return true
    }
}

let modeLoadSubMenuItems = [
    MenuItem(view: AnyView(ModelLoadSubMenuItemView(modelSize: Size(rawValue: "tiny")!, language: Lang(rawValue: "multi")!, needsSubscription: false, modelDisplayName: "Tiny")), subMenuItems: nil),
    MenuItem(view: AnyView(ModelLoadSubMenuItemView(modelSize: Size(rawValue: "tiny")!, language: Lang(rawValue: "en")!, needsSubscription: false, modelDisplayName: "Tiny")), subMenuItems: nil),
    MenuItem(view: AnyView(ModelLoadSubMenuItemView(modelSize: Size(rawValue: "base")!, language: Lang(rawValue: "multi")!, needsSubscription: false, modelDisplayName: "Base")), subMenuItems: nil),
    MenuItem(view: AnyView(ModelLoadSubMenuItemView(modelSize: Size(rawValue: "base")!, language: Lang(rawValue: "en")!, needsSubscription: false, modelDisplayName: "Base")), subMenuItems: nil),
    MenuItem(view: AnyView(ModelLoadSubMenuItemView(modelSize: Size(rawValue: "small")!, language: Lang(rawValue: "multi")!, needsSubscription: false, modelDisplayName: "Small")), subMenuItems: nil),
    MenuItem(view: AnyView(ModelLoadSubMenuItemView(modelSize: Size(rawValue: "small")!, language: Lang(rawValue: "en")!, needsSubscription: false, modelDisplayName: "Small")), subMenuItems: nil),
]
let modelLoadMenuItem = MenuItem(view: AnyView(ModelLoadMenuItemView()), subMenuItems: modeLoadSubMenuItems)
