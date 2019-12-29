//
//  ViewController.swift
//  Quick Paste
//
//  Created by 张壹弛 on 12/24/18.
//  Copyright © 2018 张壹弛. All rights reserved.
//

import Cocoa
import CoreData

class ViewController: NSViewController {

    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var tableView: NSTableView!
    var consolidator : NSFRCChangeConsolidator?
    var rowToBeFocusedIndex: NSIndexSet!
//    var container: NSPersistentContainer!
    //store managedObject array of current view
    var copieds : [Copied]?
    var fetchPredicate : NSPredicate? {
        didSet {
            fetchedResultsController.fetchRequest.predicate = fetchPredicate
            print("FetchResultsController.fecthRequest.predicate changed from \(oldValue) to \(fetchPredicate)")
        }
    }
    var appDelegate : AppDelegate!
    var dataController : DataController!
    private var dataSource: CopiedDataSource!
    private var tableViewDelegate: CopiedTableViewDelegate!
    private lazy var fetchedResultsController: NSFetchedResultsController<Copied> = {
//        let context = container.viewContext
        let context = dataController.context
        let fetchRequest = NSFetchRequest<Copied>(entityName: "Copied")
        let nameSort = NSSortDescriptor(key: "timestamp", ascending: false)
        fetchRequest.sortDescriptors = [nameSort]
        fetchRequest.predicate = fetchPredicate
        //here should refer directly from place where persistent initialize rather detour from appdelegate, but for now just leave it as it was
        //let context = dataController.persistentContainer
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        //important step, but don't know exactly why
        controller.delegate = self
        return controller
    }()
    override func viewDidAppear() {
        super.viewDidAppear()
        //after using CustomView searchfield is not auto focused anymore
        searchField.window?.makeFirstResponder(searchField)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate = NSApplication.shared.delegate as! AppDelegate
//        guard container != nil else{
        guard dataController.persistentContainer != nil else{
            fatalError("This view need a persistent container")
        }
        // Do any additional setup after loading the view.
        do{
            try fetchedResultsController.performFetch()
        }catch{
            fatalError("Failed to fecth entites: \(error)")
        }
        copieds = fetchedResultsController.fetchedObjects
        dataSource = CopiedDataSource()
        dataSource.fetchedResultsController = fetchedResultsController
        tableViewDelegate = CopiedTableViewDelegate()
        tableViewDelegate.fetchedResultsController = fetchedResultsController
        tableView.dataSource = dataSource
        tableView.delegate = tableViewDelegate
        searchField.delegate = self
        tableView.action = #selector(copyOnSelect)
        print("AXIsProcessTrusted(): \(AXIsProcessTrusted())")
       
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    //table view copy on select
    @objc func copyOnSelect(sender: NSTableView){
        print("---------copyOnSelect--------------")
        guard tableView.selectedRow >= 0,
            let item: Copied = copieds![tableView.selectedRow] else {
            return
        }
        print("rowView\(tableView.rowView(atRow: tableView.selectedRow, makeIfNecessary: false))")
        let cellView = tableView.view(atColumn: 0, row: tableView.selectedRow, makeIfNecessary: false)
        print ("cellView\(cellView?.subviews[0])")
        let imageView = cellView?.subviews[0] as! NSImageView
        print("imageView hide status: \(imageView.isHidden)")
        let textField = cellView?.subviews[1] as! NSTextField
        print ("stringValue: \(textField.stringValue)")
        print("thumbnail == nil ? : \(item.thumbnail == nil)")
        copyIt(item: item)
    }
    //table view copy on shortcut
    @objc func copyOnNumber(numberKey: Int){
        print("---------copyOnNumber--------------")
        print("available copied count in current view: \(copieds!.count)")
        guard numberKey <= copieds!.count,
            let item: Copied = copieds![numberKey-1] else {
            return
        }
        copyIt(item: item)
    }
    private func copyOnReturn(currentRow: Int){
        print("---------CopyOnReturn---------------")
        print("available copied count in current view: \(copieds!.count)")
        guard currentRow <= copieds!.count,
            let item: Copied = copieds![currentRow] else {
            return
        }
        copyIt(item: item)
    }
    //base copy
    private func copyIt(item: Copied){
        //important step
        NSPasteboard.general.clearContents()
        //avoid post to notification center post to .NSPasteBoardDidChange, since clearContents would increment pasteboard changeCount
        appDelegate.lastChangeCount = NSPasteboard.general.changeCount
        print ("Copied \(item.id): \(item.type)")
        if(item.type == "public.png"){
            NSPasteboard.general.setData(item.thumbnail!, forType: NSPasteboard.PasteboardType.init("public.png"))
        }else{
            //data error may lead to unwrap failure, though now it seems not possible, so using if let to safely unwrap
            if let path = item.path, let type = item.type, let name = item.name {
                NSPasteboard.general.setString(path, forType: NSPasteboard.PasteboardType.init(type))
                NSPasteboard.general.setString(name, forType: NSPasteboard.PasteboardType.init("public.utf8-plain-text"))
            }
        }
        print("we copy entry content to pasteboard")
        appDelegate.printPasteBoard()
    }
    //base delete
    private func deleteIt(){
        print("---------deleteIt------------")
        let item: Copied = copieds![tableView.selectedRow]
        dataController.removeCopied(item: item)
    }
    //monitor for keydown event
    override func keyDown(with event: NSEvent) {
        //avoid crash caused by cmd+backspace
        if(event.keyCode>=18 && event.keyCode<=23){
            switch event.modifierFlags.intersection(.deviceIndependentFlagsMask) {
            //not using event.keycode is because keyCode of key 5 key 6 is reverse sequence
            case [.command] where Int(event.characters!)! <= 6 && Int(event.characters!)! >= 1 :
                print("command+\(event.characters!)")
                copyOnNumber(numberKey: Int(event.characters!)!)
            //other modifier keys
            default:
                break
            }
        }
        if event.keyCode == 51{
            print("detected deletetable. View.selectedRow:\(tableView.selectedRow),  event.timestamp: \(event.timestamp)")
            var popOverWindow: NSWindow?
            NSApplication.shared.windows.forEach{window in
//                print(window.className)
                if(window.className.contains("Popover")){
                    popOverWindow = window
//                    print(popOverWindow)
                }
            }
            if popOverWindow!.firstResponder?.isKind(of: NSTableView.self) == true && popOverWindow!.isKeyWindow {
                //focus change to searchfield only if no entry left
                print("deleting row: \(tableView.selectedRow)")
                //if deleting row is last row, focus on prev index instead of sticking to same index of deleting row
                let rowToBeFocused = tableView.selectedRow == copieds!.count-1 ? tableView.selectedRow-1: tableView.selectedRow
                print("rowToBeFocused: \(rowToBeFocused)")
                //even if you selectRowIndexes here, it won't work at this point even put it after deleteIt(core data processing is done), since tableview UI hasn't start yet.
                rowToBeFocusedIndex = NSIndexSet(index: rowToBeFocused)
                let changeFocusToSearchBar = copieds!.count == 1 ? true : false
                //currently only support delete on record
                if tableView.selectedRow >= 0 {
                    deleteIt()
                    if changeFocusToSearchBar == true{
                        popOverWindow!.makeFirstResponder(searchField)
                        searchField.currentEditor()?.moveToEndOfLine(nil)
                        searchField.moveToEndOfDocument(nil)
                    }
                    else{
                        popOverWindow!.makeFirstResponder(tableView)
                    }
                }
            }
        }
        if event.keyCode == 125{
            print("detected arrow down")
            print("tableView.selectedRow:\(tableView.selectedRow),  event.timestamp: \(event.timestamp)")
//            print("NSApplication.shared.windows:\(NSApplication.shared.windows)")
            var popOverWindow: NSWindow?
            NSApplication.shared.windows.forEach{window in
                print(window.className)
                if(window.className.contains("Popover")){
                    popOverWindow = window; print(popOverWindow)
                }
            }
            //when focus on searchbar, arrow down would bring focus to tableview and highlight first row
            if popOverWindow!.firstResponder?.isKind(of: NSTextView.self) == true{
                //tackle click back to search bar, remaining rows selected
                print("tableView.selectedRowIndexes.count\(tableView.selectedRowIndexes.count)")
                //only right after launch directly go to table will not go inside this condition
                if tableView.selectedRowIndexes.count > 0{
                    tableView.deselectAll(tableView.selectedRowIndexes)
                }
                //move focus only if there is result present
                if(copieds!.count>0){
                    popOverWindow!.makeFirstResponder(tableView)
                }
            }
        }
        if event.keyCode == 126{
            print("detected arrow up")
            print("tableView.selectedRow:\(tableView.selectedRow), event.timestamp: \(event.timestamp)")
            var popOverWindow: NSWindow?
            NSApplication.shared.windows.forEach{window in
                print(window.className)
                if(window.className.contains("Popover")){
                    popOverWindow = window; print(popOverWindow)
                }
            }
            if popOverWindow!.firstResponder?.isKind(of: NSTableView.self) == true{
                print("copieds!.count\(copieds!.count)")
                if tableView.selectedRow == 0{
                    popOverWindow!.makeFirstResponder(searchField)
                    //remove this line if you want text being selected
                    searchField.currentEditor()?.moveToEndOfLine(nil)
                    searchField.moveToEndOfDocument(nil)
                }
            }
        }
        if event.keyCode == 36{
            print("return key detected，View.selectedRow:\(tableView.selectedRow),  event.timestamp: \(event.timestamp)")
            var popOverWindow: NSWindow?
            NSApplication.shared.windows.forEach{window in
                print(window.className)
                if(window.className.contains("Popover")){
                    popOverWindow = window; print(popOverWindow)
                }
            }
            if popOverWindow?.firstResponder?.isKind(of: NSTableView.self) == true{
                print("current selected row:\(tableView.selectedRow)")
                copyOnReturn(currentRow: tableView.selectedRow)
            }
        }
        //global shortcut
        //ctrl+shift+q popup the quick paste window
        if event.keyCode == 12{
            print("q detected")
            switch event.modifierFlags.intersection(.deviceIndependentFlagsMask){
            case[.control, .shift]:
                print("control+shift");
                if(appDelegate == nil){
                    appDelegate = NSApplication.shared.delegate as! AppDelegate
                }
                appDelegate.togglePopover(appDelegate.statusItem.button)
            default:
                break
            }
        }
    }
}

extension ViewController {
  // MARK: Storyboard instantiation
  static func freshController() -> ViewController {
    //1.
    let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
    //2.
    let identifier = NSStoryboard.SceneIdentifier("ViewController")
    //3.
    guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? ViewController else {
      fatalError("Why cant i find ViewController? - Check Main.storyboard")
    }
    return viewcontroller
  }
}

extension ViewController{
    @IBAction func Quit(_ sender: Any) {
        appDelegate.globalBringUpMonitor.stop()
        NSApplication.shared.terminate(self)
    }
    @IBAction func clear(_ sender: NSButton) {
        print("trigger clear button")
        dataController.deleteAll()
//        tableView.reloadData()
    }
}
extension ViewController: NSSearchFieldDelegate{
    func controlTextDidChange(_ notification: Notification) {
        if let field = notification.object as? NSSearchField {
            let query = field.stringValue
            if query.isEmpty {
                fetchPredicate = nil
            } else {
                fetchPredicate = NSPredicate(format: "name contains[cd] %@", query)
            }
            requestData(with: fetchPredicate)
        } else {
            //not sure how to call super's method, gives me a error now
            //super.controlTextDidChange(notification)
        }
    }
    func requestData(with predicate : NSPredicate? = nil) {
            //instead of modify the predicate of fetchRequest of NSFetchedResultsController, simply change property fetchPredicate value, add observer on the property, so everytime fetchPredicate change, the predicate of fetchRequest of NSFetchedResultsController change as well
            //fetchedResultsController.fetchRequest.predicate = predicate
        do{
            try fetchedResultsController.performFetch()
            print ("Fetched \(fetchedResultsController.fetchedObjects?.count) objects")
            copieds = fetchedResultsController.fetchedObjects
            //when you search, you dont actually add any new object, instead you change the fetchedResultsController's predicate, since this repointing, the context doesn't observer any changes. you need reload to refresh the view manually
            tableView.reloadData()
        } catch let error{
            fatalError("Failed to request Data, \(error.localizedDescription) ")
        }
    }
}

//this extension is important, but don't know the difference from class ViewController: NSViewController, NSFetchedResultsControllerDelegate
extension ViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("tableViewBeginUpdates")
        print("tableView select row before tableview UI update: \(tableView.selectedRow)")
        consolidator = NSFRCChangeConsolidator()
        tableView.beginUpdates()
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>){
        if let rowDeletes = consolidator?.sortedRowDeletes(){
            if(rowDeletes.count > 0){
                for indexPath in rowDeletes{
                    tableView.removeRows(at: [indexPath.item], withAnimation: .effectFade)
                }
            }
        }
        if let rowInserts = consolidator?.sortedRowInserts(){
            if(rowInserts.count > 0){
                for indexPath in rowInserts{
                    tableView.insertRows(at: [indexPath.item], withAnimation: .effectFade)
                }
            }
        }
        tableView.endUpdates()
        //deallocate consolidator
        consolidator = nil
        print("tableView select row before manual set: \(tableView.selectedRow)")
        print("rowToBeFocusedIndex: \(rowToBeFocusedIndex)")
        //if rowToBeFocus is -1, rowToBeFocusIndex would be nil, that would lead to stmt below unwrap nil(crash)
        if rowToBeFocusedIndex != nil{
            tableView.selectRowIndexes(rowToBeFocusedIndex as IndexSet, byExtendingSelection: false)
        }
        print("tableView select row after manual set: \(tableView.selectedRow)")
        print("tableViewEndUpdates")
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,didChange anObject: Any, at indexPath: IndexPath?,for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?){
        consolidator?.ingestItemChange(ofType: type, oldIndexPath: indexPath, newIndexPath: newIndexPath)
        print("Change type \(type) for indexPath \(String(describing: indexPath)), newIndexPath \(String(describing: newIndexPath)). Changed object: \(anObject). FRC by this moment has \(String(describing: self.fetchedResultsController.fetchedObjects?.count)) objects, tableView has \(self.tableView.numberOfRows) rows")
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
//                tableView.insertRows(at: [newIndexPath.item], withAnimation: .effectFade)
            }
        case .delete:
            if let indexPath = indexPath{
//                tableView.removeRows(at: [indexPath.item], withAnimation: .effectFade)
            }
        case .update:
            //post about sequence on 12.4 log says we shouldn't care about oldindexpath
            if let indexPath = indexPath{
                let row = indexPath.item
                for column in 0..<tableView.numberOfColumns{
                    if let cell = tableView.view(atColumn: column, row: row, makeIfNecessary: true) as? NSTableCellView{
                        tableViewDelegate.configureCell(cell: cell, row: row, column: column)
                    }
                }
            }
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath{
                tableView.removeRows(at: [indexPath.item], withAnimation: .effectFade)
                tableView.insertRows(at: [newIndexPath.item], withAnimation: .effectFade)
            }
            
        }
        copieds = fetchedResultsController.fetchedObjects
    }
}


