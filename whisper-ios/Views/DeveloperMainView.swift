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
                for i in 0 ..< transcriptionLines.count {
                    text += transcriptionLines[i].text
                }
            }
        ) else {
            return "認識に失敗しました"
        }
        return ""
    }

    var body: some View {
        StreamingRecognitionTestView()
    }
}

struct DeveloperMainView_Previews: PreviewProvider {
    static var previews: some View {
        DeveloperMainView()
    }
}
