import SwiftUI
import AVFoundation
import Foundation

struct MetaInfo: Hashable{
    var audioFileURL: URL
    var language: Language
    var label: String
    var transcripts: [String]
}

struct MetaInfoJson: Codable {
    var audioFileName: String
    var language: String
    var label: String
    var transcripts: [String]
}

let recordSettings = [
    AVFormatIDKey: Int(kAudioFormatLinearPCM),
    AVSampleRateKey: 16000,
    AVNumberOfChannelsKey: 1,
    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
]

struct StreamingRecognitionTestView: View {
    @EnvironmentObject var recognizer: WhisperRecognizer
    @AppStorage(UserDefaultRecognitionFrequencySecKey) var recognitionFrequencySec = 15
    @AppStorage(PromptingActiveKey) var promptingActive = true
    @AppStorage(RemainingAudioConcatActiveKey) var remainingAudioConcatActive = true
    
    // recognition related
    @State var recognizingSpeech: RecognizedSpeech?
    @State var audioFileURL: URL?
    @State var audioFileURLList: [URL] = []
    @State var language: Language?
    @State var transcripts: [String] = []
    
    let metaInfoList = getAllMetaInfoList()
    @State var selectedMetaInfo: MetaInfo?
    
    // recognition result related
    @State var recognizedTranscriptionLines: [TranscriptionLine] = []
    @State var recognizedTranscript: String?
    @State var charErrorRate: Float?
    
    // display handling
    @State var isSelectSampleReady: Bool = true
    @State var isRecognitionReady: Bool = false
    
    var body: some View {
        GeometryReader {
            geometry in
            VStack(alignment: .center){
                Text("ストリーミング認識テスト")
                    .font(.title)
                    .fontWeight(.bold)

                HStack {
                    Text("サンプル: ")
                    Menu(selectedMetaInfo?.label ?? "選択 ↕") {
                        ForEach(metaInfoList, id: \.self) {
                            metaInfo in
                            Button(metaInfo.label, action: {
                                selectedMetaInfo = metaInfo
                                audioFileURL = metaInfo.audioFileURL
                                language = metaInfo.language
                                transcripts = metaInfo.transcripts
                                preprocess(audioFileURL: audioFileURL!, language: language!)
                            })
                        }
                    }
                    .menuStyle(ButtonMenuStyle())
                    .disabled(!isSelectSampleReady)
                }
                
                Button("認識開始", action: {
                    isRecognitionReady = false
                    isSelectSampleReady = false
                    for (idx, audioFileURL) in audioFileURLList.enumerated() {
                        recognizer.streamingRecognize(
                            audioFileURL: audioFileURL,
                            language: language ?? Language.ja,
                            recognizingSpeech: recognizingSpeech!,
                            is_prompting: promptingActive,
                            is_remaining_audio_concat: remainingAudioConcatActive,
                            callback: { rs in
                                recognizedTranscriptionLines = rs.transcriptionLines
                                if idx == audioFileURLList.count - 1 {
                                    recognizedTranscript = recognizedTranscriptionLines.reduce("", {
                                        (old: String, new: TranscriptionLine) -> String in return old + new.text
                                    })
                                    let transcript = transcripts.reduce("", {
                                        (old: String, new: String) -> String in return old + new
                                    })
                                    charErrorRate = calculateCER(ref: transcript, out: recognizedTranscript ?? "")
                                    isSelectSampleReady = true
                                    isRecognitionReady = true
                                }
                            },
                            feasibilityCheck: { _ in
                                return true
                            }
                        )
                    }
                })
                .buttonStyle(.bordered)
                .disabled(!isRecognitionReady)
                
                Divider()
                Text("正解")
                    .font(.title2)
                    .fontWeight(.bold)
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(transcripts.enumerated()), id: \.self.offset){
                            index, transcript in
                            HStack{
                                Text(transcript)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(index % 2 == 0 ? Color.gray.opacity(0.1) : Color.gray.opacity(0.2))
                        }
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: geometry.size.height / 4, maxHeight: geometry.size.height / 4, alignment: .topLeading)
                Text("認識結果")
                    .font(.title2)
                    .fontWeight(.bold)
                ScrollView {
                    if recognizingSpeech != nil, recognizingSpeech!.transcriptionLines.count > 0 {
                        VStack(spacing: 0) {
                            ForEach(Array(recognizedTranscriptionLines.enumerated()), id: \.self.offset){
                                index, transcriptionLine in
                                HStack{
                                    Text(transcriptionLine.text)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(index % 2 == 0 ? Color.gray.opacity(0.1) : Color.gray.opacity(0.2))
                            }
                        }
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: geometry.size.height / 3, maxHeight: geometry.size.height / 3, alignment: .topLeading)
                Text("CER: \((charErrorRate ?? -1) < 0 ? "認識完了前" : "\(charErrorRate!)")")
                    .font(.title3)
                    .fontWeight(.bold)
            }
        }
    }
    
    func preprocess(audioFileURL: URL, language: Language) {
        recognizingSpeech = RecognizedSpeech(audioFileURL: audioFileURL, language: language)
        recognizedTranscriptionLines = []
        charErrorRate = nil
        
        guard let audioData = try? loadAudio(url: audioFileURL) else {
            Logger.error("audio load error")
            return
        }
        let audioDataSplitSize = recognitionFrequencySec * 16000
        for audioFileURL in audioFileURLList {
            do {
                try FileManager.default.removeItem(at: audioFileURL)
            } catch {
                Logger.warning("failed to remove audio files.")
            }
        }
        audioFileURLList.removeAll()
        for i in 0..<audioData.count/audioDataSplitSize + 1 {
            let start = i * audioDataSplitSize
            let end = (i + 1) * audioDataSplitSize
            var splittedAudioData: [Float32] = []
            if end > audioData.count {
                splittedAudioData = Array(audioData[start..<audioData.count])
            } else {
                splittedAudioData = Array(audioData[start..<end])
            }
            let url = getURLByName(fileName: "tmp\(i).m4a")
            do {
                try writeAudio(audioData: splittedAudioData, url: url)
                audioFileURLList.append(url)
            } catch {
                Logger.error("audio write error")
                return
            }
        }
        Logger.info("Ready for recognition.")
        isRecognitionReady = true
    }
}

// MARK: audio related func

func loadAudio(url: URL) throws -> [Float32] {
    guard let audio = try? AVAudioFile(forReading: url, commonFormat: .pcmFormatFloat32, interleaved: false) else {
        throw NSError(domain: "audio load error", code: -1)
    }
    guard let buffer = AVAudioPCMBuffer(pcmFormat: audio.processingFormat, frameCapacity: AVAudioFrameCount(audio.length)) else {
        throw NSError(domain: "audio load error", code: -1)
    }
    do {
        try audio.read(into: buffer)
    } catch {
        throw NSError(domain: "audio load error", code: -1)
    }
    guard let float32Data = buffer.floatChannelData else {
        throw NSError(domain: "audio load error", code: -1)
    }
    let audioData = Array(UnsafeBufferPointer(start: float32Data[0], count: Int(buffer.frameLength)))
    return audioData
}

func writeAudio(audioData: [Float32], url: URL) throws {
    guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false) else {
        throw NSError(domain: "audio write error", code: -1)
    }
    guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(audioData.count)) else {
        throw NSError(domain: "audio write error", code: -1)
    }
    for i in 0 ..< audioData.count {
        pcmBuffer.floatChannelData!.pointee[i] = Float(audioData[i])
    }
    pcmBuffer.frameLength = AVAudioFrameCount(audioData.count)
    guard let audioFile = try? AVAudioFile(forWriting: url, settings: recordSettings) else {
        throw NSError(domain: "audio write error", code: -1)
    }
    guard let _ = try? audioFile.write(from: pcmBuffer) else {
        throw NSError(domain: "audio write error", code: -1)
    }
}

