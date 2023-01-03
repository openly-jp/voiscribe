import AVFoundation
import SwiftUI

let UserDefaultASRLanguageKey = "asr-language"

struct RecognitionPane: View {
    // MARK: - Recording state
    let audioRecorder: AVAudioRecorder
    @State var isRecording: Bool = false
    @State var isPaused: Bool = false

    @State var elapsedTime: Int
    @State var idAmps: [IdAmp]

    @State var updateRecordingTimeTimer: Timer?
    @State var updateWaveformTimer: Timer?

    // MARK: - ASR state
    @EnvironmentObject var recognizer: WhisperRecognizer
    @Binding var recognizingSpeechIds: [UUID]
    @Binding var recognizedSpeeches: [RecognizedSpeech]
    @Binding var isActives: [Bool]
    @State var language: Language = getUserLanguage()
    @State var title = ""

    // MARK: - pane management state
    @State var isPaneOpen: Bool = false
    @State var isConfirmOpen: Bool = false
    @State var isCancelRecognitionAlertOpen = false

    var timeString: String {
        let minutes = String(format: "%02d", elapsedTime / 60)
        let seconds = String(format: "%02d", elapsedTime % 60)
        return "\(minutes):\(seconds)"
    }

    init(
        recognizingSpeechIds: Binding<[UUID]>,
        recognizedSpeeches: Binding<[RecognizedSpeech]>,
        isActives: Binding<[Bool]>
    ) {
        let session = AVAudioSession.sharedInstance()
        try! session.setCategory(AVAudioSession.Category.playAndRecord)
        try! session.setActive(true)

        let settings = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        self.audioRecorder = try! AVAudioRecorder(url: getTmpURL(), settings: settings)
        audioRecorder.isMeteringEnabled = true

        self.elapsedTime = 0
        self.idAmps = []
        self._recognizingSpeechIds = recognizingSpeechIds
        self._recognizedSpeeches = recognizedSpeeches
        self._isActives = isActives
    }

    // MARK: - functions about recording

    /// start recording
    ///
    /// this function is also for restarting recording when paused
    func startRecording() {
        isRecording = true
        isPaused = false
        isPaneOpen = true

        audioRecorder.record()

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
            audioRecorder.updateMeters()

            let idAmp = IdAmp(
                id: UUID(),
                amp: audioRecorder.averagePower(forChannel: 0),
                idx: idAmps.count
            )
            idAmps.append(idAmp)
        }
    }

    func pauseRecording() {
        isPaused = true

        updateRecordingTimeTimer?.invalidate()
        updateWaveformTimer?.invalidate()
        audioRecorder.pause()
    }

    /// discard all information about recording and close the pane
    ///
    /// reset timers for updateting recording time and waveform.
    /// stop recording and reset recording time and waveform.
    /// this funciton also close recognition pane.
    /// this function does not reset information about `RecognizedSpeech` like title.
    func finishRecording() {
        updateRecordingTimeTimer?.invalidate()
        updateWaveformTimer?.invalidate()
        audioRecorder.stop()

        elapsedTime = 0
        idAmps = []

        isRecording = false
        isPaneOpen = false
        isConfirmOpen = false
    }

    // MARK: - function about ASR
    func startRecognition() {
        finishRecording()

        guard let recognizingSpeech = try? recognizer.recognize(
            audioFileURL: getTmpURL(),
            language: language,
            callback: { rs in
                var removeIdx: Int?
                for idx in 0 ..< recognizingSpeechIds.count {
                    if recognizingSpeechIds[idx] == rs.id {
                        removeIdx = idx
                        break
                    }
                }
                if let removeIdx {
                    recognizingSpeechIds.remove(at: removeIdx)
                }
                renameAudioFileURL(recognizedSpeech: rs)
                CoreDataRepository.saveRecognizedSpeech(aRecognizedSpeech: rs)

                title = ""
            }
        ) else {
            print("認識に失敗しました")
            return
        }
        if title != "" {
            recognizingSpeech.title = title
        }
        recognizingSpeechIds.insert(recognizingSpeech.id, at: 0)
        recognizedSpeeches.insert(recognizingSpeech, at: 0)
        isActives.insert(true, at: 0)

        saveUserLanguage(language)
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
                                primaryButton: .destructive(Text("終了"), action: finishRecording),
                                secondaryButton: .cancel())
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
                        Text(timeString)
                    }.padding(40)

                    Waveform(idAmps: $idAmps)
                        .padding(.top, 40)
                        .padding(.bottom, 40)

                    NavigationLink(
                        destination: ConfirmPane(
                            startRecognition: startRecognition,
                            reset: finishRecording,
                            language: $language,
                            title: $title
                        ),
                        isActive: $isConfirmOpen
                    ) {}.hidden()
                    HStack(spacing: 50) {
                        StopButtonPane {
                            pauseRecording()
                            isConfirmOpen = true
                        }
                        RecordButtonPane(
                            isRecording: $isRecording,
                            isPaused: $isPaused,
                            startAction: startRecording,
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
    try! FileManager.default.moveItem(at: tmpURL, to: newURL)
}

/// get temporary url to save audio file
///
/// When starting recording, the id of RecognizedSpeech is not detemined yet.
/// Thus recorded audio is firstly saved to a temporary file and it is renamed after.
func getTmpURL() -> URL {
    return getURLByName(fileName: "tmp.m4a")
}

func getAudioFileURL(id: UUID) -> URL {
    return getURLByName(fileName: "\(id.uuidString).m4a")
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
