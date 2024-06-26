import SwiftUI

let userDefaultModelSizeKey = "user-default-model-size"

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
    @Binding var progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 4.0)
                .opacity(0.3)
                .foregroundColor(.gray)

            Circle()
                .trim(from: 0.0, to: min(CGFloat(progress), 1.0))
                .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .foregroundColor(.blue)
                .rotationEffect(Angle(degrees: 270.0))
        }
    }
}

struct ModelRow: View {
    @EnvironmentObject var recognitionManager: RecognitionManager

    let recognitionLanguage: RecognitionLanguage
    @ObservedObject var whisperModel: WhisperModel

    // Only one `.alert` modifier can be used with one view,
    // thus use `isDeletePrompt` flag to detect deletion alert or download alert
    @State private var isDeletePrompt = false
    @State private var showPrompt = false

    // TODO: remove the following states and store the states in a class for managing models (#282)
    @AppStorage private var isDownloading: Bool
    @AppStorage private var isDownloaded: Bool
    @AppStorage private var progressValue: Double

    init(whisperModel: WhisperModel, recognitionLanguage: RecognitionLanguage) {
        self.whisperModel = whisperModel
        self.recognitionLanguage = recognitionLanguage

        let isDownloadingKey = "\(USER_DEFAULT_MODEL_DOWNLOADING_PREFIX)-\(whisperModel.name)"
        let isDownloadedKey = "\(USER_DEFAULT_MODEL_DOWNLOADED_PREFIX)-\(whisperModel.name)"
        let progressValueKey = "\(USER_DEFAULT_MODEL_PROGRESS_PREFIX)-\(whisperModel.name)"
        _isDownloading = AppStorage(wrappedValue: false, isDownloadingKey)
        _isDownloaded = AppStorage(wrappedValue: whisperModel.isDownloaded, isDownloadedKey)
        _progressValue = AppStorage(wrappedValue: 0, progressValueKey)
    }

    var body: some View {
        HStack {
            Text("\(whisperModel.size.displayName) - ").font(.headline)
            // NSLocalizedString is needed for dynamic string
            Text(NSLocalizedString(recognitionLanguage.displayName, comment: ""))
                .font(.headline)
            Spacer()
            if !whisperModel.isBundled {
                if isDownloading {
                    CircularProgressBar(progress: $progressValue)
                        .frame(width: 18, height: 18)
                } else {
                    if isDownloaded {
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
            guard !isDownloaded else {
                return
            }

            showPrompt = true
            isDeletePrompt = false
        }
        .alert(isPresented: $showPrompt) { alertView }
    }

    var isDeleteDisabled: Bool {
        whisperModel.isBundled
            || !isDownloaded
            || recognitionManager.isModelSelected(whisperModel)
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

    private func downloadModel() {
        isDownloading = true
        try! whisperModel.downloadModel { err in
            isDownloading = false
            isDownloaded = true
            progressValue = 0

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
            isDownloaded = false
        } catch {
            Logger.error(error)
        }
    }
}

struct ModelManagementView: View {
    var body: some View {
        List {
            ForEach(Size.allCases) { size in
                ForEach(RecognitionLanguage.allCases) { lang in
                    let model = WhisperModel(
                        size: size,
                        recognitionLanguage: lang
                    )
                    ModelRow(
                        whisperModel: model,
                        recognitionLanguage: lang
                    )
                }
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
