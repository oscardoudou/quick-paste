//
//  AppDelegate.swift
//  Quick Paste
//
//  Created by 张壹弛 on 12/24/18.
//  Copyright © 2018 张壹弛. All rights reserved.
//

import Cocoa
import CoreSpotlight

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var item : NSStatusItem? = nil
    let menu = NSMenu()
    var index = 1
    var firstTime = true
    var firstParenthesisEntry = true
    var maxCharacterSize = 255
    let preferTypes: [NSPasteboard.PasteboardType] = [NSPasteboard.PasteboardType.init("public.file-url"),NSPasteboard.PasteboardType.init("public.utf8-plain-text"),NSPasteboard.PasteboardType.init("public.png")]
    let mobileTypes: [NSPasteboard.PasteboardType] = [NSPasteboard.PasteboardType.init("iOS rich content paste pasteboard type"), NSPasteboard.PasteboardType.init("com.apple.mobilemail.attachment-ids"),NSPasteboard.PasteboardType.init("com.apple.is-remote-clipboard")]
    var timer: Timer!
    var lastChangeCount: Int = 0
    let pasteboard = NSPasteboard.general
    var dataController: DataController!
    let popover = NSPopover()
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    var viewController: ViewController! = ViewController.freshController()
    lazy var localEventMonitor : LocalEventMonitor  = LocalEventMonitor(mask: .keyDown){[weak self]
        event in
        if let strongSelf = self {
            print(strongSelf.localEventMonitor)
            strongSelf.viewController.keyDown(with: event!)
        }
        return event!
    }
    lazy var globalEventMonitor: GlobalEventMonitor = GlobalEventMonitor(mask: [.leftMouseDown, .rightMouseDown]){ [weak self]
        event in
        if let strongSelf = self, strongSelf.popover.isShown {
            print(strongSelf.globalEventMonitor)
            strongSelf.closePopover(sender: event)
        }
    }
    lazy var globalBringUpMonitor: GlobalEventMonitor = GlobalEventMonitor(mask: .keyDown){ [weak self]
        event in
        if let strongSelf = self {
            print(strongSelf.globalBringUpMonitor)
            strongSelf.viewController.keyDown(with: event!)
        }
    }
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
//         buildMenu()
        dataController = DataController()
        if let button = statusItem.button {
          button.image = NSImage(named:"paste")
          button.action = #selector(togglePopover)
        }
        //grab the view controller and pass a Persistent Container Reference to a View Controller
//        if let viewController =  ViewController.freshController() as? ViewController{
//            viewController.container = dataController.persistentContainer
            viewController.dataController = self.dataController
            popover.contentViewController =  viewController
