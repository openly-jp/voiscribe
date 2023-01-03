//
//  TranscriptionLineData+CoreDataProperties.swift
//  whisper-ios
//
//  Created by creevo on 2023/01/02.
//  Copyright © 2023 jp.openly. All rights reserved.
//
//

import CoreData
import Foundation

extension TranscriptionLineData {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TranscriptionLineData> {
        NSFetchRequest<TranscriptionLineData>(entityName: "TranscriptionLineData")
    }

    @NSManaged public var id: UUID
    @NSManaged public var startMSec: Int64
    @NSManaged public var endMSec: Int64
    @NSManaged public var text: String
    @NSManaged public var ordering: Int32
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var recognizedSpeech: RecognizedSpeechData?
}

extension TranscriptionLineData: Identifiable {}
