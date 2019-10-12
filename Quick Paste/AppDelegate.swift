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
    let preferTypes: [NSPasteboard.PasteboardType] = [NSPasteboard.PasteboardType.init("public.file-url"),NSPasteboard.PasteboardType.init("public.utf8-plain-text")]
    var timer: Timer!
    var lastChangeCount: Int = 0
    let pasteboard = NSPasteboard.general
    var dataController: DataController!
    let popover = NSPopover()
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
//         buildMenu()
        dataController = DataController()
        if let button = statusItem.button {
          button.image = NSImage(named:"paste")
          button.action = #selector(togglePopover)
        }
        //grab the view controller and pass a Persistent Container Reference to a View Controller
        if let viewController =  ViewController.freshController() as? ViewController{
            viewController.container = dataController.persistentContainer
            popover.contentViewController =  viewController
        }
        //url scheme
        NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(self.handleAppleEvent(event:replyEvent:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
        //add pasteboard observer/listener to notification center, center will post onPasteboardChanged when be notified
        NotificationCenter.default.addObserver(self, selector: #selector(onPasteboardChanged(_:)), name: .NSPasteBoardDidChange, object: nil)
        //the interval 0.05 0.1 doesn't help, system unlikey trigger it at precisely 0.05 0.1 second intervals, system reserve the right
        //not sure if using selector would help, so far 1 sec is somehow robust to record all the copy
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (t) in
            if self.lastChangeCount != self.pasteboard.changeCount {
                self.lastChangeCount = self.pasteboard.changeCount
                NotificationCenter.default.post(name: .NSPasteBoardDidChange, object: self.pasteboard)
            }
        }
        let defaults = UserDefaults.standard
        let defaultValue = ["maxId" : ""]
        defaults.register(defaults: defaultValue)
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
    }

    func closePopover(sender: Any?) {
      popover.performClose(sender)
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
        guard let item = items.first?.string(forType: .string) else { return } // you should handle multiple types
        var currentDateTime = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .medium
        let copyTimeStamp = "\(dateFormatter.string(from: currentDateTime))"
        //for now we only log copy event, could be searchable, before introducing duplicate will leave this as unsearchable
        print("\(copyTimeStamp) | '\(item)'")
        //index copy event
        bindIt()
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
//            menu.insertItem(NSMenuItem.separator(), at: 1)
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
            print("Prefer type is: \(preferType)")
            if preferType.rawValue == "public.utf8-plain-text"{
                title = item.string(forType: preferType) ?? "NoText"
                //NSPasteboard.general.clearContents()
                print("plaintext is: \(title)")
                dataController.createCopied(id: id, title: title, type: preferType.rawValue, timestamp:Date())
                let newItem = createMenuItem(id: id, title: title, type: preferType.rawValue)
                let newSearchableItem = createSearhableItem(id: id, title: title, type: preferType.rawValue, data: nil)
                //addItemToMenu(item: newItem)
                indexItem(item: newSearchableItem)
            }
            else if preferType.rawValue == "public.file-url"{
                path = item.string(forType: preferType) ?? "NoPath"
                data = item.data(forType: NSPasteboard.PasteboardType.init("com.apple.icns")) ?? Data()
                title = item.string(forType: NSPasteboard.PasteboardType.init("public.utf8-plain-text")) ?? "NoFileName"
                //NSPasteboard.general.clearContents()
                print("path is: \(path)")
                dataController.createCopied(id: id, title: title, path: path, type: preferType.rawValue, data: data, timestamp:Date())
                let newItem = createMenuItem(id: id, title: title, type: preferType.rawValue, data: data)
                let newSearchableItem = createSearhableItem(id: id, title: title, type: preferType.rawValue, path: path, data: data)
                //addItemToMenu(item: newItem)
                indexItem(item: newSearchableItem)
            }
            else{
//                TODO
                print(preferType.rawValue)
            }
        }
    }
    
    @objc func createMenuItem(id: Int, title: String, type: String, data: Data = Data())->NSMenuItem{
        var newItem : NSMenuItem? = nil
        print ("\(title), \(type)")
        if type == "public.file-url" {
            newItem = NSMenuItem(title: String(title), action: #selector(AppDelegate.copyIt), keyEquivalent: "\(id%9)")
            let rawImage = NSImage(data: data)
            newItem?.image = rawImage?.resizedImageTo(sourceImage: rawImage!, newSize: NSSize.init(width: 20, height: 20))
            
        }
        if type == "public.utf8-plain-text"{
            let afterParse = parseResumeFormat(title: title)
            newItem = NSMenuItem(title: afterParse, action: #selector(AppDelegate.copyIt), keyEquivalent: "\(id%9)")
            if(afterParse == "stackoverflow"){
                newItem?.image = NSImage(named: "stackoverflow")
                newItem?.title = ""
            }
            if(afterParse == "linkedin"){
                newItem?.image = NSImage(named: "linkedin")
                newItem?.title = ""
            }
            if(afterParse == "github"){
                newItem?.image = NSImage(named: "github")
                newItem?.title = ""
            }
        }
        newItem!.representedObject = id as Int
        return newItem!
    }
    
    @objc func addItemToMenu(item: NSMenuItem){
        menu.insertItem(item, at: index + 1)
        index+=1
    }
    
    
    //spotlight searchable
    func createSearhableItem(id: Int, title: String, type: String, path: String = "", data: Data?)->CSSearchableItem{
        let searchableAttributeSet = CSSearchableItemAttributeSet.init(itemContentType: kUTTypeData as String)
        searchableAttributeSet.title = title
        searchableAttributeSet.contentDescription = title
        searchableAttributeSet.kind = type
        //currently contentURL gives thumbnail, thumbnailURL do nothing
        searchableAttributeSet.contentURL = URL.init(fileURLWithPath: path)
        searchableAttributeSet.path = URL.init(fileURLWithPath: path).path
        let searchableItem = CSSearchableItem.init(uniqueIdentifier: String(id), domainIdentifier: "", attributeSet: searchableAttributeSet)
        return searchableItem
    }
    
    func indexItem(item: CSSearchableItem){
        CSSearchableIndex.default().indexSearchableItems([item]){error in
            if let error = error {
                print("Indexing error: \(error.localizedDescription)")
            } else {
                print("Search item successfully indexed!")
            }
        }
    }
    
    
    //status bar copy
    @objc func copyIt(sender: NSMenuItem){
        print("---------copyIt--------------")
        //important step
        NSPasteboard.general.clearContents()
        let item = dataController.fetch(id: sender.representedObject as! Int)
        print ("Copied \(item.id): \(item.type)")
        NSPasteboard.general.setString(item.path!, forType: NSPasteboard.PasteboardType.init(item.type!))
//        if item.type! != "public.utf8-plain-text"{
        NSPasteboard.general.setString(item.name!, forType: NSPasteboard.PasteboardType.init("public.utf8-plain-text"))
//        }
        print(sender.representedObject as! Int)
        print("we copy entry content to pasteboard")
        printPasteBoard()
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
//        menu.addItem(NSMenuItem.separator())
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
                    let newItem = createMenuItem(id: id, title: paramFromCommandLine, type: "public.utf8-plain-text")
                    let newSearchableItem = createSearhableItem(id: id, title: paramFromCommandLine, type: "public.utf8-plain-text", data: nil)
                    //addItemToMenu(item: newItem)
                    indexItem(item: newSearchableItem)
                }
            }
        }
    }
    
    //need refactor
    @objc func parseResumeFormat(title: String)->String{
        var res = ""
        if let indexEndOfTitle = title.firstIndex(of: "(") as String.Index?{
            //get string before "("
            if(firstParenthesisEntry){
                maxCharacterSize = indexEndOfTitle.encodedOffset < maxCharacterSize ? indexEndOfTitle.encodedOffset : maxCharacterSize
                firstParenthesisEntry = false
            }
            else{
                //utilize the space as much as possible as long as it doesn't exceed ( entry's max size
                maxCharacterSize = indexEndOfTitle.encodedOffset > maxCharacterSize ? indexEndOfTitle.encodedOffset : maxCharacterSize
            }
            //            print("\(index)" + ", " + "\(maxCharacterSize)")
//            newItem = NSMenuItem(title: String(title[..<indexEndOfTitle]), action: #selector(AppDelegate.copyIt), keyEquivalent: "\(index)")
            res = String(title[..<indexEndOfTitle])
        }else{
            //no "(" present in first line, link or email
            if let indexOfAt = title.firstIndex(of: "@") as String.Index?{
                //email
                let start = title.index(indexOfAt, offsetBy: 1)
                let end = title.lastIndex(of: ".")!
                let institue = String(title[start..<end])
//                newItem = NSMenuItem(title: institue.uppercased(), action: #selector(AppDelegate.copyIt), keyEquivalent: "\(index)")
                res = institue.uppercased()
            }else{
                //only . present
                if let end = title.lastIndex(of: ".") as String.Index?{
                    //default start form startIndex
                    var start = title.startIndex
                    //point to last . since end always be the last .
                    //                let end = title.lastIndex(of: ".")!
                    //point to first .
                    let indexPossibleStartHost = title.firstIndex(of: ".")!
                    //if has http or https prefix, start from 3 offset from colon
                    if title.hasPrefix("http://")||title.hasPrefix("https://"){
                        let indexEndOfProtocol = title.firstIndex(of: ":")!
                        //point to first char after :// for link like github and leetcode
                        start = title.index(indexEndOfProtocol, offsetBy: 3)
                    }
                    if(indexPossibleStartHost.encodedOffset != end.encodedOffset){
                        //piont to first . for link like linkedin
                        start = title.index(indexPossibleStartHost, offsetBy: 1)
                    }
                    let host = String(title[start..<end])
                    print (host)
//                    newItem = NSMenuItem(title: host, action: #selector(AppDelegate.copyIt), keyEquivalent: "\(index)")
                    res = host
                }else{
                    //no . use space to separate no space simply return first element in splitted array
                    let words = title.split(separator: " ")
                    var preview = words[0]
                    print(preview.count)
                    for word in words{
                        if(word == words[0]){continue}
                        //only preview whole word never cut in the middle
                        if(preview.count + word.count < maxCharacterSize){
                            preview += word + " "
                            //                            print(preview.count)
                        }else{
                            break
                        }
                    }
//                    newItem = NSMenuItem(title: String(preview), action: #selector(AppDelegate.copyIt), keyEquivalent: "\(index)")
                    res = String(preview)
                }
            }
        }
        return res
    }
    //system menu
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
