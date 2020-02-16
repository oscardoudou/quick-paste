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
        print("inside viewDidLoad of SplitViewController:\(self)")
        super.viewDidLoad()
        print("super is \(super.className)")
        print("after SplitViewController super.viewDidLoad")
        print("children are \(self.children)")
        // Do view setup here.
        if let viewController = viewItem.viewController as? ViewController{
            if let detailViewController = detailViewItem.viewController as? DetailViewController {
                viewController.detailViewController = detailViewController
                detailViewController.viewController = viewController
                //instead of create direct reference to tableViewDelegate, indirectly use viewController's property as tableViewDelegate is instantiated in viewController
                viewController.tableViewDelegate.detailViewController = detailViewController
                print("viewController.tableViewDelegate.detailViewController: \(viewController.tableViewDelegate.detailViewController)")
            }
        }
    }
    
}
extension NSSplitViewController {
  // MARK: Storyboard instantiation
  static func freshController() -> SplitViewController {
    //1.
    let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
     print("inside splitviewcontroller freshcontroller")
    //2.
    let identifier = NSStoryboard.SceneIdentifier("SplitViewController")
    //3.
    guard let splitViewController = storyboard.instantiateController(withIdentifier: identifier) as? SplitViewController else {
      fatalError("Why cant i find SplitViewController? - Check Main.storyboard")
    }
    print("splitViewController:\(splitViewController)")
    return splitViewController
  }
}
