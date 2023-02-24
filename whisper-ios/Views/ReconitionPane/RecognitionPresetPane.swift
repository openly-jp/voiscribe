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
    @AppStorage(UserDefaultASRLanguageKey) var defaultLanguageRawValue = Language.en.rawValue
    let modelSize: Size
    let modelLanguage: Lang
    let recognitionLanguage: Language
    let geometryWidth: Double
    var body: some View {
            HStack {
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
                    if modelSize == defaultModelSize, recognitionLanguage.rawValue == defaultLanguageRawValue{
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .offset(x: 5)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .green)
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
                            ForEach(0 ..< 5 - modelSize.accuracy) { _ in
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
                        ForEach(0 ..< 5 - modelSize.speed) { _ in
                            Image(systemName: "car.side")
                                .frame(width: geometryWidth / 15)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .padding(.horizontal)
            .contentShape(Rectangle())
            .onTapGesture {
                defaultModelSize = modelSize
                defaultLanguageRawValue = recognitionLanguage.rawValue
            }
    }
}

struct RecognitionPresetPane_Previews: PreviewProvider {
    static var previews: some View {
        RecognitionPresetPane()
    }
}
