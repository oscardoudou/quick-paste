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
    
}
extension ViewController: NSTableViewDelegate {
    // 2/2 have to implement function to show core data in table view
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var image: NSImage?
        var name: String?
        var time: String?
        var other: String?
        var text: String?
        var cellIdentifier: String = ""
        let dateFormatter = DateFormatter()
        //probably should guard
        let copied :Copied = fetchedResultsController.fetchedObjects![row]
        if tableColumn == tableView.tableColumns[0]{
//            image = NSImage(data: copied.thumbnail!)
            image = copied.thumbnail != nil ? NSImage(data: copied.thumbnail!) : NSImage(named: "stackoverflow")
            name = copied.name
            text = name
            cellIdentifier = "NameCellId"
        }else if (tableColumn == tableView.tableColumns[1]){
            dateFormatter.timeStyle = .medium
            time = copied.timestamp != nil ? dateFormatter.string(from: copied.timestamp!) : "notime"
            text = time
            cellIdentifier = "TimeCellId"
        }else if(tableColumn == tableView.tableColumns[2]){
            other = String(copied.id)
            text = other
            cellIdentifier = "OtherCellId"
        }
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView{
            cell.textField?.stringValue = text != nil ? text! : "default"
            cell.imageView?.image = image ?? nil
            return cell
        }
        return nil
    }
}

extension ViewController: NSTableViewDataSource{
    // 1/2 have to implement function to show core data in table view
    func numberOfRows(in tableView: NSTableView) -> Int {
        print("\(fetchedResultsController.fetchedObjects?.count)")
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }
}
