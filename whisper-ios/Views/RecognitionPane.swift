import AVFoundation
import DequeModule
import SwiftUI

let UserDefaultASRLanguageKey = "asr-language"

struct RecognitionPane: View {
    // MARK: - Recording state

    @State var audioRecorder: AVAudioRecorder?
    @State var tmpAudioFileNumber: Int = 0
    @State var isRecording: Bool = false
    @State var isPaused: Bool = false

    @State var elapsedTime: Int = 0
    @State var idAmps: Deque<IdAmp> = []
    @State var maxAmp: Float = 0

    @State var updateRecordingTimeTimer: Timer?
    @State var updateWaveformTimer: Timer?
    @State var streamingRecognitionTimer: Timer?
    @State var recognizedResultsScrollTimer: Timer?

    let recordSettings = [
        AVFormatIDKey: Int(kAudioFormatLinearPCM),
        AVSampleRateKey: 16000,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
    ]

    // MARK: - ASR state

    @EnvironmentObject var recognizer: WhisperRecognizer
    @Binding var recognizingSpeechIds: [UUID]
    @Binding var recognizedSpeeches: [RecognizedSpeech]
    @State var recognizingSpeech: RecognizedSpeech?
    @Binding var isRecordDetailActives: [Bool]
    @State var language: Language = getUserLanguage()
    @State var title = ""

    @AppStorage(UserDefaultRecognitionFrequencySecKey) var recognitionFrequencySec = 15
    @AppStorage(PromptingActiveKey) var isPromptingActive = true
    @AppStorage(RemainingAudioConcatActiveKey) var isRemainingAudioConcatActive = true

    // MARK: - pane management state

    @State var isPaneOpen: Bool = false
    @State var isConfirmOpen: Bool = false
    @State var isCancelRecognitionAlertOpen = false

    // MARK: - background related state

    @Environment(\.scenePhase) var scenePhase
    @State var isBackground = false

