import AVFoundation
import Dispatch
import Foundation

class WhisperRecognizer: Recognizer {
    private var whisperContext: OpaquePointer?
    @Published var whisperModel: WhisperModel?
    let serialDispatchQueue = DispatchQueue(label: "recognize")
    var is_ready: Bool {
        whisperContext != nil
    }

    init(whisperModel: WhisperModel) {
        do {
            try load_model(whisperModelURL: whisperModel.localPath!)
            self.whisperModel = whisperModel
        } catch {
            self.whisperModel = WhisperModel(size: Size(rawValue: "tiny")!, language: Lang(rawValue: "en")!, needsSubscription: false, callBack: { _ in })
            return
        }

    }

    deinit {
        if whisperContext != nil {
            whisper_free(whisperContext)
        }
    }

    func load_model(whisperModelURL: URL) throws {
        whisperContext = whisper_init(whisperModelURL.path())
        if whisperContext == nil {
            throw NSError(domain: "model load error", code: -1)
        }
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
        guard let whisperContext: OpaquePointer else {
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
        callback: @escaping (RecognizedSpeech) -> Void,
        feasibilityCheck: @escaping (RecognizedSpeech) -> Bool
    ) {
        serialDispatchQueue.async {
            guard let whisperContext = self.whisperContext else {
                Logger.error("model load error")
                return
            }
            guard let audioData = try? self.load_audio(url: audioFileURL) else {
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

                    whisper_reset_timings(whisperContext)
                    audioData.withUnsafeBufferPointer { data in
                        if whisper_full(whisperContext, params, data.baseAddress, Int32(data.count)) != 0 {
                        } else {
                            whisper_print_timings(whisperContext)
                        }
                    }
                }

                let baseStartMSec = recognizingSpeech.transcriptionLines.last?.endMSec ?? 0
                let baseOrdering = recognizingSpeech.transcriptionLines.last?.ordering != nil ? recognizingSpeech.transcriptionLines.last!.ordering + 1 : 0
                let n_segments = whisper_full_n_segments(whisperContext)
                for i in 0 ..< n_segments {
                    let text = String(cString: whisper_full_get_segment_text(whisperContext, i))
                    let startMSec = whisper_full_get_segment_t0(whisperContext, i) * 10 + baseStartMSec
                    let endMSec = whisper_full_get_segment_t1(whisperContext, i) * 10 + baseStartMSec
                    let transcriptionLine = TranscriptionLine(startMSec: startMSec, endMSec: endMSec, text: text, ordering: baseOrdering + i)
                    recognizingSpeech.transcriptionLines.append(transcriptionLine)
                }
                recognizingSpeech.tmpAudioDataList.append(audioData)
                callback(recognizingSpeech)
            }
        }
    }
}
