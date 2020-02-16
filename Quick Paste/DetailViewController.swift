//
//  DetailViewController.swift
//  Quick Paste
//
//  Created by 张壹弛 on 1/2/20.
//  Copyright © 2020 张壹弛. All rights reserved.
//

import Cocoa

class DetailViewController: NSViewController {
    //both viewController and copied need to be reference outside the class, so can't be private
    var viewController: ViewController!
    var copied: Copied!
    private var scrollView: NSScrollView!
    private var imageView:NSImageView!
    private var textView:NSTextView!
    
    override func viewDidLoad() {
        print("inside viewDidLoad of DetailViewController:\(self)")
        super.viewDidLoad()
        print("super is \(super.className)")
        print("after DetailViewController super.viewDidLoad")
        print("children are \(self.children)")
//         Do view setup here.
        imageView = NSImageView()
        textView = NSTextView()
        scrollView = NSScrollView()
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.autoresizingMask = .width
        textView.isVerticallyResizable = true
        textView.textContainer?.widthTracksTextView = true

        let DefaultAttribute =
        [NSAttributedString.Key.foregroundColor: NSColor.textColor] as [NSAttributedString.Key: Any]
        let attributeString = NSAttributedString(string: "hello world", attributes: DefaultAttribute)
//        textView.textStorage?.append(attributeString)
        textView.textStorage?.setAttributedString(attributeString)

        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = textView

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        print("view:\(view.subviews)")
        var testScrollView: NSScrollView = view.subviews[0] as! NSScrollView
        print("testScrollView.documentView: \(testScrollView.documentView)")
    }
//    static func freshController() -> DetailViewController {
//      //1.
//      let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
//        print("inside detailviewcontroller freshcontroller")
//      //2.
//      let identifier = NSStoryboard.SceneIdentifier("DetailViewController")
//      //3.use this controller class as casting type, not ViewController !!
//      guard let detailviewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? DetailViewController else {
//        fatalError("Why cant i find detailViewController? - Check Main.storyboard")
//      }
//    print("detailviewcontroller:\(detailviewcontroller)")
//      return detailviewcontroller
//    }
    
    func getCopiedFromLeft(){
        print("inside getCopiedFromLeft():")
        print("copied: \(copied)")
    }
    
    func showImageDetail(){
        if(copied != nil){
            var imageRect: NSRect
            imageView.image = NSImage(data: copied.thumbnail!)
            imageRect = NSMakeRect(0.0, 0.0, imageView.image!.size.width, imageView.image!.size.height)
            imageView.setFrameSize(CGSize(width: imageRect.width, height: imageRect.height))
            imageView.imageScaling = NSImageScaling.scaleNone
            scrollView.documentView = imageView
        }
    }
    
    func showTextDetail(){
        if(copied != nil){
//            textView = NSTextView(frame: <#T##NSRect#>, textContainer: <#T##NSTextContainer?#>)
            let DefaultAttribute =
            [NSAttributedString.Key.foregroundColor: NSColor.textColor] as [NSAttributedString.Key: Any]
            let attributeString = NSAttributedString(string: copied.name!, attributes: DefaultAttribute)
//            textView.textStorage?.append(attributeString)
//            textView.string = copied.name!
            textView.textStorage?.setAttributedString(attributeString)
            //no need set again
            scrollView.documentView = textView
        }
    }
    
}
