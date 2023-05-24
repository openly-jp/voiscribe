import AVFoundation
import Dispatch
import Foundation
import SwiftUI

var numRecognitionTasks = 0

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
                numRecognitionTasks -= 1
            }
            let identifier = UIApplication.shared.beginBackgroundTask(expirationHandler: {
                Logger.warning("background task expired")
            })

            numRecognitionTasks += 1
            // prohibit user from changing model
            self.isRecognizing = true

            guard let context = self.whisperModel.whisperContext else {
                Logger.error("model load error")
                return
            }
            guard let originalAudioData = try? self.load_audio(url: audioFileURL) else {
                Logger.error("audio load error")
                return
            }
            recognizingSpeech.tmpAudioData += originalAudioData

            // append remaining previous audioData to originalAudioData
            let audioData = recognizingSpeech.remainingAudioData + originalAudioData
            let audioDataMSec = Int64(audioData.count / 16000 * 1000)
            do {
                try FileManager.default.removeItem(at: audioFileURL)
            } catch {
                Logger.warning("failed to remove audio file")
            }
            let baseStartMSec = recognizingSpeech.transcriptionLines.last?.endMSec ?? 0
            let baseOrdering = Int32(recognizingSpeech.transcriptionLines.count)
            var newSegmentCallbackData = NewSegmentCallbackData(
                recognizingSpeech: recognizingSpeech,
                newTranscriptionLines: [],
                audioDataMSec: audioDataMSec,
                baseStartMSec: baseStartMSec,
                baseOrdering: baseOrdering,
                transcribedMSec: 0,
                nextPromptTokens: []
            )
            // check whether recognizingSpeech was removed (i.e. abort recording) or not
            if feasibilityCheck(recognizingSpeech) {
                let maxThreads = max(1, min(8, ProcessInfo.processInfo.processorCount - 2))
                var params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)
                withUnsafeMutablePointer(to: &newSegmentCallbackData) {
                    newSegmentCallbackDataPtr in

                    let languageNSString = language.rawValue as NSString
                    guard let languageCString = languageNSString.utf8String else {
                        Logger.error("failed to convert language to cString")
                        return
                    }

                    params.print_realtime = true
                    params.print_progress = false
                    params.print_timestamps = true
                    params.print_special = false
                    params.translate = false
                    params.language = languageCString
                    params.n_threads = Int32(maxThreads)
                    params.offset_ms = 0
                    params.no_context = true
                    params.single_segment = false
                    params.suppress_non_speech_tokens = false
                    params.prompt_tokens = UnsafePointer(recognizingSpeech.promptTokens)
                    params.prompt_n_tokens = Int32(recognizingSpeech.promptTokens.count)
                    params.new_segment_callback = newSegmentCallback
                    params.new_segment_callback_user_data = UnsafeMutableRawPointer(newSegmentCallbackDataPtr)

                    whisper_reset_timings(context)
                    audioData.withUnsafeBufferPointer { audioDataBufferPtr in
                        if whisper_full(
                            context,
                            params,
                            audioDataBufferPtr.baseAddress,
                            Int32(audioDataBufferPtr.count)
                        ) != 0 {
                        } else {
                            whisper_print_timings(context)
                        }
                    }
                }

                // The following code will be executed after all "new_segment_callback" have been processed

                // When some transcription line was suppressed because of repetition, we need to modify last endmsec
                recognizingSpeech.transcriptionLines.last?.endMSec = baseStartMSec + newSegmentCallbackData
                    .transcribedMSec
                // update promptTokens
                if isPromptingActive {
                    recognizingSpeech.promptTokens.removeAll()
                    recognizingSpeech.promptTokens = newSegmentCallbackData.nextPromptTokens
                }
                // update remaining audioData
                if isRemainingAudioConcatActive {
                    let audioDataCount: Int = audioData.count
                    let usedAudioDataCount = Int(Float(newSegmentCallbackData.transcribedMSec) / Float(1000) * self
                        .samplingRate)
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
            UIApplication.shared.endBackgroundTask(identifier)
        }
    }
}

