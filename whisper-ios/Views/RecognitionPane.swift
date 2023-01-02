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
    @State var audioRecorder: AVAudioRecorder
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
        
        audioRecorder = try! AVAudioRecorder(url: getURL(), settings: settings)
        
        elapsedTime = 0
        idAmps = []
        self._recognizedSpeeches = recognizedSpeeches
    }
    
    func onClickRecordButton() {
        if isRecording { start() } else { stop() }
    }
    
    func start() {
        isRecording = true
        audioRecorder.record()
        
        updateRecordingTimeTimer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true
        ) { _ in
            self.elapsedTime += 1
        }
        audioRecorder.isMeteringEnabled = true

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
    
    func stop() {
        isRecording = false
        let language: Language = .en
        
        updateRecordingTimeTimer?.invalidate()
        audioRecorder.stop()
        
        let url = getURL()
        let recognizer = WhisperRecognizer(modelName: "ggml-tiny.en")
        guard let recognizedSpeech = try? recognizer.recognize(
            audioFileURL: url,
            language: language
        ) else {
            print("認識に失敗しました")
            return
        }
        let transcriptionLines = recognizedSpeech.transcriptionLines
        var transcription = ""
        for i in 0 ..< transcriptionLines.count {
            transcription += transcriptionLines[i].text
        }
        
        let aRecognizedSpeech = RecognizedSpeech(
            audioFileURL: url,
            language: language,
            transcriptionLines: transcriptionLines
        )
        CoreDataRepository.saveRecognizedSpeech(aRecognizedSpeech: aRecognizedSpeech)
        recognizedSpeeches.append(aRecognizedSpeech)
    }
    
    var body: some View {
        RecordButtonPane(
            isRecording: $isRecording,
            startAction: start,
            stopAction: {}
        )
        .frame(height: 150)
        .sheet(isPresented: $isRecording, content: {
            VStack {
                HStack(spacing: 10) {
                    Circle()
                        .fill(.red)
                        .frame(width: 10)
                    Text(timeString)
                }.padding(50)
                
                Waveform(idAmps: $idAmps)
                    .padding(.top, 40)
                    .padding(.bottom, 40)
                HStack(spacing: 50) {
                    StopButtonPane {}
                    RecordButtonPane(
                        isRecording: $isRecording,
                        startAction: {},
                        stopAction: stop
                    )
                }
                    .padding(.bottom, 30)
            }
                
        })
    }
}

func getURL() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let docsDirect = paths[0]
    let url = docsDirect.appendingPathComponent("recording.m4a")
    return url
}

struct RecognitionPane_Previews: PreviewProvider {
    static var previews: some View {
        RecognitionPane(recognizedSpeeches: .constant(CoreDataRepository.getAll()))
    }
}
