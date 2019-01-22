//
//  AppDelegate.swift
//  Quick Paste
//
//  Created by 张壹弛 on 12/24/18.
//  Copyright © 2018 张壹弛. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var item : NSStatusItem? = nil
    let menu = NSMenu()
    var entry: [String] = [""]
    var index = 1
    var firstTime = true
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item?.button?.image = NSImage(named: "paste")
//        item?.button?.title = "Link It"
//        item?.button?.action = #selector(AppDelegate.linkIt) //the menu taks precedence for the click
//        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Bind It", action: #selector(AppDelegate.bindIt), keyEquivalent: "b"))
        menu.addItem(NSMenuItem.separator())
        print (menu.item(at: 1))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(AppDelegate.quit), keyEquivalent: "q"))
        item?.menu = menu
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @objc func bindIt(){
//        print("we will do some stuff")
        if(firstTime){
            menu.insertItem(NSMenuItem.separator(), at: 1)
            firstTime = false
        }
        if let items = NSPasteboard.general.pasteboardItems{
            for item in items{
                for type in item.types{
                    if type.rawValue == "public.utf8-plain-text"{
                        if let copiedContent = item.string(forType: type){
                            NSPasteboard.general.clearContents()
                            entry.append(copiedContent)
                        }
                    }
                }
            }
        }
        var newItem : NSMenuItem? = nil
        if let indexEndOfTitle = entry[index].firstIndex(of: "(") as String.Index?{
            //get string before "("
            newItem = NSMenuItem(title: String(entry[index][..<indexEndOfTitle]), action: #selector(AppDelegate.copyIt), keyEquivalent: "\(index)")
        }else{
            //no "(" present in first line, link or email
            if let indexOfAt = entry[index].firstIndex(of: "@") as String.Index?{
                //email
                let start = entry[index].index(indexOfAt, offsetBy: 1)
                let end = entry[index].lastIndex(of: ".")!
                let institue = String(entry[index][start..<end])
                newItem = NSMenuItem(title: institue.uppercased(), action: #selector(AppDelegate.copyIt), keyEquivalent: "\(index)")
            }else{
                //default start form startIndex
                var start = entry[index].startIndex
                //point to last . since end always be the last .
                let end = entry[index].lastIndex(of: ".")!
                //point to first .
                let indexPossibleStartHost = entry[index].firstIndex(of: ".")!
                //if has http or https prefix, start from 3 offset from colon
                if entry[index].hasPrefix("http://")||entry[index].hasPrefix("https://"){
                    let indexEndOfProtocol = entry[index].firstIndex(of: ":")!
                    //point to first char after :// for link like github and leetcode
                    start = entry[index].index(indexEndOfProtocol, offsetBy: 3)
                }
                if(indexPossibleStartHost.encodedOffset != end.encodedOffset){
                    //piont to first . for link like linkedin
                    start = entry[index].index(indexPossibleStartHost, offsetBy: 1)
                }
                let host = String(entry[index][start..<end])
                print (host)
                newItem = NSMenuItem(title: host, action: #selector(AppDelegate.copyIt), keyEquivalent: "\(index)")
                if(host == "stackoverflow"){
                    newItem?.image = NSImage(named: "stackoverflow")
                    newItem?.title = ""
                }
                if(host == "linkedin"){
                    newItem?.image = NSImage(named: "linkedin")
                    newItem?.title = ""
                }
                if(host == "github"){
                    newItem?.image = NSImage(named: "github")
                    newItem?.title = ""
                }
            }

        }
        newItem!.representedObject = index as Int
        menu.insertItem(newItem!, at: index + 1)
        index+=1
    }
    
    @objc func copyIt(sender: NSMenuItem){
        print("---------copyIt--------------")
        NSPasteboard.general.setString(entry[sender.representedObject as! Int], forType: NSPasteboard.PasteboardType.init("public.utf8-plain-text"))
        print("we copy entry content to pasteboard")
        printPasteBoard()
    }
    
    @objc func printPasteBoard(){
        //it is possible no copy at all, so it need to be optional
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
}

