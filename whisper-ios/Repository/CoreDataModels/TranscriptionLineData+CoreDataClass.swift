//
//  TranscriptionLineData+CoreDataClass.swift
//  whisper-ios
//
//  Created by creevo on 2023/01/02.
//  Copyright © 2023 jp.openly. All rights reserved.
//
//

import CoreData
import Foundation

@objc(TranscriptionLineData)
public class TranscriptionLineData: NSManagedObject {
    static func update(_ tl: TranscriptionLine) {
        guard let tlEntity: TranscriptionLineData = CoreDataRepository.getById(uuid: tl.id) else {
            fatalError("object with id: \(tl.id.uuidString) is not found.")
        }

        tlEntity.id = tl.id
        tlEntity.startMSec = tl.startMSec
        tlEntity.endMSec = tl.endMSec
        tlEntity.text = tl.text
        tlEntity.ordering = tl.ordering
        tlEntity.createdAt = tl.createdAt
        tlEntity.updatedAt = tl.updatedAt

        CoreDataRepository.save()
    }
}