struct NewSegmentCallbackData {
    var recognizingSpeech: RecognizedSpeech
    var newTranscriptionLines: [TranscriptionLine]
    let audioDataMSec: Int64
    let baseStartMSec: Int64
    let baseOrdering: Int32
    var transcribedMSec: Int64
    var nextPromptTokens: [Int32]
}

func newSegmentCallback(
    ctx: OpaquePointer?,
    state _: OpaquePointer?,
    nNew _: Int32,
    userData: UnsafeMutableRawPointer?
) {
    guard let context = ctx else {
        Logger.error("context is nil on new segment callback.")
        return
    }
    guard let userData else {
        Logger.error("userData is nil on new segment callback.")
        return
    }
    let newSegmentCallbackDataPtr = userData.bindMemory(to: NewSegmentCallbackData.self, capacity: 1)
    let baseStartMSec = newSegmentCallbackDataPtr.pointee.baseStartMSec
    let baseOrdering = newSegmentCallbackDataPtr.pointee.baseOrdering // 0-indexed
    let previousSegmentText = newSegmentCallbackDataPtr.pointee.newTranscriptionLines.last?.text ?? ""

    let nSegments = whisper_full_n_segments(context)

    // whisper sometimes exceeds audioDataMSec, so we need to check it
    let newSegmentStartMSec = min(
        whisper_full_get_segment_t0(context, nSegments - 1) * 10 + baseStartMSec,
        newSegmentCallbackDataPtr.pointee.audioDataMSec + baseStartMSec
    )
    let newSegmentEndMSec = min(
        whisper_full_get_segment_t1(context, nSegments - 1) * 10 + baseStartMSec,
        newSegmentCallbackDataPtr.pointee.audioDataMSec + baseStartMSec
    )
    let newSegmentOrdering = baseOrdering + Int32(nSegments) - 1
    let newSegmentText = String(cString: whisper_full_get_segment_text(context, nSegments - 1))
    newSegmentCallbackDataPtr.pointee.transcribedMSec = min(
        whisper_full_get_segment_t1(context, nSegments - 1) * 10,
        newSegmentCallbackDataPtr.pointee.audioDataMSec
    )
    // suppress repetition
    if newSegmentText != previousSegmentText {
        // add new tokens to next prompt tokens
        let tokenCount = whisper_full_n_tokens(context, nSegments - 1)
        for j in 0 ..< tokenCount {
            let tokenId = whisper_full_get_token_id(context, nSegments - 1, j)
            newSegmentCallbackDataPtr.pointee.nextPromptTokens.append(tokenId)
        }
        // add new segment to recognizing speech
        let newTranscriptionLine = TranscriptionLine(
            startMSec: newSegmentStartMSec,
            endMSec: newSegmentEndMSec,
            text: newSegmentText,
            ordering: newSegmentOrdering
        )
        newSegmentCallbackDataPtr.pointee.recognizingSpeech.transcriptionLines.append(
            newTranscriptionLine
        )
        // add new transcription line to new transcription lines to save it to coredata
        newSegmentCallbackDataPtr.pointee.newTranscriptionLines.append(
            newTranscriptionLine
        )
    }
}

func sendBackgroundAlertNotification() {
    let BACKGROUND_ALERT_NOTIFICATION_IDENTIFIER = "background-alert-notification"
    let BACKGROUND_ALERT_NOTIFICATION_TITLE = "VoiScribe"
    let BACKGROUND_ALERT_NOTIFICATION_BODY = NSLocalizedString("30s以上バックグラウンド状態の場合、アプリの動作が停止します。", comment: "")

    let backgroundAlertNotificationContent = UNMutableNotificationContent()
    backgroundAlertNotificationContent.title = BACKGROUND_ALERT_NOTIFICATION_TITLE
    backgroundAlertNotificationContent.body = BACKGROUND_ALERT_NOTIFICATION_BODY

    let backgroundAlertNotificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    let backgroundAlertNotificationRequest = UNNotificationRequest(
        identifier: BACKGROUND_ALERT_NOTIFICATION_IDENTIFIER,
        content: backgroundAlertNotificationContent,
        trigger: backgroundAlertNotificationTrigger
    )
    UNUserNotificationCenter.current().add(backgroundAlertNotificationRequest)
}
