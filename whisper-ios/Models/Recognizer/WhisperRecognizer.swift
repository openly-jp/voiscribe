import AVFoundation
import Dispatch
import Foundation

class WhisperRecognizer: Recognizer {
    @Published var whisperModel: WhisperModel
    let serialDispatchQueue = DispatchQueue(label: "recognize")
    let samplingRate: Float = 16000

    var isRecognizing = false

    init(whisperModel: WhisperModel) throws {
        if whisperModel.localPath == nil {
            throw NSError(domain: "whisperModel.localPath is nil", code: -1)
        } else {
            self.whisperModel = whisperModel
        }
    }

    private func load_audio(url: URL) throws -> [Float32] {
        guard let audio = try? AVAudioFile(forReading: url, commonFormat: .pcmFormatFloat32, interleaved: false) else {
            throw NSError(domain: "audio load error", code: -1)
        }
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: audio.processingFormat,
            frameCapacity: AVAudioFrameCount(audio.length)
        ) else {
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
        guard let context: OpaquePointer = whisperModel.whisperContext else {
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

                whisper_reset_timings(context)
                audioData.withUnsafeBufferPointer { data in
                    if whisper_full(context, params, data.baseAddress, Int32(data.count)) != 0 {
                    } else {
                        whisper_print_timings(context)
                    }
                }
            }

            let n_segments = whisper_full_n_segments(context)
            for i in 0 ..< n_segments {
                let text = String(cString: whisper_full_get_segment_text(context, i))
                let startMSec = whisper_full_get_segment_t0(context, i) * 10
                let endMSec = whisper_full_get_segment_t1(context, i) * 10
                let transcriptionLine = TranscriptionLine(
                    startMSec: startMSec,
                    endMSec: endMSec,
                    text: text,
                    ordering: i
                )
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
            defer {
                self.isRecognizing = false
            }

            // prohibit user from changing model
            self.isRecognizing = true
            Logger.debug("Prompting: \(isPromptingActive ? "active" : "inactive")")
            Logger.debug("Remaining Audio Concat: \(isRemainingAudioConcatActive ? "active" : "inactive")")
            guard let context = self.whisperModel.whisperContext else {
                Logger.error("model load error")
                return
            }
            guard var originalAudioData = try? self.load_audio(url: audioFileURL) else {
                Logger.error("audio load error")
                return
            }
            recognizingSpeech.tmpAudioDataList.append(originalAudioData)
            // append remaining previous audioData to originalAudioData
            var audioData = recognizingSpeech.remainingAudioData + originalAudioData
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
                    params.suppress_non_speech_tokens = true
                    params.prompt_tokens = UnsafePointer(recognizingSpeech.promptTokens)
                    params.prompt_n_tokens = Int32(recognizingSpeech.promptTokens.count)

                    whisper_reset_timings(context)
                    audioData.withUnsafeBufferPointer { data in
                        if whisper_full(context, params, data.baseAddress, Int32(data.count)) != 0 {
                        } else {
                            whisper_print_timings(context)
                        }
                    }
                }

                let baseStartMSec = recognizingSpeech.transcriptionLines.last?.endMSec ?? 0
                let baseOrdering = recognizingSpeech.transcriptionLines.last?.ordering != nil
                    ? recognizingSpeech.transcriptionLines.last!.ordering + 1
                    : 0
                let nSegments = whisper_full_n_segments(context)
                var lastEndMSec: Int64 = 0
                for i in 0 ..< nSegments {
                    let text = String(cString: whisper_full_get_segment_text(context, i))
                    let startMSec = whisper_full_get_segment_t0(context, i) * 10 + baseStartMSec
                    let endMSec = whisper_full_get_segment_t1(context, i) * 10 + baseStartMSec
                    lastEndMSec = whisper_full_get_segment_t1(context, i) * 10
                    let transcriptionLine = TranscriptionLine(
                        startMSec: startMSec,
                        endMSec: endMSec,
                        text: text,
                        ordering: baseOrdering + i
                    )
                    recognizingSpeech.transcriptionLines.append(transcriptionLine)
                }
                // update promptTokens
                if isPromptingActive {
                    let oldPromptTokens = recognizingSpeech.promptTokens
                    var newPromptTokens: [Int32] = []
                    recognizingSpeech.promptTokens.removeAll()
                    for i in 0 ..< nSegments {
                        let tokenCount = whisper_full_n_tokens(context, i)
                        for j in 0 ..< tokenCount {
                            let tokenId = whisper_full_get_token_id(context, i, j)
                            newPromptTokens.append(tokenId)
                        }
                    }
                    // reset promptTokens if new and old promptTokens are the same
                    if newPromptTokens == oldPromptTokens {
                        recognizingSpeech.promptTokens = []
                    } else {
                        recognizingSpeech.promptTokens = newPromptTokens
                    }
                }
                // update remaining audioData
                if isRemainingAudioConcatActive {
                    let audioDataCount: Int = audioData.count
                    let usedAudioDataCount = Int(Float(lastEndMSec) / Float(1000) * self.samplingRate)
                    let remainingAudioDataCount: Int = audioDataCount - usedAudioDataCount
                    if remainingAudioDataCount > 0 {
                        recognizingSpeech.remainingAudioData = Array(audioData[usedAudioDataCount ..< audioDataCount])
                    } else {
                        recognizingSpeech.remainingAudioData = []
                    }
                }
                callback(recognizingSpeech)
            }
        }
    }
}
