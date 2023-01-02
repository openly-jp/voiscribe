//
//  RecognitionPane.swift
//  whisper-ios
//
//  Created by creevo on 2022/12/31.
//  Copyright © 2022 jp.openly. All rights reserved.
//

import AVFoundation
import SwiftUI

struct RecognitionPane: View {
    @EnvironmentObject var recognizer: WhisperRecognizer
    @Binding var recognizedSpeeches: [RecognizedSpeech]

    @State var isRecording: Bool = false
    @State var isPaused: Bool = false
    @State var isPaneOpen: Bool = false

    let audioRecorder: AVAudioRecorder
    @State var elapsedTime: Int
    @State var idAmps: [IdAmp]

    @State var updateRecordingTimeTimer: Timer?
    @State var updateWaveformTimer: Timer?

    var timeString: String {
        let minutes = String(format: "%02d", elapsedTime / 60)
        let seconds = String(format: "%02d", elapsedTime % 60)
        return "\(minutes):\(seconds)"
    }

    init(recognizedSpeeches: Binding<[RecognizedSpeech]>) {
        let session = AVAudioSession.sharedInstance()
        try! session.setCategory(AVAudioSession.Category.playAndRecord)
        try! session.setActive(true)

        let settings = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        audioRecorder = try! AVAudioRecorder(url: getTmpURL(), settings: settings)
        audioRecorder.isMeteringEnabled = true

        elapsedTime = 0
        idAmps = []
        self._recognizedSpeeches = recognizedSpeeches
    }

    func onClickRecordButton() {
        if isRecording { start() } else { stop() }
    }

    /// start recording
    ///
    /// this function is also for restarting recording when paused
    func start() {
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

    func pause() {
        isPaused = true

        updateRecordingTimeTimer?.invalidate()
        updateWaveformTimer?.invalidate()
        audioRecorder.pause()
    }

    func stop() {
        isRecording = false
        isPaneOpen = false

        updateRecordingTimeTimer?.invalidate()
        updateWaveformTimer?.invalidate()
        audioRecorder.stop()

        elapsedTime = 0
        idAmps = []

        let recognizer = WhisperRecognizer(modelName: "ggml-tiny.en")
        guard let recognizedSpeech = try? recognizer.recognize(
            audioFileURL: getTmpURL(),
            language: .ja
        ) else {
            print("認識に失敗しました")
            return
        }

        renameAudioFileURL(recognizedSpeech: recognizedSpeech)
        CoreDataRepository.saveRecognizedSpeech(aRecognizedSpeech: recognizedSpeech)
        recognizedSpeeches.append(recognizedSpeech)
    }

    var body: some View {
        RecordButtonPane(
            isRecording: $isRecording,
            isPaused: $isPaused,
            startAction: start,
            stopAction: pause
        )
        .frame(height: 150)
        .sheet(isPresented: $isPaneOpen, content: {
            VStack {
                HStack(spacing: 10) {
                    if isPaused{
                        Image(systemName: "pause.fill")
                            .foregroundColor(.gray)
                    } else {
                        Circle()
                            .fill(.red)
                            .frame(width: 10)
                    }
                    Text(timeString)
                }.padding(50)

                Waveform(idAmps: $idAmps)
                    .padding(.top, 40)
                    .padding(.bottom, 40)
                HStack(spacing: 50) {
                    StopButtonPane(stopAction: stop)
                    RecordButtonPane(
                        isRecording: $isRecording,
                        isPaused: $isPaused,
                        startAction: start,
                        stopAction: pause
                    )
                }
                .padding(.bottom, 30)
            }

        })
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
    return getURLByName(fileName: id.uuidString)
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

struct RecognitionPane_Previews: PreviewProvider {
    static var previews: some View {
        RecognitionPane(recognizedSpeeches: .constant(CoreDataRepository.getAll()))
    }
}
