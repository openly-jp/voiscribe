import SwiftUI

let userDefaultModelSizeKey = "user-default-model-size"
let userDefaultModelLanguageKey = "user-default-model-language"

struct ModelLoadMenuItemView: View {
    var body: some View {
        NavigationLink(destination: ModelManagementView()) {
            HStack {
                Image(systemName: "ear.fill")
                    .imageScale(.large)
                    .frame(width: 32)
                Text("認識モデル")
                    .font(.headline)
                Spacer()
            }
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

struct ModelRow: View {
    @EnvironmentObject var recognizer: WhisperRecognizer
    @State var progressValue: CGFloat = 0.0

    let modelSize: Size
    let language: ModelLanguage
    let modelDisplayName: String
    @ObservedObject var whisperModel: WhisperModel

    // Only one `.alert` modifier can be used with one view,
    // thus use `isDeletePrompt` flag to detect deletion alert or download alert
    @State private var isDeletePrompt = false
    @State private var showPrompt = false
    @AppStorage private var isDownloading: Bool
    @AppStorage(userDefaultRecognitionLanguageKey) var defaultRecognitionLanguage = RecognitionLanguage()

    init(modelSize: Size, language: ModelLanguage, modelDisplayName: String) {
        self.modelSize = modelSize
        self.language = language
        self.modelDisplayName = modelDisplayName
        let isDownloadingKey = "\(userDefaultWhisperModelDownloadingPrefix)-\(modelSize)-\(language)"
        _isDownloading = AppStorage(wrappedValue: false, isDownloadingKey)
        whisperModel = WhisperModel(size: modelSize, language: language)
    }

    var body: some View {
        HStack {
            Text(modelDisplayName)
                .font(.headline)
            Spacer()
            if !WhisperModelRepository.isModelBundled(size: modelSize, language: language) {
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
        // this enable user to tap on Spacer
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing) {
            Button {
                if !isDeleteDisabled {
                    showPrompt = true
                    isDeletePrompt = true
                }
            } label: { Image(systemName: "trash.fill") }
                .tint(isDeleteDisabled ? .gray : .red)
        }
        .onTapGesture {
            guard !isDownloading else {
                return
            }
            guard !whisperModel.isDownloaded else {
                return
            }

            showPrompt = true
            isDeletePrompt = false
        }
        .alert(isPresented: $showPrompt) { alertView }
    }

    var isDeleteDisabled: Bool {
        WhisperModelRepository.isModelBundled(size: modelSize, language: language) || !whisperModel.isDownloaded
    }

    var alertView: Alert {
        if isDeletePrompt {
            return Alert(
                title: Text("モデルを削除しますか?"),
                message: Text("モデルは削除後も再びダウンロード可能です。"),
                primaryButton: .cancel(Text("キャンセル")),
                secondaryButton: .destructive(Text("削除"), action: deleteModel)
            )
        } else {
            return Alert(
                title: Text("モデルをダウンロードしますか?"),
                message: Text("通信容量にご注意ください。"),
                primaryButton: .cancel(Text("キャンセル")),
                secondaryButton: .default(Text("ダウンロード"), action: downloadModel)
            )
        }
    }

    var isModelSelected: Bool {
        whisperModel.equalsTo(recognizer.whisperModel) && recognitionLanguage == defaultRecognitionLanguage
    }

    private func downloadModel() {
        isDownloading = true
        whisperModel.downloadModel { err in
            isDownloading = false
            if let err {
                Logger.error(err)
            }
        } updateCallback: { num in
            progressValue = CGFloat(num)
        }
    }

    func deleteModel() {
        do {
            try whisperModel.deleteModel()
        } catch {
            Logger.error(error)
        }
    }
}

struct ModelManagementView: View {
    let models = [
        ("base", "multi", "Base"),
        ("base", "en", "Base(EN)"),
        ("small", "multi", "Small"),
        ("small", "en", "Small(EN)"),
        ("medium", "multi", "Medium"),
        ("medium", "en", "Medium(EN)"),
    ]
    var body: some View {
        List {
            ForEach(models, id: \.2) { model in
                ModelRow(
                    modelSize: Size(rawValue: model.0)!,
                    language: ModelLanguage(rawValue: model.1)!,
                    modelDisplayName: model.2
                )
            }
        }
    }
}

let modelLoadMenuItem = MenuItem(view: AnyView(ModelLoadMenuItemView()), subMenuItems: nil)

struct ModelManagementView_Previews: PreviewProvider {
    static var previews: some View {
        ModelManagementView()
    }
}
