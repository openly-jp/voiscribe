//
//  RecognizedSpeechData+CoreDataProperties.swift
//  whisper-ios
//
//  Created by creevo on 2023/01/02.
//  Copyright © 2023 jp.openly. All rights reserved.
//
//

import Foundation
import CoreData


extension RecognizedSpeechData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RecognizedSpeechData> {
        return NSFetchRequest<RecognizedSpeechData>(entityName: "RecognizedSpeechData")
    }

    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var audioFileURL: URL
    @NSManaged public var language: String
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var transcriptionLines: NSOrderedSet

}

// MARK: Generated accessors for transcriptionLines
extension RecognizedSpeechData {

    @objc(insertObject:inTranscriptionLinesAtIndex:)
    @NSManaged public func insertIntoTranscriptionLines(_ value: TranscriptionLineData, at idx: Int)

    @objc(removeObjectFromTranscriptionLinesAtIndex:)
    @NSManaged public func removeFromTranscriptionLines(at idx: Int)

    @objc(insertTranscriptionLines:atIndexes:)
    @NSManaged public func insertIntoTranscriptionLines(_ values: [TranscriptionLineData], at indexes: NSIndexSet)

    @objc(removeTranscriptionLinesAtIndexes:)
    @NSManaged public func removeFromTranscriptionLines(at indexes: NSIndexSet)

    @objc(replaceObjectInTranscriptionLinesAtIndex:withObject:)
    @NSManaged public func replaceTranscriptionLines(at idx: Int, with value: TranscriptionLineData)

    @objc(replaceTranscriptionLinesAtIndexes:withTranscriptionLines:)
    @NSManaged public func replaceTranscriptionLines(at indexes: NSIndexSet, with values: [TranscriptionLineData])

    @objc(addTranscriptionLinesObject:)
    @NSManaged public func addToTranscriptionLines(_ value: TranscriptionLineData)

    @objc(removeTranscriptionLinesObject:)
    @NSManaged public func removeFromTranscriptionLines(_ value: TranscriptionLineData)

    @objc(addTranscriptionLines:)
    @NSManaged public func addToTranscriptionLines(_ values: NSOrderedSet)

    @objc(removeTranscriptionLines:)
    @NSManaged public func removeFromTranscriptionLines(_ values: NSOrderedSet)

}

extension RecognizedSpeechData : Identifiable {

}
