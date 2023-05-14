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
            recognizingSpeech.tmpAudioData += originalAudioData

            // append remaining previous audioData to originalAudioData
            var audioData = recognizingSpeech.remainingAudioData + originalAudioData
            let audioDataMSec = Int64(audioData.count / 16000 * 1000)
            do {
                try FileManager.default.removeItem(at: audioFileURL)
            } catch {
                Logger.warning("failed to remove audio file")
            }
            let baseStartMSec = recognizingSpeech.transcriptionLines.last?.endMSec ?? 0
            let baseOrdering = Int32(recognizingSpeech.transcriptionLines.count)
            let recognizingSpeechPointer = UnsafeMutablePointer<RecognizedSpeech>.allocate(capacity: 1)
            recognizingSpeechPointer.pointee = recognizingSpeech
            var newSegmentCallbackData = NewSegmentCallbackData(
                recognizingSpeech: recognizingSpeech,
                audioDataMSec: audioDataMSec,
                baseStartMSec: baseStartMSec,
                baseOrdering: baseOrdering
            )
            let newSegmentCallbackDataPointer = withUnsafeMutablePointer(to: &newSegmentCallbackData) { pointer in
                return pointer
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
                    // suppress hallucination for english
                    params.suppress_non_speech_tokens = language == Language.en ? false : false
                    params.prompt_tokens = UnsafePointer(recognizingSpeech.promptTokens)
                    params.prompt_n_tokens = Int32(recognizingSpeech.promptTokens.count)
                    params.new_segment_callback = newSegmentCallback
                    params.new_segment_callback_user_data = UnsafeMutableRawPointer(newSegmentCallbackDataPointer)
                    
                    whisper_reset_timings(context)
                    audioData.withUnsafeBufferPointer { data in
                        if whisper_full(context, params, data.baseAddress, Int32(data.count)) != 0 {
                        } else {
                            whisper_print_timings(context)
                        }
                    }
                }

                // When some transcription line was suppressed because of repetition, we need to modify last endmsec
                recognizingSpeech.transcriptionLines.last?.endMSec = baseStartMSec + newSegmentCallbackData.transcribedMSec
                // update promptTokens
                if isPromptingActive {
                    recognizingSpeech.promptTokens.removeAll()
                    recognizingSpeech.promptTokens = newSegmentCallbackData.nextPromptTokens
                }
                // update remaining audioData
                if isRemainingAudioConcatActive {
                    let audioDataCount: Int = audioData.count
                    let usedAudioDataCount = Int(Float(newSegmentCallbackData.transcribedMSec) / Float(1000) * self.samplingRate)
                    let remainingAudioDataCount: Int = audioDataCount - usedAudioDataCount
                    if remainingAudioDataCount > 0 {
                        recognizingSpeech.remainingAudioData = Array(audioData[usedAudioDataCount ..< audioDataCount])
                    } else {
                        recognizingSpeech.remainingAudioData = []
                    }
                }
                // when recognizedSpeech deleted during recognizing, this may cause error
                // to avoid it, do feasibility check before saving audio data and update RecognizedSpeech coredata
                if feasibilityCheck(recognizingSpeech) {
                    do {
                        try saveAudioData(
                            audioFileURL: recognizingSpeech.audioFileURL,
                            audioData: recognizingSpeech.tmpAudioData
                        )
                    } catch {
                        fatalError("failed to save audio data")
                    }
                    // if error cause here, try DispatchQueue.main.async
                    CoreDataRepository.addTranscriptionLinesToRecognizedSpeech(
                        recognizedSpeech: recognizingSpeech,
                        transcriptionLines: newSegmentCallbackData.newTranscriptionLines
                    )
                }
                callback(recognizingSpeech)
            }
        }
    }
}

class NewSegmentCallbackData {
    var recognizingSpeech: RecognizedSpeech
    var newTranscriptionLines: [TranscriptionLine]
    let audioDataMSec: Int64
    let baseStartMSec: Int64
    let baseOrdering: Int32
    var transcribedMSec: Int64
    var nextPromptTokens: [Int32]

    init(
        recognizingSpeech: RecognizedSpeech,
        audioDataMSec: Int64,
        baseStartMSec: Int64,
        baseOrdering: Int32
    ) {
        self.recognizingSpeech = recognizingSpeech
        self.newTranscriptionLines = []
        self.audioDataMSec = audioDataMSec
        self.baseStartMSec = baseStartMSec
        self.baseOrdering = baseOrdering
        self.transcribedMSec = 0
        self.nextPromptTokens = []
    }
}

func newSegmentCallback(
    ctx: OpaquePointer?,
    sate: OpaquePointer?,
    nNew: Int32,
    userData: UnsafeMutableRawPointer?
) {
    guard let context = ctx else {
        Logger.error("context is nil on new segment callback.")
        return
    }
    guard let userData = userData else {
        Logger.error("userData is nil on new segment callback.")
        return
    }
    // bind unsafe pointer to NewSegmentCallbackData
    var newSegmentCallbackData = userData.bindMemory(to: NewSegmentCallbackData.self, capacity: 1).pointee
    let recognizingSpeech = newSegmentCallbackData.recognizingSpeech
    let baseStartMSec = newSegmentCallbackData.baseStartMSec
    let baseOrdering = newSegmentCallbackData.baseOrdering // 0-indexed
    let previousSegmentText = newSegmentCallbackData.newTranscriptionLines.last?.text ?? ""

    let nSegments = whisper_full_n_segments(context)

    // whisper sometimes exceeds audioDataMSec, so we need to check it
    let newSegmentStartMSec = min(whisper_full_get_segment_t0(context, nSegments - 1) * 10 + baseStartMSec, newSegmentCallbackData.audioDataMSec + baseStartMSec)
    let newSegmentEndMSec = min(whisper_full_get_segment_t1(context, nSegments - 1) * 10 + baseStartMSec, newSegmentCallbackData.audioDataMSec + baseStartMSec)
    let newSegmentOrdering = baseOrdering + Int32(nSegments) - 1
    let newSegmentText = String(cString: whisper_full_get_segment_text(context, nSegments - 1))
    newSegmentCallbackData.transcribedMSec = min(whisper_full_get_segment_t1(context, nSegments - 1) * 10, newSegmentCallbackData.audioDataMSec)
    // suppress repetition
    if newSegmentText != previousSegmentText {
        // add new tokens to next prompt tokens
        let tokenCount = whisper_full_n_tokens(context, nSegments - 1)
        for j in 0 ..< tokenCount {
            let tokenId = whisper_full_get_token_id(context, nSegments - 1, j)
            newSegmentCallbackData.nextPromptTokens.append(tokenId)
        }
        // add new segment to recognizing speech
        let newTranscriptionLine = TranscriptionLine(
            startMSec: newSegmentStartMSec,
            endMSec: newSegmentEndMSec,
            text: newSegmentText,
            ordering: newSegmentOrdering
        )
        recognizingSpeech.transcriptionLines.append(
            newTranscriptionLine
        )
        // add new transcription line to new transcription lines to save it to coredata
        newSegmentCallbackData.newTranscriptionLines.append(
            newTranscriptionLine
        )
    }
}
