import SwiftUI

struct RecognitionPresetPane: View {
    var body: some View {
        GeometryReader {
            geometry in
            ScrollView {
                VStack(alignment: .leading) {
                    Spacer().frame(height: 30)
                    HStack {
                        Text("音声認識設定")
                            .font(.title)
                            .fontWeight(.bold)
                        // this force the alignment center
                            .frame(maxWidth: .infinity)
                    }
                    ForEach(Size.allCases) { size in
                        ForEach([Language.en, Language.ja]) {
                            lang in
                            RecognitionPresetRow(modelSize: size, modelLanguage: lang == Language.en ? Lang.en : Lang.multi, recognitionLanguage: lang, geometryWidth: geometry.size.width)
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
    @AppStorage(userDefaultModelSizeKey) var defaultModelSize = Size(rawValue: "tiny")!
    @AppStorage(userDefaultModelLanguageKey) var defaultLanguage = Lang(rawValue: "en")!
    @AppStorage(UserDefaultASRLanguageKey) var defaultLanguageRawValue = Language.en.rawValue
    @EnvironmentObject var recognizer: WhisperRecognizer
    var modelSize: Size
    var modelLanguage: Lang
    var recognitionLanguage: Language
    var geometryWidth: Double
    var whisperModel: WhisperModel
    
    @State private var isDownloading = false
    @State var progressValue: CGFloat = 0.0
    @State var isShowAlert = false
    
    init (
        modelSize: Size,
        modelLanguage: Lang,
        recognitionLanguage: Language,
        geometryWidth: Double
    ) {
        self.modelSize = modelSize
        self.modelLanguage = modelLanguage
        self.recognitionLanguage = recognitionLanguage
        self.geometryWidth = geometryWidth
        self.whisperModel = WhisperModel(
            size: self.modelSize,
            language: self.modelLanguage
        )
    }
    
    var body: some View {
        HStack {
            Image(systemName: modelSize == recognizer.whisperModel.size &&
                  modelLanguage == recognizer.whisperModel.language &&
                  recognitionLanguage.rawValue == defaultLanguageRawValue ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 20))
            .symbolRenderingMode(.palette)
            .foregroundStyle(.white, .green)
            ZStack(alignment: .bottomTrailing) {
                VStack {
                    Text(recognitionLanguage.displayName)
                        .font(.title2)
                    Text(modelSize.displayName)
                        .font(.title2)
                }
                .frame(maxWidth: geometryWidth / 5, minHeight: 50)
                .padding()
                .background(Color(uiColor: .systemGray5).opacity(0.8))
                .cornerRadius(20)
                if isDownloading {
                    CircularProgressBar(progress: $progressValue)
                        .frame(width: 20, height: 20)
                } else {
                    if whisperModel.isDownloaded {
                        Image(systemName: "checkmark.icloud.fill")
                            .font(.system(size: 20))
                            .offset(x: 5)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .cyan)
                    } else {
                        Image(systemName: "icloud.and.arrow.down")
                            .font(.system(size: 20))
                            .offset(x: 5)
                            .foregroundColor(.cyan)
                    }
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
                        ForEach(0 ..< 4 - modelSize.accuracy) { _ in
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
                    ForEach(0 ..< 4 - modelSize.speed) { _ in
                        Image(systemName: "car.side")
                            .frame(width: geometryWidth / 15)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 50)
        .contentShape(Rectangle())
        .onTapGesture {
            isShowAlert = true
        }
        .alert(isPresented: $isShowAlert){
            whisperModel.isDownloaded ?
            Alert(
                title: Text("モデルを変更しますか？"),
                primaryButton: .cancel(Text("キャンセル")),
                secondaryButton: .default(Text("変更"), action: loadModel)
            )
            : Alert(
                title: Text("モデルをダウンロードしますか?"),
                message: Text("\(modelSize.gigabytes, specifier: "%.3f") GBの通信容量が必要です。"),
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
            defaultLanguageRawValue = recognitionLanguage.rawValue
        }
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
}

struct RecognitionPresetPane_Previews: PreviewProvider {
    static var previews: some View {
        RecognitionPresetPane()
    }
}
