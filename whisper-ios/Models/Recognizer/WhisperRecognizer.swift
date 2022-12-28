import Foundation
import AVFoundation

class WhisperRecognizer: Recognizer{
    private var whisperContext: OpaquePointer? = nil
    var is_ready: Bool {
        get{
            return whisperContext != nil
        }
    }
    init(modelName: String) {
        do {
            try load_model(modelName: modelName)
        } catch {
            return
        }
    }
    deinit {
        if whisperContext != nil {
            whisper_free(whisperContext)
        }
    }
    private func load_model(modelName: String) throws {
        guard let url: URL = Bundle.main.url(forResource: modelName, withExtension: "bin") else {
            throw NSError(domain: "model load error", code: -1)
        }
        whisperContext = whisper_init(url.path())
        if whisperContext == nil {
            throw NSError(domain: "model load error", code: -1)
        }
    }
    private func load_audio(url: URL) throws -> Array<Float32> {
        guard let audio = try? AVAudioFile(forReading: url, commonFormat: .pcmFormatFloat32, interleaved: false) else{
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
    
    func recognize(audioFileURL: URL, language: Language) throws -> RecognizedSpeech{
        if whisperContext != nil {
            guard let audioData = try? load_audio(url: audioFileURL) else{
                throw NSError(domain: "audio load error", code: -1)
            }
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
                    if (whisper_full(whisperContext, params, data.baseAddress, Int32(data.count)) != 0) {
                    } else {
                        whisper_print_timings(whisperContext)
                    }
                }
            }
            var transcription = ""
            let n_segments = whisper_full_n_segments(whisperContext)
            var transcriptionLines: [TranscriptionLine] = []
            for i in 0..<n_segments {
                let text = String.init(cString: whisper_full_get_segment_text(whisperContext, i))
                let startMSec = whisper_full_get_segment_t0(whisperContext, i) * 10
                let endMSec = whisper_full_get_segment_t1(whisperContext, i) * 10
                let transcriptionLine = TranscriptionLine(startMSec: startMSec, endMSec: endMSec, text: text, ordering: i)
                transcriptionLines.append(transcriptionLine)
                transcription += text
            }
            let recognizedSpeech = RecognizedSpeech(audioFileURL: audioFileURL, language: language, transcriptionLines: transcriptionLines)
            
            return recognizedSpeech
        } else {
            throw NSError(domain: "model load error", code: -1)
        }
    }
}
