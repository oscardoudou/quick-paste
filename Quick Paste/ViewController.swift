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
    var container: NSPersistentContainer!
    //store managedObject array of current view
    var copieds : [Copied]?
    var fetchPredicate : NSPredicate? {
        didSet {
            fetchedResultsController.fetchRequest.predicate = fetchPredicate
        }
    }
    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    private lazy var fetchedResultsController: NSFetchedResultsController<Copied> = {
        let context = container.viewContext
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard container != nil else{
            fatalError("This view need a persistent container")
        }
        // Do any additional setup after loading the view.
        do{
            try fetchedResultsController.performFetch()
        }catch{
            fatalError("Failed to fecth entites: \(error)")
        }
        copieds = fetchedResultsController.fetchedObjects
        tableView.delegate = self
        tableView.dataSource = self
        searchField.delegate = self
        tableView.action = #selector(copyOnSelect)
        print("AXIsProcessTrusted(): \(AXIsProcessTrusted())")
        NSEvent.addLocalMonitorForEvents(matching: .keyDown){
            self.keyDown(with: $0)
            return $0
        }
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
        NSPasteboard.general.setString(item.path!, forType: NSPasteboard.PasteboardType.init(item.type!))
        NSPasteboard.general.setString(item.name!, forType: NSPasteboard.PasteboardType.init("public.utf8-plain-text"))
        }
        print("we copy entry content to pasteboard")
        appDelegate.printPasteBoard()
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
        NSApplication.shared.terminate(self)
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
        tableView.beginUpdates()
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>){
        tableView.endUpdates()
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,didChange anObject: Any, at indexPath: IndexPath?,for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?){
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath.item], withAnimation: .effectFade)
            }
        case .delete:
            if let indexPath = indexPath{
                tableView.removeRows(at: [indexPath.item], withAnimation: .effectFade)
            }
        case .update:
            if let indexPath = indexPath{
                let row = indexPath.item
                for column in 0..<tableView.numberOfColumns{
                    if let cell = tableView.view(atColumn: column, row: row, makeIfNecessary: true) as? NSTableCellView{
                        configureCell(cell: cell, row: row, column: column)
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
extension ViewController: NSTableViewDelegate {
    // 2/2 have to implement function to show core data in table view
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var cellIdentifier: String = ""
        var cell: NSTableCellView!
        //probably should guard
        let copied :Copied = fetchedResultsController.fetchedObjects![row]
        let column = tableView.tableColumns.firstIndex(of: tableColumn!)!
        switch column{
        case 0:
            cellIdentifier = "NameCellId"
        case 1:
            cellIdentifier = "TimeCellId"
        case 2:
            cellIdentifier = "OtherCellId"
        default:
            return nil
        }
        cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView
        configureCell(cell: cell, row: row, column: column)
        return cell
    }
    private func configureCell(cell: NSTableCellView, row: Int, column: Int){
        var image: NSImage?
        var name: String?
        var time: String?
        var other: String?
        var text: String?
        let dateFormatter = DateFormatter()
        let copied = fetchedResultsController.fetchedObjects![row]
        switch column {
        case 0:
            image = copied.thumbnail != nil ? NSImage(data: copied.thumbnail!) : NSImage(named: "stackoverflow")
            name = copied.name
            text = name
        case 1:
            dateFormatter.timeStyle = .medium
            time = copied.timestamp != nil ? dateFormatter.string(from: copied.timestamp!) : "notime"
            text = time
        case 2:
            other = String(copied.id)
            text = other
        default:
            break
        }
        cell.textField?.stringValue = text != nil ? text! : "default"
        //we have a surprising bug: if text copied, even default stackoverflow image won't be set.The image would be blank, but next time you open if will show up
        cell.imageView?.image = image ?? nil
    }
}

extension ViewController: NSTableViewDataSource{
    // 1/2 have to implement function to show core data in table view
    func numberOfRows(in tableView: NSTableView) -> Int {
        let count = fetchedResultsController.fetchedObjects?.count
        print("Number of Rows: \(count)")
        return count ?? 0
    }
}
