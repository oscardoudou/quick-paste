//
//  NSFRCChangeConsolidator.swift
//  Quick Paste
//
//  Created by 张壹弛 on 12/4/19.
//  Copyright © 2019 张壹弛. All rights reserved.
//

import Foundation
import CoreData

class NSFRCChangeConsolidator: NSObject {
       private var rowDeletes: [IndexPath] = []
       private var rowInserts: [IndexPath] = []
       private var rowUpdates: [IndexPath] = []
       
       func ingestItemChange(ofType changeType: NSFetchedResultsChangeType, oldIndexPath: IndexPath?, newIndexPath: IndexPath?) {
           switch changeType {
           case .insert:
               self.rowInserts.append(newIndexPath!)
           case .delete:
               self.rowDeletes.append(oldIndexPath!)
           case .move:
               self.rowDeletes.append(oldIndexPath!)
               self.rowInserts.append(newIndexPath!)
           case .update:
               self.rowUpdates.append(newIndexPath!)
           @unknown default:
            logger.log(category: .app, message: "Unknown change type")
               fatalError("Unknown change type")
           }
       }
       
       // Reverse-sorted row deletes, suitable for feeding into table views.
       func sortedRowDeletes() -> [IndexPath] {
           return rowDeletes.sorted { $0.item > $1.item }
       }
       
       // Sorted row inserts, suitable for feeding into table views.
       func sortedRowInserts() -> [IndexPath] {
           return rowInserts.sorted { $0.item < $1.item }
       }

       // Sorted row updates, suitable for feeding into table views.
       func sortedRowUpdates() -> [IndexPath] {
           return rowUpdates.sorted { $0.item < $1.item }
       }
}
