import AVFoundation
import DequeModule
import SwiftUI

let UserDefaultASRLanguageKey = "asr-language"

struct RecognitionPane: View {
    // MARK: - Recording state

    @State var audioRecorder: AVAudioRecorder?
    @State var audioFileNumber: Int = 0
    @State var isRecording: Bool = false
    @State var isPaused: Bool = false

    @State var elapsedTime: Int = 0
    @State var idAmps: Deque<IdAmp> = []

    @State var updateRecordingTimeTimer: Timer?
    @State var updateWaveformTimer: Timer?
    @State var streamingRecognitionTimer: Timer?
    @State var recognizedResultsScrollTimer: Timer?

    @State var tmpAudioDataList: [[Float32]] = []

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
    @Binding var isActives: [Bool]
    @State var language: Language = getUserLanguage()
    @State var title = ""
    @State var onGoingTranscriptionLines: [TranscriptionLine]?
    @State var onGoingTranscriptionLineStartOrdering: Int32 = 0
    @State var onGoingTranscriptionLineStartMSec: Int64 = 0
    @AppStorage(UserDefaultRecognitionFrequencySecKey) var recognitionFrequencySec = 15

    // MARK: - pane management state

    @State var isPaneOpen: Bool = false
    @State var isConfirmOpen: Bool = false
    @State var isCancelRecognitionAlertOpen = false

    init(
        recognizingSpeechIds: Binding<[UUID]>,
        recognizedSpeeches: Binding<[RecognizedSpeech]>,
        isActives: Binding<[Bool]>
    ) {
        let session = AVAudioSession.sharedInstance()
        try! session.setCategory(AVAudioSession.Category.playAndRecord)
        try! session.setActive(true)

        _recognizingSpeechIds = recognizingSpeechIds
        _recognizedSpeeches = recognizedSpeeches
        _isActives = isActives
    }

    // MARK: - functions about recording

    /// start recording
    func startRecording() {
        isRecording = true
        isPaused = false
        isPaneOpen = true

        elapsedTime = 0
        idAmps = []
        title = ""
        audioFileNumber = 0
        tmpAudioDataList = []
        audioRecorder = try! AVAudioRecorder(url: getTmpURLByNumber(number: audioFileNumber), settings: recordSettings)
        audioRecorder!.isMeteringEnabled = true
        audioRecorder!.record()

        onGoingTranscriptionLines = []
        onGoingTranscriptionLineStartOrdering = 0
        onGoingTranscriptionLineStartMSec = 0
        resetTimers()
    }

