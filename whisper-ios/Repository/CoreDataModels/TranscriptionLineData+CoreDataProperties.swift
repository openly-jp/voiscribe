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

public extension TranscriptionLineData {
    @nonobjc class func fetchRequest() -> NSFetchRequest<TranscriptionLineData> {
        NSFetchRequest<TranscriptionLineData>(entityName: "TranscriptionLineData")
    }

    @NSManaged var id: UUID
    @NSManaged var startMSec: Int64
    @NSManaged var endMSec: Int64
    @NSManaged var text: String
    @NSManaged var ordering: Int32
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var recognizedSpeech: RecognizedSpeechData?
}

extension TranscriptionLineData: Identifiable {}
