import SwiftUI

struct RecognitionPresetPane: View {
    @Binding var isRecognitionPresetSelectionPaneOpen: Bool
    var body: some View {
        GeometryReader {
            geometry in
            ScrollView {
                VStack(alignment: .leading) {
                    HStack {
                        ZStack(alignment: .trailing){
                            Text("音声認識設定")
                                .font(.title)
                                .fontWeight(.bold)
                                // this force the alignment center
                                .frame(maxWidth: .infinity)
                            Button(action: {
                                isRecognitionPresetSelectionPaneOpen = false
                            }){
                                Image(systemName: "xmark")
                                    .font(.title3)
                                    .foregroundColor(Color.secondary)
                                    .padding(.trailing)
                            }
                        }
                    }
                    .padding(.top)
                    ForEach(Size.allCases) { size in
                        ForEach([Language.en, Language.ja]) {
                            lang in
                            RecognitionPresetRow(
                                modelSize: size,
                                modelLanguage: lang == Language.en ? Lang.en : Lang.multi,
                                recognitionLanguage: lang,
                                geometryWidth: geometry.size.width
                            )
                            Divider()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }
}

struct RecognitionPresetRow: View {
    @AppStorage(userDefaultModelSizeKey) var defaultModelSize = Size()
    @AppStorage(userDefaultModelLanguageKey) var defaultLanguage = Lang()
    @AppStorage(userDefaultRecognitionLanguageKey) var defaultRecognitionLanguage = Language()
    @EnvironmentObject var recognizer: WhisperRecognizer

    var modelSize: Size
    var modelLanguage: Lang
    var recognitionLanguage: Language
    var geometryWidth: Double
    var whisperModel: WhisperModel

    @AppStorage var isDownloaded: Bool
    @AppStorage private var isDownloading: Bool
    @State var progressValue: CGFloat
    @State var isShowAlert = false

    var isSelected: Bool {
        modelSize == recognizer.whisperModel.size &&
            modelLanguage == recognizer.whisperModel.language &&
            recognitionLanguage == defaultRecognitionLanguage
    }

    // MARK: - design related constants

    let itemMinHeight: CGFloat = 50
    let modelInformationItemColor = Color(uiColor: .systemGray5).opacity(0.8)
    let modelInformationItemCornerRadius: CGFloat = 20
    let iconSize: CGFloat = 20
    let downloadIconOffset: CGFloat = 5
    let recommendTagOffset: CGFloat = 10

    init(
        modelSize: Size,
        modelLanguage: Lang,
        recognitionLanguage: Language,
        geometryWidth: Double
    ) {
        self.modelSize = modelSize
        self.modelLanguage = modelLanguage
        self.recognitionLanguage = recognitionLanguage
        self.geometryWidth = geometryWidth
        let isDownloadedKey = "\(userDefaultWhisperModelDownloadPrefix)-\(modelSize)-\(modelLanguage)"
        _isDownloaded = AppStorage(wrappedValue: false, isDownloadedKey)
        let isDownloadingKey = "\(userDefaultWhisperModelDownloadingPrefix)-\(modelSize)-\(modelLanguage)"
        _isDownloading = AppStorage(wrappedValue: false, isDownloadingKey)
        progressValue = UserDefaults.standard.bool(forKey: isDownloadingKey) ? 0.5 : 0.0

        whisperModel = WhisperModel(
            size: self.modelSize,
            language: self.modelLanguage
        )
    }

    var body: some View {
        HStack {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: iconSize))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .green)
            ZStack(alignment: .topTrailing) {
                ZStack(alignment: .bottomTrailing) {
                    VStack {
                        Text(recognitionLanguage.displayName)
                            .font(.title2)
                        Text(modelSize.displayName)
                            .font(.title2)
                    }
                    .frame(maxWidth: geometryWidth / 5, minHeight: itemMinHeight)
                    .padding()
                    .background(modelInformationItemColor)
                    .cornerRadius(modelInformationItemCornerRadius)
                    if isDownloading {
                        CircularProgressBar(progress: $progressValue)
                            .frame(width: iconSize, height: iconSize)
                    } else {
                        if isDownloaded {
                            Image(systemName: "checkmark.icloud.fill")
                                .font(.system(size: iconSize))
                                .offset(x: downloadIconOffset)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .cyan)
                        } else {
                            Image(systemName: "icloud.and.arrow.down")
                                .font(.system(size: iconSize))
                                .offset(x: downloadIconOffset)
                                .foregroundColor(.cyan)
                        }
                    }
                }
                if WhisperModelRepository.isModelBundled(size: modelSize, language: modelLanguage) {
                    Text("おすすめ")
                        .font(.caption)
                        .foregroundColor(Color.black)
                        .padding(.horizontal)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.yellow))
                        .offset(x: recommendTagOffset)
                }
            }
            VStack(alignment: .leading) {
                HStack {
                    Text("精度")
                        .frame(width: geometryWidth / 8)
                    Group {
                        ForEach(0 ..< modelSize.accuracy) { _ in
                            Image(systemName: "star.fill")
                                .frame(width: geometryWidth / 15)
                        }
                        ForEach(0 ..< 3 - modelSize.accuracy) { _ in
                            Image(systemName: "star")
                                .frame(width: geometryWidth / 15)
                        }
                    }
                }
                HStack {
                    Text("速度")
                        .frame(width: geometryWidth / 8)
                    ForEach(0 ..< modelSize.speed) { _ in
                        Image(systemName: "car.side.fill")
                            .frame(width: geometryWidth / 15)
                    }
                    ForEach(0 ..< 3 - modelSize.speed) { _ in
                        Image(systemName: "car.side")
                            .frame(width: geometryWidth / 15)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: itemMinHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            isShowAlert = isDownloading || isSelected ? false : true
        }
        .alert(isPresented: $isShowAlert) {
            isDownloaded ?
                Alert(
                    title: Text("モデルを変更しますか？"),
                    primaryButton: .cancel(Text("キャンセル")),
                    secondaryButton: .default(Text("変更"), action: loadModel)
                )
                : Alert(
                    title: Text("モデルをダウンロードしますか?"),
                    message: Text("\(modelSize.megabytes, specifier: "%.3f") MBの通信容量が必要です。"),
                    primaryButton: .cancel(Text("キャンセル")),
                    secondaryButton: .default(Text("ダウンロード"), action: downloadModel)
                )
        }
    }

    private func loadModel() {
        recognizer.whisperModel.freeModel()
        recognizer.whisperModel = whisperModel

        whisperModel.loadModel {
            err in
            if let err {
                return
            }
            defaultModelSize = modelSize
            defaultLanguage = modelLanguage
            defaultRecognitionLanguage = recognitionLanguage
        }
    }

    private func downloadModel() {
        isDownloading = true
        whisperModel.downloadModel { err in
            isDownloading = false
            isDownloaded = true
            if let err {
                Logger.error(err)
            }
            DispatchQueue.main.async {
                loadModel()
            }
        } updateCallback: { num in
            progressValue = CGFloat(num)
        }
    }
}

struct RecognitionPresetPane_Previews: PreviewProvider {
    @State static var isRecognitionPresetSelectionPaneOpen = true
    static var previews: some View {
        RecognitionPresetPane(isRecognitionPresetSelectionPaneOpen: $isRecognitionPresetSelectionPaneOpen)
    }
}