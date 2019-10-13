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

    @IBOutlet weak var SearchField: NSSearchFieldCell!
    @IBOutlet weak var tableView: NSTableView!
    var container: NSPersistentContainer!
    
    private lazy var fetchedResultsController: NSFetchedResultsController<Copied> = {
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<Copied>(entityName: "Copied")
        let nameSort = NSSortDescriptor(key: "timestamp", ascending: false)
        fetchRequest.sortDescriptors = [nameSort]
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
        tableView.delegate = self
        tableView.dataSource = self

    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
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
        print("\(fetchedResultsController.fetchedObjects?.count)")
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }
}
