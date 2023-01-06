import SwiftUI

struct DeveloperMainView: View {
    // This will be utilized as a developer main view
    @State var text = "まだ認識されていません"
    @State var audio_file_name = "sample_wav1"
    @EnvironmentObject var recognizer: WhisperRecognizer
    func recognize(audioFileName: String) -> String {
        guard let url: URL = Bundle.main.url(forResource: audioFileName, withExtension: "wav") else {
            return "音声のロードに失敗しました"
        }
        guard let recognizedSpeech = try? recognizer.recognize(
            audioFileURL: url,
            language: Language.en,
            callback: { rs in
                let transcriptionLines = rs.transcriptionLines
                for i in 0..<transcriptionLines.count {
                    text += transcriptionLines[i].text
                }
                print("inside callback", text)
            }
        ) else{
            return "認識に失敗しました"
        }
        return ""
    }
    var body: some View {
        VStack {
            HStack{
                Text("音声認識テスト").font(.title).fontWeight(.bold)
                Image(systemName: "mic.circle.fill").resizable()
                    .frame(width: 30.0, height: 30.0)
            }
            Spacer().frame(height: 30)
            Text("選択中サンプル: \(audio_file_name)")
            Text("認識結果: \(text)")
            HStack{
                Button("サンプル1", action: {audio_file_name = "sample_wav1"}).buttonStyle(.bordered)
                Button("サンプル2", action: {
                    audio_file_name = "sample_wav2"
                }).buttonStyle(.bordered)
            }
            Button("認識開始", action: {
                text = recognize(audioFileName: audio_file_name)
            }).buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct DeveloperMainView_Previews: PreviewProvider {
    static var previews: some View {
        DeveloperMainView()
    }
}