    func resumeRecording() {
        isRecording = true
        isPaused = false
        isPaneOpen = true
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
    /// reset timers for updateting recording time and waveform.
    /// stop recording and reset recording time and waveform.
    /// this funciton also close recognition pane.
    /// this function does not reset information about `RecognizedSpeech` like title.
    func finishRecording() {
        audioRecorder!.stop()

        updateRecordingTimeTimer?.invalidate()
        updateWaveformTimer?.invalidate()
        streamingRecognitionTimer?.invalidate()
        recognizedResultsScrollTimer?.invalidate()

        isRecording = false
        isPaneOpen = false
        isConfirmOpen = false

        /// execute last streaming ASR、and create RecognizedSpeech model
        let url = getTmpURLByNumber(number: audioFileNumber)
        let recognizingSpeech = RecognizedSpeech(audioFileURL: url, language: language, transcriptionLines: [])
        guard let tmpAudioData = try? recognizer.streamingRecognize(
            audioFileURL: url,
            language: language,
            callback: { tls in
                tls.forEach { transcriptionLine in
                    transcriptionLine.startMSec = onGoingTranscriptionLineStartMSec + transcriptionLine.startMSec
                    transcriptionLine.endMSec = onGoingTranscriptionLineStartMSec + transcriptionLine.endMSec
                    transcriptionLine.ordering = onGoingTranscriptionLineStartOrdering + transcriptionLine.ordering
                    onGoingTranscriptionLines?.append(transcriptionLine)
                }
                recognizingSpeech.transcriptionLines = onGoingTranscriptionLines ?? []

                var audioData: [Float32] = []
                for tmpAudioData in tmpAudioDataList {
                    audioData = audioData + tmpAudioData
                }
                if let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false) {
                    let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(audioData.count))
                    for i in 0 ..< audioData.count {
                        pcmBuffer?.floatChannelData!.pointee[i] = Float(audioData[i])
                    }
                    pcmBuffer?.frameLength = AVAudioFrameCount(audioData.count)
                    let new_url = getURLByName(fileName: "\(recognizingSpeech.id.uuidString).m4a")
                    let audioFile = try? AVAudioFile(forWriting: new_url, settings: recordSettings)
                    do {
                        try audioFile?.write(from: pcmBuffer!)
                        recognizingSpeech.audioFileURL = new_url
                        print(new_url)
                    } catch {
                        print("音声書き込みエラー")
                    }
                }
                CoreDataRepository.saveRecognizedSpeech(aRecognizedSpeech: recognizingSpeech)

                var removeIdx: Int?
                for idx in 0 ..< recognizingSpeechIds.count {
                    if recognizingSpeechIds[idx] == recognizingSpeech.id {
                        removeIdx = idx
                        break
                    }
                }
                if let removeIdx {
                    recognizingSpeechIds.remove(at: removeIdx)
                }
            }
        ) else {
            print("認識に失敗しました")
            return
        }
        // FIXME: ここ以下が非同期処理よりも先に実行されることを保証するべきである
        // MEMO: Use append of 2D array instead of cocate of 1D array to reduce computation time
        tmpAudioDataList.append(tmpAudioData)
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print("音声一時ファイルの削除に失敗しました")
        }
        if title != "" {
            recognizingSpeech.title = title
        }
        recognizingSpeechIds.insert(recognizingSpeech.id, at: 0)
        recognizedSpeeches.insert(recognizingSpeech, at: 0)
        isActives.insert(true, at: 0)
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
        /// remove tmp audio file
        let url = getTmpURLByNumber(number: audioFileNumber)
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print("音声一時ファイルの削除に失敗しました")
        }
    }

    // MARK: - function about ASR

    /// recognition function called in a timer
    func streamingRecognitionTimerFunc() {
        audioRecorder!.stop()

        let url = getTmpURLByNumber(number: audioFileNumber)
        guard let tmpAudioData = try? recognizer.streamingRecognize(
            audioFileURL: url,
            language: language,
            callback: { tls in
                tls.forEach { transcriptionLine in
                    transcriptionLine.startMSec = onGoingTranscriptionLineStartMSec + transcriptionLine.startMSec
                    transcriptionLine.endMSec = onGoingTranscriptionLineStartMSec + transcriptionLine.endMSec
                    transcriptionLine.ordering = onGoingTranscriptionLineStartOrdering + transcriptionLine.ordering
                    onGoingTranscriptionLines?.append(transcriptionLine)
                }
                if let lastTranscriptionLine = tls.last {
                    onGoingTranscriptionLineStartOrdering = lastTranscriptionLine.ordering + 1
                    onGoingTranscriptionLineStartMSec = lastTranscriptionLine.endMSec
                }
            }
        ) else {
            print("認識に失敗しました")
            return
        }
        /// resume recording as soon as possible
        audioFileNumber = audioFileNumber + 1
        let new_url = getTmpURLByNumber(number: audioFileNumber)
        audioRecorder = try! AVAudioRecorder(url: new_url, settings: recordSettings)
        audioRecorder!.isMeteringEnabled = true
        audioRecorder!.record()

        /// use append of 2D array instead of cocate of 1D array to reduce computation time
        tmpAudioDataList.append(tmpAudioData)
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print("音声一時ファイルの削除に失敗しました")
        }
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
            idAmps.append(idAmp)
        }

        streamingRecognitionTimer = Timer.scheduledTimer(
            withTimeInterval: Double(recognitionFrequencySec),
            repeats: true
        ) { _ in
            streamingRecognitionTimerFunc()
        }
    }

    func getTextColor(_ idx: Int) -> Color {
        let lines = onGoingTranscriptionLines!
        let startMSec = Double(lines[idx].startMSec)
        let endMSec: Double = idx < lines.count - 1 ? Double(lines[idx + 1].startMSec) : .infinity
        let currentMSec = Double(elapsedTime * 1000)
        let isInside = startMSec <= currentMSec && currentMSec < endMSec
        let uiColor: UIColor = isInside ? .systemGray5 : .systemBackground
        return Color(uiColor)
    }

    var body: some View {
        RecordButtonPane(
            isRecording: $isRecording,
            isPaused: $isPaused,
            startAction: startRecording,
            stopAction: pauseRecording
        )
        .frame(height: 150)
        .sheet(isPresented: $isPaneOpen) {
            NavigationView {
                VStack {
                    HStack {
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
                        Spacer()
                    }
                    HStack(spacing: 10) {
                        if isPaused {
                            Image(systemName: "pause.fill")
                                .foregroundColor(.gray)
                        } else {
                            Circle()
                                .fill(.red)
                                .frame(width: 10)
                        }
                        Text(formatTime(Double(elapsedTime)))
                    }.padding(40)

                    Waveform(idAmps: $idAmps, isPaused: $isPaused)
                        .padding(.top, 60)
                        .padding(.bottom, 20)
                    Divider()
                    if onGoingTranscriptionLines != nil, onGoingTranscriptionLines!.count > 0 {
                        ScrollViewReader { scrollReader in
                            ScrollView {
                                LazyVStack(spacing: 0) {
                                    ForEach(Array(onGoingTranscriptionLines!.enumerated()), id: \.self.offset) {
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
                                        .background(getTextColor(idx))
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
                                        scrollReader.scrollTo(onGoingTranscriptionLines!.count - 1, anchor: .bottom)
                                    }
                                }
                            }
                        }
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
                }
            }
        }
    }
}

private func renameAudioFileURL(recognizedSpeech: RecognizedSpeech) {
    let tmpURL = getTmpURL()
    let newURL = getAudioFileURL(id: recognizedSpeech.id)

    recognizedSpeech.audioFileURL = newURL
    do {
        try FileManager.default.moveItem(at: tmpURL, to: newURL)
    } catch {
        debugPrint("fail to move file:", error)
    }
}

/// get temporary url to save audio file
///
/// When starting recording, the id of RecognizedSpeech is not detemined yet.
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

// DEPRECATED: This operation will be done only on SideMenu
func saveUserLanguage(_ language: Language) {
    UserDefaults.standard.set(language.rawValue, forKey: UserDefaultASRLanguageKey)
}

struct RecognitionPane_Previews: PreviewProvider {
    static var previews: some View {
        RecognitionPane(
            recognizingSpeechIds: .constant([]),
            recognizedSpeeches: .constant([getRecognizedSpeechMock(audioFileName: "sample_ja", csvFileName: "sample_ja")!]),
            isActives: .constant([])
        )
    }
}
