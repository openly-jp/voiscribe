//
//  RecognizedSpeechData+CoreDataClass.swift
//  whisper-ios
//
//  Created by creevo on 2023/01/02.
//  Copyright © 2023 jp.openly. All rights reserved.
//
//

import CoreData
import Foundation

@objc(RecognizedSpeechData)
public class RecognizedSpeechData: NSManagedObject {
    static func new(aRecognizedSpeech: RecognizedSpeech) -> RecognizedSpeechData {
        let rsEntity: RecognizedSpeechData = CoreDataRepository.entity()
        rsEntity.id = aRecognizedSpeech.id
        rsEntity.title = aRecognizedSpeech.title
        rsEntity.audioFileURL = aRecognizedSpeech.audioFileURL
        rsEntity.language = aRecognizedSpeech.language.rawValue
        rsEntity.createdAt = aRecognizedSpeech.createdAt
        rsEntity.updatedAt = aRecognizedSpeech.updatedAt

        for aTranscriptionLine in aRecognizedSpeech.transcriptionLines {
            let tlEntity: TranscriptionLineData = CoreDataRepository.entity()
            tlEntity.id = aTranscriptionLine.id
            tlEntity.startMSec = aTranscriptionLine.startMSec
            tlEntity.endMSec = aTranscriptionLine.endMSec
            tlEntity.text = aTranscriptionLine.text
            tlEntity.ordering = aTranscriptionLine.ordering
            tlEntity.createdAt = aTranscriptionLine.createdAt
            tlEntity.updatedAt = aTranscriptionLine.updatedAt

            tlEntity.recognizedSpeech = rsEntity
            rsEntity.addToTranscriptionLines(tlEntity)
        }
        return rsEntity
    }

    static func toModel(aRecognizedSpeechData: RecognizedSpeechData) -> RecognizedSpeech {
        let rsModel = RecognizedSpeech(
            id: aRecognizedSpeechData.id,
            title: aRecognizedSpeechData.title,
            audioFileURL: aRecognizedSpeechData.audioFileURL,
            language: Language(rawValue: aRecognizedSpeechData.language)!,
            transcriptionLines: [],
            createdAt: aRecognizedSpeechData.createdAt,
            updatedAt: aRecognizedSpeechData.updatedAt
        )

        let transcriptionLines: [TranscriptionLine] = []
        for tld in aRecognizedSpeechData.transcriptionLines {
            let tldEntity = tld as! TranscriptionLineData
            let tlModel = TranscriptionLine(
                id: tldEntity.id,
                startMSec: tldEntity.startMSec,
                endMSec: tldEntity.endMSec,
                text: tldEntity.text,
                ordering: tldEntity.ordering,
                createdAt: tldEntity.createdAt,
                updatedAt: tldEntity.updatedAt
            )

            rsModel.transcriptionLines.append(tlModel)
        }
        return rsModel
    }
}