func calculateCER(ref: String, out: String) -> Float {
    var dpTable = Array(repeating: Array(repeating: 0, count: out.count+1), count: ref.count+1)
    for rowIdx in 0..<ref.count + 1 {
        dpTable[rowIdx][0] = rowIdx
    }
    for colIdx in 0..<out.count + 1 {
        dpTable[0][colIdx] = colIdx
    }
    for rowIdx in 1..<ref.count + 1 {
        for colIdx in 1..<out.count + 1 {
            let refPos = ref.index(ref.startIndex, offsetBy: rowIdx-1)
            let outPos = out.index(out.startIndex, offsetBy: colIdx-1)
            if ref[refPos] == out[outPos] {
                dpTable[rowIdx][colIdx] = dpTable[rowIdx-1][colIdx-1]
            } else {
                dpTable[rowIdx][colIdx] = min(dpTable[rowIdx-1][colIdx] + 1, min(dpTable[rowIdx][colIdx-1] + 1, dpTable[rowIdx-1][colIdx-1] + 1))
            }
        }
    }
    return Float(dpTable[ref.count][out.count]) / Float(ref.count)
}

// MARK: meta info related func

func getAllMetaInfoList() -> [MetaInfo] {
    guard let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: "StreamingRecognitionTest") else {
        Logger.error("Failed to get urls for meta info.")
        return []
    }
    var metaInfoList: [MetaInfo] = []
    for url in urls {
        guard let jsonData = try? Data(contentsOf: url) else {
            Logger.error("Failed to load json data. \(url.absoluteString)")
            continue
        }
        guard let metaInfoJson = try? JSONDecoder().decode(MetaInfoJson.self, from: jsonData) else {
            Logger.error("Failed to decode json data. \(url.absoluteString)")
            continue
        }
        guard let audioFileURL = Bundle.main.url(forResource: metaInfoJson.audioFileName, withExtension: "wav", subdirectory: "StreamingRecognitionTest") else {
            Logger.error("Failed to get audio file url. \(url.absoluteString)")
            continue
        }
        guard let language = Language(rawValue: metaInfoJson.language) else {
            Logger.error("Language is not valid. \(metaInfoJson.language)")
            continue
        }
        let metaInfo = MetaInfo(audioFileURL: audioFileURL, language: language, label: metaInfoJson.label, transcripts: metaInfoJson.transcripts)
        metaInfoList.append(metaInfo)
    }
    return metaInfoList
}

struct StreamingRecognitionTestView_Previews: PreviewProvider {
    static var previews: some View {
        StreamingRecognitionTestView()
    }
}
