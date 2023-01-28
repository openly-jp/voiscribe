import AVFoundation
import Dispatch
import Foundation

class WhisperRecognizer: Recognizer {
    private var whisperContext: OpaquePointer?
    @Published var usedModelName: String?
    let serialDispatchQueue = DispatchQueue(label: "recognize")
    let samplingRate: Float = 16000
    var is_ready: Bool {
        whisperContext != nil
    }

    init(modelName: String) {
        do {
            try load_model(modelName: modelName)
            usedModelName = modelName
        } catch {
            usedModelName = "ggml-tiny"
            return
        }
    }

    deinit {
        if whisperContext != nil {
            whisper_free(whisperContext)
        }
    }

    func load_model(modelName: String) throws {
        guard let url: URL = Bundle.main.url(forResource: modelName, withExtension: "bin") else {
            throw NSError(domain: "model load error", code: -1)
        }
        whisperContext = whisper_init(url.path())
        if whisperContext == nil {
            throw NSError(domain: "model load error", code: -1)
        }
        usedModelName = modelName
    }

    private func load_audio(url: URL) throws -> [Float32] {
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

    func recognize(
        audioFileURL: URL,
        language: Language,
        callback: @escaping (RecognizedSpeech) -> Void
    ) throws -> RecognizedSpeech {
        guard let whisperContext else {
            throw NSError(domain: "model load error", code: -1)
        }

        guard let audioData = try? load_audio(url: audioFileURL) else {
            throw NSError(domain: "audio load error", code: -1)
        }

        let recognizedSpeech = RecognizedSpeech(
            audioFileURL: audioFileURL,
            language: language,
            transcriptionLines: []
        )
        DispatchQueue.global(qos: .userInteractive).async {
            let maxThreads = max(1, min(8, ProcessInfo.processInfo.processorCount - 2))
            var params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)
            language.rawValue.withCString { en in
                // Adapted from whisper.objc
                params.print_realtime = true
                params.print_progress = false
                params.print_timestamps = true
                params.print_special = false
                params.translate = false
                params.language = en
                params.n_threads = Int32(maxThreads)
                params.offset_ms = 0
                params.no_context = true
                params.single_segment = false

                whisper_reset_timings(whisperContext)
                audioData.withUnsafeBufferPointer { data in
                    if whisper_full(whisperContext, params, data.baseAddress, Int32(data.count)) != 0 {
                    } else {
                        whisper_print_timings(whisperContext)
                    }
                }
            }

            let n_segments = whisper_full_n_segments(whisperContext)
            for i in 0 ..< n_segments {
                let text = String(cString: whisper_full_get_segment_text(whisperContext, i))
                let startMSec = whisper_full_get_segment_t0(whisperContext, i) * 10
                let endMSec = whisper_full_get_segment_t1(whisperContext, i) * 10
                let transcriptionLine = TranscriptionLine(startMSec: startMSec, endMSec: endMSec, text: text, ordering: i)
                recognizedSpeech.transcriptionLines.append(transcriptionLine)
            }

            callback(recognizedSpeech)
        }

        return recognizedSpeech
    }

    func streamingRecognize(
        audioFileURL: URL,
        language: Language,
        recognizingSpeech: RecognizedSpeech,
        isPromptingActive: Bool,
        isRemainingAudioConcatActive: Bool,
        callback: @escaping (RecognizedSpeech) -> Void,
        feasibilityCheck: @escaping (RecognizedSpeech) -> Bool
    ) {
        serialDispatchQueue.async {
            Logger.debug("Prompting: \(isPromptingActive ? "active" : "inactive")")
            Logger.debug("Remaining Audio Concat: \(isRemainingAudioConcatActive ? "active" : "inactive")")
            guard let whisperContext = self.whisperContext else {
                Logger.error("model load error")
                return
            }
            guard var audioData = try? self.load_audio(url: audioFileURL) else {
                Logger.error("audio load error")
                return
            }
            do {
                try FileManager.default.removeItem(at: audioFileURL)
            } catch {
                Logger.warning("failed to remove audio file")
            }
            // check whether recognizingSpeech was removed (i.e. abort recording) or not
            if feasibilityCheck(recognizingSpeech) {
                let maxThreads = max(1, min(8, ProcessInfo.processInfo.processorCount - 2))
                var params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)
                language.rawValue.withCString { lang in
                    // Adapted from whisper.objc
                    params.print_realtime = true
                    params.print_progress = false
                    params.print_timestamps = true
                    params.print_special = false
                    params.translate = false
                    params.language = lang
                    params.n_threads = Int32(maxThreads)
                    params.offset_ms = 0
                    params.no_context = true
                    params.single_segment = false
                    params.prompt_tokens = UnsafePointer(recognizingSpeech.promptTokens)
                    params.prompt_n_tokens = Int32(recognizingSpeech.promptTokens.count)

                    whisper_reset_timings(whisperContext)
                    // append remaining previous audioData to audioData
                    audioData = recognizingSpeech.remainingAudioData + audioData
                    audioData.withUnsafeBufferPointer { data in
                        if whisper_full(whisperContext, params, data.baseAddress, Int32(data.count)) != 0 {
                        } else {
                            whisper_print_timings(whisperContext)
                        }
                    }
                }

                let baseStartMSec = recognizingSpeech.transcriptionLines.last?.endMSec ?? 0
                let baseOrdering = recognizingSpeech.transcriptionLines.last?.ordering != nil ? recognizingSpeech.transcriptionLines.last!.ordering + 1 : 0
                let nSegments = whisper_full_n_segments(whisperContext)
                var lastEndMSec: Int64 = 0
                for i in 0 ..< nSegments {
                    let text = String(cString: whisper_full_get_segment_text(whisperContext, i))
                    let startMSec = whisper_full_get_segment_t0(whisperContext, i) * 10 + baseStartMSec
                    let endMSec = whisper_full_get_segment_t1(whisperContext, i) * 10 + baseStartMSec
                    lastEndMSec = whisper_full_get_segment_t1(whisperContext, i) * 10
                    let transcriptionLine = TranscriptionLine(startMSec: startMSec, endMSec: endMSec, text: text, ordering: baseOrdering + i)
                    recognizingSpeech.transcriptionLines.append(transcriptionLine)
                }
                // update promptTokens
                if isPromptingActive {
                    recognizingSpeech.promptTokens.removeAll()
                    for i in 0 ..< nSegments {
                        let tokenCount = whisper_full_n_tokens(whisperContext, i)
                        for j in 0 ..< tokenCount {
                            let tokenId = whisper_full_get_token_id(whisperContext, i, j)
                            recognizingSpeech.promptTokens.append(tokenId)
                        }
                    }
                }
                // update remaining audioData
                if isRemainingAudioConcatActive {
                    let originalAudioDataCount: Int = audioData.count
                    let usedAudioDataCount = Int(Float(lastEndMSec) / Float(1000) * self.samplingRate)
                    let remainingAudioDataCount: Int = originalAudioDataCount - usedAudioDataCount
                    if remainingAudioDataCount > 0 {
                        recognizingSpeech.remainingAudioData = Array(audioData[usedAudioDataCount ..< originalAudioDataCount])
                    } else {
                        recognizingSpeech.remainingAudioData = []
                    }
                }

                recognizingSpeech.tmpAudioDataList.append(audioData)
                callback(recognizingSpeech)
            }
        }
    }
}
