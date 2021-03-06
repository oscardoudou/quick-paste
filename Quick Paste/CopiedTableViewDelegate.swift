//
//  CopiedTableViewDelegate.swift
//  Quick Paste
//
//  Created by 张壹弛 on 12/24/19.
//  Copyright © 2019 张壹弛. All rights reserved.
//

import Cocoa

class CopiedTableViewDelegate: NSObject, NSTableViewDelegate {
    var fetchedResultsController: NSFetchedResultsController<Copied>!
    //both tableView and detailViewController reference are have-to have to allow detailViewVC work,
    //and yet both refence instance are instantiated in other file, so timing to point to those reference is critical.
    //eg: tableView is realy when ViewController's view is really, so reference to tableView could done in viewDidLoad of ViewController,
    //while detailViewController won't be ready until detialViewController is instantiated, so safe place to referencing is in detailViewController's viewDidLoad or splitViewController viewDidLoad
    //as splitViewController's view is parent view of detailVC'view and viewController's view, so it's view won't be ready until its children view ready
    var tableView: NSTableView!
    var detailViewController: DetailViewController!
    func tableViewSelectionDidChange(_ notification: Notification) {
        let scrollView: NSScrollView = detailViewController.view.subviews[0] as! NSScrollView
        scrollView.magnification = 1.0
        logger.log(category: .app, message: "inside tableViewSelectionDidChange")
        logger.log(category: .ui, message: "tableView.selectedRow: \(tableView.selectedRow)")
        logger.log(category: .app , message: "detailViewController: \(String(describing: detailViewController))")
        detailViewController.getCopiedFromLeft()
        logger.log(category: .app, message: "before passing data to detailViewController")
        if(tableView.selectedRow == -1){return}
        if let copied = fetchedResultsController.fetchedObjects![tableView.selectedRow] as? Copied{
            detailViewController.copied = copied
            if(copied.thumbnail == nil){
                detailViewController.showTextDetail()
            }else{
                detailViewController.showImageDetail()
            }
        }
        detailViewController.getCopiedFromLeft()
    }
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
//            if let copied: Copied = fetchedResultsController.fetchedObjects![row] as? Copied{
//                if let thumbnail = copied.thumbnail as NSData?{
//    //                let tv: NSImageView = NSImageView(image: NSImage(data: copied.thumbnail!)!)
//    //                let someWidth: CGFloat = tableView.frame.size.width
//    //                let frame: NSRect = NSMakeRect(0, 0, someWidth, CGFloat.greatestFiniteMagnitude)
//    //                let tv: NSImageView = NSImageView(frame: frame)
//    //                print("Before sizeToFit\(tv.frame.size.height)")
//    //                tv.sizeToFit()
//    //                print("After sizeToFit\(tv.frame.size.height)")
//                    return 70
//                }
//                if let string: String = copied.name{
//                    let someWidth: CGFloat = tableView.frame.size.width
//                    let stringAttributes = [NSAttributedString.Key.font: NSFont.systemFont(ofSize: 12)] //change to font/size u are using
//                    let attrString: NSAttributedString = NSAttributedString(string: string, attributes: stringAttributes)
//                    let frame: NSRect = NSMakeRect(0, 0, someWidth, CGFloat.greatestFiniteMagnitude)
//                    let tv: NSTextView = NSTextView(frame: frame)
//                    tv.textStorage?.setAttributedString(attrString)
//                    tv.isHorizontallyResizable = false
//                    tv.sizeToFit()
//                    let height: CGFloat = tv.frame.size.height + 17 // + other objects...
//                    return height
//                }
//            }
            return 17
        }
        // 2/2 have to implement function to show core data in table view
        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            var cellIdentifier: String = ""
    //        var cell: NSTableCellView!
            //probably should guard
            let copied :Copied = fetchedResultsController.fetchedObjects![row]
            let column = tableView.tableColumns.firstIndex(of: tableColumn!)!
            switch column{
            case 0:
                cellIdentifier = "DeviceCellId"
            case 1:
                cellIdentifier = "NameCellId"
            case 2:
                cellIdentifier = "TimeCellId"
            default:
                return nil
            }
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView{
                configureCell(cell: cell, row: row, column: column)
                //pure text hide image
                if(copied.thumbnail == nil){
                    if(column == 1){
                        cell.imageView?.isHidden = true
                        cell.textField?.isHidden = false
                    }
                //if have image type data, hide text
                }else{
                    if(column == 1){
                        cell.textField?.isHidden = false
                        cell.imageView?.isHidden = true
                    }
                }
                return cell
            }
            return nil
        }
         func configureCell(cell: NSTableCellView, row: Int, column: Int){
            var image: NSImage?
            var name: String?
            var time: String?
            var device: String?
            var text: String?
            let dateFormatter = DateFormatter()
            let copied = fetchedResultsController.fetchedObjects![row]
            switch column {
            case 0:
                device = String(copied.id)
                if let deviceNonOptional = copied.device{
                  device = deviceNonOptional == "mac" ? "🖥" : "📱"
                }
                text = device
            case 1:
                image = copied.thumbnail != nil ? NSImage(data: copied.thumbnail!) : NSImage(named: "stackoverflow")
                name = copied.name
                text = name
            case 2:
                dateFormatter.timeStyle = .medium
                time = copied.timestamp != nil ? dateFormatter.string(from: copied.timestamp!) : "notime"
                text = time
            default:
                break
            }
            cell.textField?.stringValue = text != nil ? text! : "default"
            cell.imageView?.image = image
        }
}
