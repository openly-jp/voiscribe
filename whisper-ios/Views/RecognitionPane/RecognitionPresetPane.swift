import SwiftUI

struct RecognitionPresetPane: View {
    @Binding var isRecognitionPresetSelectionPaneOpen: Bool
    var body: some View {
        GeometryReader {
            geometry in
            ScrollView {
                VStack(alignment: .leading) {
                    HStack {
                        ZStack(alignment: .leading) {
                            Text("音声認識設定")
                                .font(.title)
                                .fontWeight(.bold)
                                // this force the alignment center
                                .frame(maxWidth: .infinity)
                            Button(action: {
                                isRecognitionPresetSelectionPaneOpen = false
                            }) {
                                Image(systemName: "xmark")
                                    .font(.title3)
                                    .foregroundColor(Color.secondary)
                                    .padding(.leading)
                            }
                        }
                    }
                    .padding(.top)
                    ForEach(Size.allCases) { size in
                        ForEach(RecognitionLanguage.allCases) { lang in
                            RecognitionPresetRow(
                                whisperModel: WhisperModel(size: size, recognitionLanguage: lang),
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
    @EnvironmentObject var recognitionManager: RecognitionManager

    var recognitionLanguage: RecognitionLanguage
    var geometryWidth: Double
    var whisperModel: WhisperModel

    @AppStorage private var isDownloading: Bool
    @State var progressValue: CGFloat
    @State var isShowAlert = false

    var isSelected: Bool {
        recognitionManager.isModelSelected(whisperModel)
            && recognitionLanguage == recognitionManager.currentRecognitionLanguage
    }

    // MARK: - design related constants

    let itemMinHeight: CGFloat = 50
    let modelInformationItemColor = Color(uiColor: .systemGray5).opacity(0.8)
    let modelInformationItemCornerRadius: CGFloat = 20
    let iconSize: CGFloat = 20
    let modelSelectedIconSize: CGFloat = 30
    let modelSelectedMarginSize: CGFloat = 20
    let downloadIconOffset: CGFloat = 5
    let recommendTagOffset: CGFloat = 10

    init(
        whisperModel: WhisperModel,
        recognitionLanguage: RecognitionLanguage,
        geometryWidth: Double
    ) {
        self.whisperModel = whisperModel
        self.recognitionLanguage = recognitionLanguage
        self.geometryWidth = geometryWidth

        let isDownloadingKey = "\(userDefaultWhisperModelDownloadingPrefix)-\(whisperModel.name)"
        _isDownloading = AppStorage(wrappedValue: false, isDownloadingKey)
        progressValue = UserDefaults.standard.bool(forKey: isDownloadingKey) ? 0.5 : 0.0
    }

    var body: some View {
        HStack {
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: modelSelectedIconSize))
                    .symbolRenderingMode(.palette)

                    .foregroundStyle(.white, .green)
            } else {
                Image(systemName: "circle")
                    .font(.system(size: modelSelectedIconSize))
                    .foregroundColor(modelInformationItemColor)
            }
            Spacer().frame(width: modelSelectedMarginSize)

            ZStack(alignment: .topTrailing) {
                ZStack(alignment: .bottomTrailing) {
                    VStack {
                        // NSLocalizedString is needed for dynamic string
                        Text(NSLocalizedString(recognitionLanguage.displayName, comment: ""))
                            .font(.title3)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(whisperModel.size.displayName)
                            .font(.title3)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: geometryWidth / 5, minHeight: itemMinHeight)
                    .padding()
                    .background(modelInformationItemColor)
                    .cornerRadius(modelInformationItemCornerRadius)
                    if isDownloading {
                        CircularProgressBar(progress: $progressValue)
                            .frame(width: iconSize, height: iconSize)
                    } else {
                        if whisperModel.isDownloaded || whisperModel.isBundled {
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
                if whisperModel.isBundled {
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
                        .font(.caption)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(width: geometryWidth / 8)
                    Group {
                        ForEach(0 ..< whisperModel.size.accuracy) { _ in
                            Image(systemName: "star.fill")
                                .frame(width: geometryWidth / 15)
                        }
                        ForEach(0 ..< 3 - whisperModel.size.accuracy) { _ in
                            Image(systemName: "star")
                                .frame(width: geometryWidth / 15)
                        }
                    }
                }
                HStack {
                    Text("速度")
                        .font(.caption)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(width: geometryWidth / 8)
                    ForEach(0 ..< whisperModel.size.speed) { _ in
                        Image(systemName: "hare.fill")
                            .frame(width: geometryWidth / 15)
                    }
                    ForEach(0 ..< 3 - whisperModel.size.speed) { _ in
                        Image(systemName: "hare")
                            .frame(width: geometryWidth / 15)
                    }
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: itemMinHeight)
        .contentShape(Rectangle())
        .onTapGesture { isShowAlert = !isDownloading && !isSelected }
        .alert(isPresented: $isShowAlert) {
            whisperModel.isDownloaded || whisperModel.isBundled ?
                Alert(
                    title: Text("モデルを変更しますか？"),
                    primaryButton: .cancel(Text("キャンセル")),
                    secondaryButton: .default(Text("変更"), action: loadModel)
                )
                : Alert(
                    title: Text("モデルをダウンロードしますか?"),
                    message: Text("\(whisperModel.getModelMegaBytes()) MBの通信容量が必要です"),
                    primaryButton: .cancel(Text("キャンセル")),
                    secondaryButton: .default(Text("ダウンロード"), action: downloadModel)
                )
        }
    }

    private func loadModel() {
        recognitionManager.changeModel(
            newModel: whisperModel,
            recognitionLanguage: recognitionLanguage
        ) { err in
            guard let err else { return }

            Logger.error("Failed to load model: \(whisperModel.name)")
            Logger.error(err)
        }
    }

    private func downloadModel() {
        isDownloading = true
        whisperModel.downloadModel { err in
            isDownloading = false

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
