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
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item?.button?.image = NSImage(named: "paste")
//        item?.button?.title = "Link It"
//        item?.button?.action = #selector(AppDelegate.linkIt) //the menu taks precedence for the click
//        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Bind It", action: #selector(AppDelegate.bindIt), keyEquivalent: "b"))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(AppDelegate.quit), keyEquivalent: "q"))
//        print (menu.item(at: 1))
        item?.menu = menu
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @objc func bindIt(){
        print("we will do some stuff")
//        var entry = ""
        if let items = NSPasteboard.general.pasteboardItems{
            for item in items{
                for type in item.types{
                    if type.rawValue == "public.utf8-plain-text"{
                        if let copiedContent = item.string(forType: type){
//                            print(url)
                            NSPasteboard.general.clearContents()
//                            if url.hasPrefix("http://")||url.hasPrefix("https://"){
//                                actualURL = url
//                            }else{
//                                actualURL = "http://\(url)"
//                            }
                            entry.append(copiedContent)
                            
//                            //general scenario textedit, safari, udemy
//                            NSPasteboard.general.setString("<a href=\"\(actualURL)\">\(url)</a>", forType: NSPasteboard.PasteboardType.init("public.html"))
//                            //some scenario don't utilize html type, only recognize utf8 like chrome, leetcode
//                            NSPasteboard.general.setString(url, forType: NSPasteboard.PasteboardType.init("public.utf8-plain-text"))
//                            NSPasteboard.general.setString(entry, forType: NSPasteboard.PasteboardType.init("public.utf8-plain-text"))
                        }
                    }
                }
            }
        }
        let indexEndOfTitle = entry[index].firstIndex(of: "(")!
        //get string before "("
        let newItem = NSMenuItem(title: String(entry[index][..<indexEndOfTitle]), action: #selector(AppDelegate.copyIt), keyEquivalent: "\(index)")
        //menu.insertItem(withTitle: String(entry[index][...indexEndOfTitle]), action: #selector(AppDelegate.copyIt), keyEquivalent: "", at: 2)
        newItem.representedObject = index as Int
        menu.insertItem(newItem, at: index + 1)
        index+=1
//        printPasteBoard()
    }
    
    @objc func copyIt(sender: NSMenuItem){
        print("---------copyIt--------------")
//        NSPasteboard.general.setString(entry[index], forType: NSPasteboard.PasteboardType.init("public.utf8-plain-text"))
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

