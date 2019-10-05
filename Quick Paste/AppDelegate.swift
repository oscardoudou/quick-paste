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
    var titles: [String] = []
    var entry: [String] = []
    var types: [String] = []
    var icons: [Data] = []
    var index = 1
    var firstTime = true
    var firstParenthesisEntry = true
    var maxCharacterSize = 255
    let preferTypes: [NSPasteboard.PasteboardType] = [NSPasteboard.PasteboardType.init("public.file-url"),NSPasteboard.PasteboardType.init("public.utf8-plain-text")]
    var timer: Timer!
    var lastChangeCount: Int = 0
    let pasteboard = NSPasteboard.general
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item?.button?.image = NSImage(named: "paste")
        menu.addItem(NSMenuItem(title: "Bind It", action: #selector(AppDelegate.bindIt), keyEquivalent: "b"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(AppDelegate.quit), keyEquivalent: "q"))
        item?.menu = menu
        NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(self.handleAppleEvent(event:replyEvent:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
        NotificationCenter.default.addObserver(self, selector: #selector(onPasteboardChanged(_:)), name: .NSPasteBoardDidChange, object: nil)
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { (t) in
            if self.lastChangeCount != self.pasteboard.changeCount {
                self.lastChangeCount = self.pasteboard.changeCount
                NotificationCenter.default.post(name: .NSPasteBoardDidChange, object: self.pasteboard)
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @objc func bindIt(){
        print("---------bindIt--------------")
        let items = NSPasteboard.general.pasteboardItems!
        if items.count == 0{
            print("items is: \(items)")
            return
        }
        for item in items{
            print(item)
            for type in item.types{
                print ("\(type.rawValue): \(item.data(forType: kUTTypeAppleICNS as NSPasteboard.PasteboardType))")
                print ("\(type.rawValue): \(item.data(forType: type))")
                print ("\(type.rawValue): \(item.propertyList(forType: type))")
            }
            let preferType = item.availableType(from: preferTypes)!
            print(preferType)
            if preferType.rawValue == "public.utf8-plain-text"{
                if let copiedContent = item.string(forType: preferType){
                    //important step
                    NSPasteboard.general.clearContents()
                    print("plaintext is: \(copiedContent)")
                    titles.append(copiedContent)
                    entry.append(copiedContent)
                    //store empty data for utf8 for now
                    icons.append(Data())
                    types.append(preferType.rawValue)
                }
            }
            else if preferType.rawValue == "public.file-url"{
                if let path = item.string(forType: preferType){
                    if let data = item.data(forType: NSPasteboard.PasteboardType.init("com.apple.icns")){
                        icons.append(data)
                    }
                    if let title = item.string(forType: NSPasteboard.PasteboardType.init("public.utf8-plain-text")){
                        titles.append(title)
                    }
                    //important step
                    NSPasteboard.general.clearContents()
                    print("path is: \(path)")
                    entry.append(path)
                    types.append(preferType.rawValue)
                }
            }
            else{
//                TODO
                print(preferType.rawValue)
            }
//                for data in item.data{
//                    print (data.rawValue)
//                }
        }
        
        if(firstTime){
            menu.insertItem(NSMenuItem.separator(), at: 1)
            firstTime = false
        }
        
        let newItem = createMenuItem(title: titles[index-1], type: types[index-1])
        addItemToMenu(item: newItem)
        
    }
    
    @objc func createMenuItem(title: String, type: String)->NSMenuItem{
        var newItem : NSMenuItem? = nil
        print ("\(title), \(type)")
        if type == "public.file-url" {
            newItem = NSMenuItem(title: String(title), action: #selector(AppDelegate.copyIt), keyEquivalent: "\(index)")
            //too large
            //newItem?.image = NSImage(data: icons[index-1])
            let rawImage = NSImage(data: icons[index-1])
            newItem?.image = rawImage?.resizedImageTo(sourceImage: rawImage!, newSize: NSSize.init(width: 20, height: 20))
            
        }
        if type == "public.utf8-plain-text"{
            let afterParse = parseResumeFormat(title: title)
            newItem = NSMenuItem(title: afterParse, action: #selector(AppDelegate.copyIt), keyEquivalent: "\(index)")
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
        newItem!.representedObject = index - 1 as Int
        return newItem!
    }
    
    @objc func addItemToMenu(item: NSMenuItem){
        indexItem(item: createSearhableItem(index-1))
        menu.insertItem(item, at: index + 1)
        index+=1
    }
    
    @objc func copyIt(sender: NSMenuItem){
        print("---------copyIt--------------")
        //important step
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(entry[sender.representedObject as! Int], forType: NSPasteboard.PasteboardType.init(types[sender.representedObject as! Int]))
        // avoid after clicking a file, the original utf8 wouldn't present in pasteboard as we only need url to refer the file,
        // but this would lead to titles array index out of range when binding it again using item itself(which only have url type no more utf8 type)
        if types[sender.representedObject as! Int] != "public.utf8-plain-text"{
            NSPasteboard.general.setString(titles[sender.representedObject as! Int], forType: NSPasteboard.PasteboardType.init("public.utf8-plain-text"))
        }
        print(sender.representedObject as! Int)
        print("we copy entry content to pasteboard")
        printPasteBoard()
    }
    
    @objc func printPasteBoard(){
        //it is possible no copy at all, so it need to be optional
        print("inside printPasteBoard")
        if let items = NSPasteboard.general.pasteboardItems{
            for item in items{
                for type in item.types{
                    print("Type: \(type)")
                    print("String: \(item.string(forType: type))")
                }
            }
        }
    }
    
    @objc func quit(){
        NSApplication.shared.terminate(self)
    }

    @objc func handleAppleEvent(event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
//        menu.addItem(NSMenuItem.separator())
        if let text = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue?.removingPercentEncoding {
            if text.contains("readlog://") {
                if let indexOfSemiColon = text.firstIndex(of: ":") as String.Index?{
                    if(firstTime){
                        menu.insertItem(NSMenuItem.separator(), at: 1)
                        firstTime = false
                    }
                    let start = text.index(indexOfSemiColon, offsetBy: 3)
                    let end = text.endIndex
                    let paramFromCommandLine = String(text[start..<end])
                    NSPasteboard.general.clearContents()
                    print("url scheme message is: \(paramFromCommandLine)")
                    entry.append(paramFromCommandLine)
                    titles.append(paramFromCommandLine)
                    types.append("public.utf8-plain-text")
                    icons.append(Data())
                    addItemToMenu(item: createMenuItem(title: titles[index-1], type: types[index-1]))
                    NSPasteboard.general.setString(paramFromCommandLine, forType: NSPasteboard.PasteboardType.init("public.utf8-plain-text"))
                }
            }
        }
    }
    
    @objc func onPasteboardChanged(_ notification: Notification){
        guard let pb = notification.object as? NSPasteboard else { return }
        guard let items = pb.pasteboardItems else { return }
        guard let item = items.first?.string(forType: .string) else { return } // you should handle multiple types
        var currentDateTime = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .medium
        let copyTimeStamp = "\(dateFormatter.string(from: currentDateTime))"
        //for now we only log copy event, later would be searchable, but definitely not auto bind to menu
        //show log your iphone or ipad's paste as well thanks cross device paste, which means iphone's copy history could be searched once we make copy event searchable
        print("\(copyTimeStamp) | '\(item)'")
        indexItem(item: createSearhableItem(item, copyTimeStamp))
        
    }
    
    func createSearhableItem(_ title: String, _ timestamp: String)->CSSearchableItem{
        let searchableAttributeSet = CSSearchableItemAttributeSet.init(itemContentType: kUTTypeData as String)
        searchableAttributeSet.title = title
        searchableAttributeSet.contentDescription = timestamp
        searchableAttributeSet.kind = "public.utf8-plain-text"
        let searchableItem = CSSearchableItem.init(uniqueIdentifier: nil, domainIdentifier: "", attributeSet: searchableAttributeSet)
        return searchableItem
    }
    
    func createSearhableItem(_ index: Int)->CSSearchableItem{
        let searchableAttributeSet = CSSearchableItemAttributeSet.init(itemContentType: kUTTypeData as String)
        searchableAttributeSet.title = titles[index]
        searchableAttributeSet.contentDescription = entry[index]
        searchableAttributeSet.kind = types[index]
        //thumbnail available only for png pdf JPEG(without extension)
        //currently contentURL gives png thumbnail, thumbnailURL do nothing
        searchableAttributeSet.contentURL = URL.init(fileURLWithPath: entry[index])
//        searchableAttributeSet.thumbnailURL = URL.init(fileURLWithPath: entry[index])
        //path not showable when hold command
//        print("path converted from url: \(URL.init(fileURLWithPath: entry[index]).path)")
        searchableAttributeSet.path = URL.init(fileURLWithPath: entry[index]).path
        let indexEndOfColon = entry[index].firstIndex(of: ":")!
        let start = entry[index].index(indexEndOfColon, offsetBy: 3)
        print("path extract from url: \(String(entry[index][start...]))")
        searchableAttributeSet.path = String(entry[index][start...])
//        searchableAttributeSet.contentURL = URL.init(fileURLWithPath: String(entry[index][start...]))
        let searchableItem = CSSearchableItem.init(uniqueIdentifier: String(index), domainIdentifier: "", attributeSet: searchableAttributeSet)
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
