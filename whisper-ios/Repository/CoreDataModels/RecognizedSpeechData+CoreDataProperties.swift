//
//  RecognizedSpeechData+CoreDataProperties.swift
//  whisper-ios
//
//  Created by creevo on 2023/01/02.
//  Copyright © 2023 jp.openly. All rights reserved.
//
//

import CoreData
import Foundation

public extension RecognizedSpeechData {
    @nonobjc class func fetchRequest() -> NSFetchRequest<RecognizedSpeechData> {
        NSFetchRequest<RecognizedSpeechData>(entityName: "RecognizedSpeechData")
    }

    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var audioFileURL: URL
    @NSManaged var language: String
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var transcriptionLines: NSSet
}

// MARK: Generated accessors for transcriptionLines

public extension RecognizedSpeechData {
    @objc(insertObject:inTranscriptionLinesAtIndex:)
    @NSManaged func insertIntoTranscriptionLines(_ value: TranscriptionLineData, at idx: Int)

    @objc(removeObjectFromTranscriptionLinesAtIndex:)
    @NSManaged func removeFromTranscriptionLines(at idx: Int)

    @objc(insertTranscriptionLines:atIndexes:)
    @NSManaged func insertIntoTranscriptionLines(_ values: [TranscriptionLineData], at indexes: NSIndexSet)

    @objc(removeTranscriptionLinesAtIndexes:)
    @NSManaged func removeFromTranscriptionLines(at indexes: NSIndexSet)

    @objc(replaceObjectInTranscriptionLinesAtIndex:withObject:)
    @NSManaged func replaceTranscriptionLines(at idx: Int, with value: TranscriptionLineData)

    @objc(replaceTranscriptionLinesAtIndexes:withTranscriptionLines:)
    @NSManaged func replaceTranscriptionLines(at indexes: NSIndexSet, with values: [TranscriptionLineData])

    @objc(addTranscriptionLinesObject:)
    @NSManaged func addToTranscriptionLines(_ value: TranscriptionLineData)

    @objc(removeTranscriptionLinesObject:)
    @NSManaged func removeFromTranscriptionLines(_ value: TranscriptionLineData)

    @objc(addTranscriptionLines:)
    @NSManaged func addToTranscriptionLines(_ values: NSSet)

    @objc(removeTranscriptionLines:)
    @NSManaged func removeFromTranscriptionLines(_ values: NSSet)
}

extension RecognizedSpeechData: Identifiable {}
