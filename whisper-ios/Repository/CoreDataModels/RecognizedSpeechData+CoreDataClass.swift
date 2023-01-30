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

    /// Update recognizedSpeech data model.
    ///
    /// - Note: this method is used for update data model but not transcription lines.
    /// - Parameter rs: recognizedSpeech model
    static func update(_ rs: RecognizedSpeech) {
        guard let rsEntity: RecognizedSpeechData = CoreDataRepository.getById(uuid: rs.id) else {
            fatalError("object with id: \(rs.id.uuidString) is not found.")
        }

        rsEntity.id = rs.id
        rsEntity.title = rs.title
        rsEntity.audioFileURL = rs.audioFileURL
        rsEntity.language = rs.language.rawValue
        rsEntity.createdAt = rs.createdAt
        rsEntity.updatedAt = rs.updatedAt

        CoreDataRepository.save()
    }
}
