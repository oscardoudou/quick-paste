//
//  CopiedDataSource.swift
//  Quick Paste
//
//  Created by 张壹弛 on 12/22/19.
//  Copyright © 2019 张壹弛. All rights reserved.
//

import Cocoa

class CopiedDataSource: NSObject, NSTableViewDataSource {
    var fetchedResultsController: NSFetchedResultsController<Copied>!
    // 1/2 have to implement function to show core data in table view
    func numberOfRows(in tableView: NSTableView) -> Int {
        let count = fetchedResultsController.fetchedObjects?.count
        logger.log(category: .data, message: "Number of Rows: \(String(describing: count))")
        return count ?? 0
    }
}