    var body: some View {
        RecordingController(
            isRecording: $isRecording,
            isPaused: $isPaused,
            isPaneOpen: $isPaneOpen,
            startAction: (isRecording && isPaused) ? resumeRecording : startRecording,
            stopAction: pauseRecording,
            elapsedTime: elapsedTime,
            idAmps: $idAmps,
            maxAmp: $maxAmp
        )

        // The Views used inside RecordingController changes when recording starts,
        // so if a sheet is defined for RecordingController,
        // the animation of the sheet rising on top of the view is lost.
        // To prevent this, provide an unchanged view with height 0 at the start of recording
        // and define the sheet for it, so that the animation is performed correctly.
        Rectangle()
            .onReceive(
                NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification),
                perform: recordingInterruptionHandler
            )
            .frame(height: 0)
            .hidden()
            .sheet(isPresented: $isPaneOpen) { recordingSheet }
            .onChange(of: scenePhase) {
                newPhase in
                if newPhase == .background, isRecording, !isPaused {
                    streamingRecognitionTimer?.invalidate()
                    // to distinguish background or inactive (e.g. Control Panel)
                    isBackground = true
                } else if newPhase == .active, isRecording, !isPaused, isBackground {
                    streamingRecognitionTimer = Timer.scheduledTimer(
                        withTimeInterval: Double(recognitionFrequencySec),
                        repeats: true
                    ) { _ in
                        streamingRecognitionTimerFunc()
                    }
                    RunLoop.main.add(streamingRecognitionTimer!, forMode: .common)
                    isBackground = false
                }
            }
    }

    var recordingSheet: some View {
        NavigationView {
            VStack {
                HStack { closeButton; Spacer() }

                HStack(spacing: 10) {
                    if isPaused {
                        Image(systemName: "pause.fill")
                            .foregroundColor(.gray)
                    } else {
                        Circle()
                            .fill(.red)
                            .frame(width: 10, height: 10)
                            .blinkEffect()
                    }
                    Text(formatTime(Double(elapsedTime)))
                }

                Waveform(
                    idAmps: $idAmps,
                    isPaused: $isPaused,
                    maxAmp: $maxAmp,
                    removeIdAmps: true
                )
                .frame(height: 250)

                if recognizingSpeech != nil, recognizingSpeech!.transcriptionLines.count > 0 {
                    Group {
                        Divider()
                        transcriptionLinesView
                    }
                } else {
                    Spacer()
                }
                NavigationLink(
                    destination: ConfirmPane(
                        finishRecording: finishRecording,
                        abortRecording: abortRecording,
                        language: $language,
                        title: $title
                    ),
                    isActive: $isConfirmOpen
                ) {}.hidden()
                HStack(spacing: 50) {
                    StopButtonPane {
                        pauseRecording()
                        language = getUserLanguage()
                        isConfirmOpen = true
                    }
                    RecordButtonPane(
                        isRecording: $isRecording,
                        isPaused: $isPaused,
                        startAction: resumeRecording,
                        stopAction: pauseRecording
                    )
                }
                .padding(.bottom, 30)
            }.navigationBarHidden(true)
        }
    }

    var closeButton: some View {
        Button(action: { isCancelRecognitionAlertOpen = true }) {
            Image(systemName: "xmark")
                .resizable()
                .frame(width: 15, height: 15)
                .foregroundColor(.gray)
        }
        .padding(35)
        .alert(isPresented: $isCancelRecognitionAlertOpen) {
            Alert(
                title: Text("録音を終了しますか？"),
                message: Text("録音された音声は破棄されます。本当に終了しますか？"),
                primaryButton: .destructive(Text("終了"), action: abortRecording),
                secondaryButton: .cancel()
            )
        }
    }

    var transcriptionLinesView: some View {
        ScrollViewReader { scrollReader in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(recognizingSpeech!.transcriptionLines.enumerated()), id: \.self.offset) {
                        idx, onGoingTranscriptionLine in
                        HStack(alignment: .center) {
                            Text(formatTime(Double(onGoingTranscriptionLine.startMSec) / 1000))
                                .frame(width: 50, alignment: .center)
                                .foregroundColor(Color.blue)
                                .padding()
                            Spacer()
                            Text(onGoingTranscriptionLine.text)
                                .foregroundColor(Color(.label))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(10)
                        .background(getTextColor(lines: &recognizingSpeech!.transcriptionLines, idx))
                        Divider()
                    }
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
            .padding()
            .onAppear {
                // TODO: 毎秒スクロールを試行するのは負荷が大きいため、認識ごとにスクロールするようにしたい
                recognizedResultsScrollTimer = Timer.scheduledTimer(
                    withTimeInterval: 1,
                    repeats: true
                ) { _ in
                    withAnimation {
                        scrollReader.scrollTo(recognizingSpeech!.transcriptionLines.count - 1, anchor: .bottom)
                    }
                }
                RunLoop.main.add(recognizedResultsScrollTimer!, forMode: .common)
            }
        }
    }

    // MARK: - functions about recording

    /// start recording
    func startRecording() {
        isRecording = true
        isPaused = false
        isPaneOpen = true

        language = getUserLanguage()
        tmpAudioFileNumber = 0
        maxAmp = 0
        recognizingSpeech = RecognizedSpeech(
            audioFileURL: getTmpURLByNumber(number: tmpAudioFileNumber),
            language: language
        )
        recognizingSpeechIds.insert(recognizingSpeech!.id, at: 0)

        elapsedTime = 0
        idAmps = []
        title = ""

        audioRecorder = try! AVAudioRecorder(
            url: getTmpURLByNumber(number: tmpAudioFileNumber),
            settings: recordSettings
        )
        audioRecorder!.isMeteringEnabled = true
        audioRecorder!.record()

        resetTimers()
    }

    func resumeRecording() {
        isRecording = true
        isPaused = false

        audioRecorder!.record()
        resetTimers()
    }

    func pauseRecording() {
        isPaused = true
        audioRecorder!.pause()

        updateRecordingTimeTimer?.invalidate()
        updateWaveformTimer?.invalidate()
        streamingRecognitionTimer?.invalidate()
    }

    /// discard all information about recording and close the pane
    ///
    /// reset timers for updating recording time and waveform.
    /// stop recording and reset recording time and waveform.
    /// this function also close recognition pane.
    /// this function does not reset information about `RecognizedSpeech` like title.
    func finishRecording() {
        audioRecorder!.stop()

        updateRecordingTimeTimer?.invalidate()
        updateWaveformTimer?.invalidate()
        streamingRecognitionTimer?.invalidate()
        recognizedResultsScrollTimer?.invalidate()

        isRecording = false
        isPaused = false
        isPaneOpen = false
        isConfirmOpen = false

        guard let recognizingSpeech else {
            Logger.error("recognizingSpeech is nil")
            return
        }
        // execute last streaming ASR、and create RecognizedSpeech model
        let url = getTmpURLByNumber(number: tmpAudioFileNumber)
        // change title based on the confirm pane
        if title != "" {
            recognizingSpeech.title = title
        }
        recognizer.streamingRecognize(
            audioFileURL: url,
            language: language,
            recognizingSpeech: recognizingSpeech,
            isPromptingActive: isPromptingActive,
            isRemainingAudioConcatActive: isRemainingAudioConcatActive,
            callback: streamingRecognitionPostProcess,
            feasibilityCheck: streamingRecognitionFeasibilityCheck
        )
        recognizedSpeeches.insert(recognizingSpeech, at: 0)
        isRecordDetailActives.insert(true, at: 0)
    }

    func abortRecording() {
        audioRecorder!.stop()

        updateRecordingTimeTimer?.invalidate()
        updateWaveformTimer?.invalidate()
        streamingRecognitionTimer?.invalidate()
        recognizedResultsScrollTimer?.invalidate()

        isRecording = false
        isPaneOpen = false
        isConfirmOpen = false

        recognizingSpeechIds.removeAll(where: { $0 == recognizingSpeech!.id })
    }

    func recordingInterruptionHandler(notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else {
            return
        }
        if type == .began, isRecording {
            pauseRecording()
        } else if type == .ended, isRecording, isPaused {
            resumeRecording()
        }
    }

    // MARK: - function about ASR

    /// recognition function called in a timer
    func streamingRecognitionTimerFunc() {
        audioRecorder!.stop()
        let url = getTmpURLByNumber(number: tmpAudioFileNumber)

        // resume recording as soon as possible
        tmpAudioFileNumber = tmpAudioFileNumber + 1
        let newURL = getTmpURLByNumber(number: tmpAudioFileNumber)
        audioRecorder = try! AVAudioRecorder(url: newURL, settings: recordSettings)
        audioRecorder!.isMeteringEnabled = true
        audioRecorder!.record()

        guard let recognizingSpeech else {
            Logger.error("recognizingSpeech is nil.")
            return
        }
        // recognize past 10 ~ 30 sec speech
        recognizer.streamingRecognize(
            audioFileURL: url,
            language: language,
            recognizingSpeech: recognizingSpeech,
            isPromptingActive: isPromptingActive,
            isRemainingAudioConcatActive: isRemainingAudioConcatActive,
            callback: { _ in },
            feasibilityCheck: streamingRecognitionFeasibilityCheck
        )
    }

    /// check whether ASR has to be executed or not
    /// this func is called in streaming recognizer
    func streamingRecognitionFeasibilityCheck(recognizedSpeech: RecognizedSpeech) -> Bool {
        recognizingSpeechIds.contains(recognizedSpeech.id)
    }

    /// post process (e.g. audio concatenation)
    /// this func is called in streaming recognizer
    func streamingRecognitionPostProcess(recognizedSpeech: RecognizedSpeech) {
        var audioData: [Float32] = []
        let tmpAudioDataList = recognizedSpeech.tmpAudioDataList
        for tmpAudioData in tmpAudioDataList {
            audioData = audioData + tmpAudioData
        }
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        ) else {
            Logger.error("format load error")
            return
        }
        guard let pcmBuffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(audioData.count)
        ) else {
            Logger.error("audio load error")
            return
        }
        for i in 0 ..< audioData.count {
            pcmBuffer.floatChannelData!.pointee[i] = Float(audioData[i])
        }
        pcmBuffer.frameLength = AVAudioFrameCount(audioData.count)
        let newURL = getURLByName(fileName: "\(recognizedSpeech.id.uuidString).m4a")
        guard let audioFile = try? AVAudioFile(forWriting: newURL, settings: recordSettings) else {
            Logger.error("audio load error")
            return
        }
        guard let _ = try? audioFile.write(from: pcmBuffer) else {
            Logger.error("audio write error")
            return
        }
        recognizedSpeech.audioFileURL = newURL

        CoreDataRepository.saveRecognizedSpeech(recognizedSpeech)

        recognizingSpeechIds.removeAll(where: { $0 == recognizedSpeech.id })
    }

    // MARK: - general function

    func resetTimers() {
        updateRecordingTimeTimer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true
        ) { _ in
            self.elapsedTime += 1
        }

        updateWaveformTimer = Timer.scheduledTimer(
            withTimeInterval: 0.1,
            repeats: true
        ) { _ in
            audioRecorder!.updateMeters()

            let idAmp = IdAmp(
                id: UUID(),
                amp: audioRecorder!.averagePower(forChannel: 0)
            )
            if idAmp.amp > maxAmp { maxAmp = idAmp.amp }
            idAmps.append(idAmp)
        }

        streamingRecognitionTimer = Timer.scheduledTimer(
            withTimeInterval: Double(recognitionFrequencySec),
            repeats: true
        ) { _ in
            streamingRecognitionTimerFunc()
        }

        RunLoop.main.add(updateRecordingTimeTimer!, forMode: .common)
        RunLoop.main.add(updateWaveformTimer!, forMode: .common)
        RunLoop.main.add(streamingRecognitionTimer!, forMode: .common)
    }

    func getTextColor(lines: inout [TranscriptionLine], _ idx: Int) -> Color {
        let startMSec = Double(lines[idx].startMSec)
        let endMSec: Double = idx < lines.count - 1 ? Double(lines[idx + 1].startMSec) : .infinity
        let currentMSec = Double(elapsedTime * 1000)
        let isInside = startMSec <= currentMSec && currentMSec < endMSec
        let uiColor: UIColor = isInside ? .systemGray5 : .systemBackground
        return Color(uiColor)
    }
}