//        }
        //url scheme
        NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(self.handleAppleEvent(event:replyEvent:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
        //add pasteboard observer/listener to notification center, center will post onPasteboardChanged when be notified
        NotificationCenter.default.addObserver(self, selector: #selector(onPasteboardChanged(_:)), name: .NSPasteBoardDidChange, object: nil)
        //the interval 0.05 0.1 doesn't help, system unlikey trigger it at precisely 0.05 0.1 second intervals, system reserve the right
        //not sure if using selector would help, so far 1 sec is somehow robust to record all the copy
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (t) in
            //print("\(self.lastChangeCount) vs \(self.pasteboard.changeCount)")
            if self.lastChangeCount != self.pasteboard.changeCount {
                self.lastChangeCount = self.pasteboard.changeCount
                //no sure when changeCount would be reset to 0 by system, better not use lastChangeCount as check
                if !self.firstTime{
                    NotificationCenter.default.post(name: .NSPasteBoardDidChange, object: self.pasteboard)
                }
                if self.firstTime{
                    self.firstTime = false
                }
            }
        }
        let defaults = UserDefaults.standard
        let defaultValue = ["maxId" : ""]
        defaults.register(defaults: defaultValue)
        globalBringUpMonitor.start()
        togglePopover(statusItem.button)
    }

    @objc func togglePopover(_ sender: Any?) {
      if popover.isShown {
        closePopover(sender: sender)
      } else {
        showPopover(sender: sender)
      }
    }

    func showPopover(sender: Any?) {
      if let button = statusItem.button {
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
      }
        localEventMonitor.start()
        globalEventMonitor.start()
    }

    func closePopover(sender: Any?) {
      popover.performClose(sender)
        localEventMonitor.stop()
        globalEventMonitor.stop()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        timer.invalidate()
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        dataController.saveContext()
    }
    

    
    //paste board changed handler
    @objc func onPasteboardChanged(_ notification: Notification){
        guard let pb = notification.object as? NSPasteboard else { return }
        guard let items = pb.pasteboardItems else { return }
        //only copy screenshot text and file, fix unsupport copy type unwrap nil crash
        if let preferType = items.first?.availableType(from: preferTypes){
            let currentDateTime = Date()
                   let dateFormatter = DateFormatter()
                   dateFormatter.timeStyle = .medium
                   let copyTimeStamp = "\(dateFormatter.string(from: currentDateTime))"
                   //for now we only log copy event, could be searchable, before introducing duplicate will leave this as unsearchable
                   print("\(copyTimeStamp) | '\(preferType)'")
                   //index copy event
                   bindIt()
        }else{
            return
        }
    }
    
    
    //status bar menu
    @objc func bindIt(){
        printPasteBoard()
        print("---------bindIt--------------")
        let items = NSPasteboard.general.pasteboardItems!
        if items.count == 0{
            print("items is: \(items)")
            return
        }
        if(firstTime){
            firstTime = false
        }
        var path: String
        var data: Data
        var title: String
        for item in items{
            //retrieve id from UserDefault which persistent after relaunch, avoid fetch multiple object associated with same id
            let defaults = UserDefaults.standard
            let id = defaults.string(forKey: "maxId") == "" ? 0 : Int(defaults.string(forKey: "maxId")!)!
            print("id in appdelegate bindIt(): \(id)")
            let preferType = item.availableType(from: preferTypes)!
            var isMobile = false
            if let mobileType = item.availableType(from: mobileTypes){
                isMobile = true
            }
            print("Prefer type is: \(preferType)")
            print("isMobile: \(isMobile)")
            if preferType.rawValue == "public.utf8-plain-text"{
                title = item.string(forType: preferType) ?? "NoText"
                //NSPasteboard.general.clearContents()
                print("plaintext is: \(title)")
                dataController.createCopied(id: id, title: title, type: preferType.rawValue, timestamp:Date(), device: isMobile == true ? "mobile" : "mac" )
            }
            else if preferType.rawValue == "public.file-url"{
                path = item.string(forType: preferType) ?? "NoPath"
                data = item.data(forType: NSPasteboard.PasteboardType.init("com.apple.icns")) ?? Data()
                title = item.string(forType: NSPasteboard.PasteboardType.init("public.utf8-plain-text")) ?? "NoFileName"
                //NSPasteboard.general.clearContents()
                print("path is: \(path)")
                dataController.createCopied(id: id, title: title, path: path, type: preferType.rawValue, data: data, timestamp:Date(), device: isMobile == true ? "mobile" : "mac")
            }
            else if preferType.rawValue == "public.png"{
                data = item.data(forType: NSPasteboard.PasteboardType.init("public.png")) ?? Data()
                let date = Date()
                let dateFormatter = DateFormatter()
                dateFormatter.timeStyle = .medium
                let timesstamp = "\(dateFormatter.string(from: date))"
                title = "Screen Shot at \(timesstamp)"
                dataController.createCopied(id: id, title: title, type: preferType.rawValue, data: data, timestamp: date, device: isMobile == true ? "mobile" : "mac")
            }
            else{
//                TODO
                print(preferType.rawValue)
            }
        }
    }
    
    
    @objc func printPasteBoard(){
        //it is possible no copy at all, so it need to be optional
        print("---------inside printPasteBoard---------")
        if let items = NSPasteboard.general.pasteboardItems{
            for item in items{
                for type in item.types{
                    print("Type: \(type)")
                    print("String: \(item.string(forType: type))")
                }
            }
        }
    }
    
    //url scheme event handler
    @objc func handleAppleEvent(event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
        if let text = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue?.removingPercentEncoding {
            if text.contains("readlog://") {
                if let indexOfSemiColon = text.firstIndex(of: ":") as String.Index?{
                    if(firstTime){
                        menu.insertItem(NSMenuItem.separator(), at: 1)
                        firstTime = false
                    }
                    let defaults = UserDefaults.standard
                    let id = defaults.string(forKey: "maxId") == "" ? 0 : Int(defaults.string(forKey: "maxId")!)!
                    print("id in appdelegate handleAppleEvent: \(id)")
                    let start = text.index(indexOfSemiColon, offsetBy: 3)
                    let end = text.endIndex
                    let paramFromCommandLine = String(text[start..<end])
                    //NSPasteboard.general.clearContents()
                    print("url scheme message is: \(paramFromCommandLine)")
                    dataController.createCopied(id: id, title: paramFromCommandLine, type: "public.utf8-plain-text", timestamp:Date())
                }
            }
        }
    }
    

    //deprecated system menu
    func buildMenu(){
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item?.button?.image = NSImage(named: "paste")
        //construct the menu
        menu.addItem(NSMenuItem(title: "Bind It", action: #selector(AppDelegate.bindIt), keyEquivalent: "b"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(AppDelegate.quit), keyEquivalent: "q"))
        //set statusItem.menu to the menu we just set
        item?.menu = menu
    }
    //legacy quit
    @objc func quit(){
        NSApplication.shared.terminate(self)
    }
}

extension NSNotification.Name{
    static let NSPasteBoardDidChange = NSNotification.Name("pasteboardDidChangeNotification")
}

extension NSImage {
    func resizedImageTo(sourceImage: NSImage, newSize: NSSize) -> NSImage?{
        if sourceImage.isValid == false {
            return nil
        }
        let representation = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(newSize.width), pixelsHigh: Int(newSize.height), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0)
        representation?.size = newSize
        
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext.init(bitmapImageRep: representation!)
        sourceImage.draw(in: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height), from: NSZeroRect, operation: .copy, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()
        
        let newImage = NSImage(size: newSize)
        newImage.addRepresentation(representation!)
        
        return newImage
    }
}
