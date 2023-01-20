import SwiftUI

let UserDefaultASRModelNameKey = "user-default-asr-model-name"

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
    @AppStorage(UserDefaultASRModelNameKey) var defaultModelName = "ggml-tiny.en"
    let modelName: String
    let modelDisplayName: String
    @State private var showDialogue = false

    var body: some View {
        HStack {
            if recognizer.usedModelName == modelName {
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
            if recognizer.usedModelName != modelName {
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
                          // change default model name for next model loading time
                          defaultModelName = modelName
                      }
                  }))
        }
    }

    private func changeModel() -> Bool {
        do {
            if recognizer.usedModelName != modelName {
                try recognizer.load_model(modelName: modelName)
            }
        } catch {
            return false
        }
        return true
    }
}

let modeLoadSubMenuItems = [
    MenuItem(view: AnyView(ModelLoadSubMenuItemView(modelName: "ggml-tiny", modelDisplayName: "Tiny")), subMenuItems: nil),
    MenuItem(view: AnyView(ModelLoadSubMenuItemView(modelName: "ggml-tiny.en", modelDisplayName: "Tiny(En)")), subMenuItems: nil),
    MenuItem(view: AnyView(ModelLoadSubMenuItemView(modelName: "ggml-base", modelDisplayName: "Base")), subMenuItems: nil),
    MenuItem(view: AnyView(ModelLoadSubMenuItemView(modelName: "ggml-base.en", modelDisplayName: "Base(En)")), subMenuItems: nil),
    MenuItem(view: AnyView(ModelLoadSubMenuItemView(modelName: "ggml-small", modelDisplayName: "Small")), subMenuItems: nil),
    MenuItem(view: AnyView(ModelLoadSubMenuItemView(modelName: "ggml-small.en", modelDisplayName: "Small(En)")), subMenuItems: nil),
]

let modelLoadMenuItem = MenuItem(view: AnyView(ModelLoadMenuItemView()), subMenuItems: modeLoadSubMenuItems)