private func renameAudioFileURL(recognizedSpeech: RecognizedSpeech) {
    let tmpURL = getTmpURL()
    let newURL = getAudioFileURL(id: recognizedSpeech.id)

    recognizedSpeech.audioFileURL = newURL
    do {
        try FileManager.default.moveItem(at: tmpURL, to: newURL)
    } catch {
        Logger.error("Failed to move file:", error)
    }
}

/// get temporary url to save audio file
///
/// When starting recording, the id of RecognizedSpeech is not determined yet.
/// Thus recorded audio is firstly saved to a temporary file and it is renamed after.
func getTmpURL() -> URL {
    getURLByName(fileName: "tmp.m4a")
}

func getTmpURLByNumber(number: Int) -> URL {
    getURLByName(fileName: "tmp\(number).m4a")
}

func getAudioFileURL(id: UUID) -> URL {
    getURLByName(fileName: "\(id.uuidString).m4a")
}

func getURLByName(fileName: String) -> URL {
    let paths = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
    )
    let docsDirect = paths[0]
    let url = docsDirect.appendingPathComponent(fileName)
    return url
}

func getUserLanguage() -> Language {
    if let language = UserDefaults.standard.string(forKey: UserDefaultASRLanguageKey) {
        return Language(rawValue: language)!
    }

    // default language
    return .en
}

struct RecognitionPane_Previews: PreviewProvider {
    static var previews: some View {
        let mock = getRecognizedSpeechMock(
            audioFileName: "sample_ja",
            csvFileName: "sample_ja"
        )
        RecognitionPane(
            recognizingSpeechIds: .constant([]),
            recognizedSpeeches: .constant([mock!]),
            isRecordDetailActives: .constant([])
        )
    }
}
