//
//  SplitViewController.swift
//  Quick Paste
//
//  Created by 张壹弛 on 1/2/20.
//  Copyright © 2020 张壹弛. All rights reserved.
//

import Cocoa

class SplitViewController: NSSplitViewController {
    @IBOutlet weak var viewItem: NSSplitViewItem!
    @IBOutlet weak var detailViewItem: NSSplitViewItem!
    override func viewDidLoad() {
        logger.log(category: .ui, message: "inside viewDidLoad of SplitViewController:\(self)")
        super.viewDidLoad()
        logger.log(category: .ui, message: "super is \(super.className)")
        logger.log(category: .ui, message: "after SplitViewController super.viewDidLoad")
        logger.log(category: .ui, message: "children are \(self.children)")
        // Do view setup here.
        if let viewController = viewItem.viewController as? ViewController{
            if let detailViewController = detailViewItem.viewController as? DetailViewController {
                viewController.detailViewController = detailViewController
                detailViewController.viewController = viewController
                //instead of create direct reference to tableViewDelegate, indirectly use viewController's property as tableViewDelegate is instantiated in viewController
                viewController.tableViewDelegate.detailViewController = detailViewController
                logger.log(category: .app, message: "viewController.tableViewDelegate.detailViewController: \(String(describing: viewController.tableViewDelegate.detailViewController))")
            }
        }
    }
    
}
extension NSSplitViewController {
  // MARK: Storyboard instantiation
  static func freshController() -> SplitViewController {
    //1.
    logger.log(category: .app, message: "instantiating Main storyboard")
    let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
    //2.
    logger.log(category: .app, message: "instantiating SplitViewController")
    let identifier = NSStoryboard.SceneIdentifier("SplitViewController")
    //3.
    guard let splitViewController = storyboard.instantiateController(withIdentifier: identifier) as? SplitViewController else {
        logger.log(category: .app, message: "Why cant i find SplitViewController? - Check Main.storyboard", type: .error)
      fatalError("Why cant i find SplitViewController? - Check Main.storyboard")
    }
    logger.log(category: .app, message: "\(splitViewController) is instantiated")
    return splitViewController
  }
}
