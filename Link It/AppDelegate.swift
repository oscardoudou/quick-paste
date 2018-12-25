//
//  AppDelegate.swift
//  Link It
//
//  Created by 张壹弛 on 12/24/18.
//  Copyright © 2018 张壹弛. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var item : NSStatusItem? = nil

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item?.button?.image = NSImage(named: "link")
//        item?.button?.title = "Link It"
//        item?.button?.action = #selector(AppDelegate.linkIt) //the menu taks precedence for the click
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Link It", action: #selector(AppDelegate.linkIt), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(AppDelegate.quit), keyEquivalent: ""))
        item?.menu = menu
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @objc func linkIt(){
        print("we will do some stuff")
        if let items = NSPasteboard.general.pasteboardItems{
            for item in items{
                for type in item.types{
                    if type.rawValue == "public.utf8-plain-text"{
                        if let url = item.string(forType: type){
//                            print(url)
                            NSPasteboard.general.clearContents()
                            var actualURL = ""
                            if url.hasPrefix("http://")||url.hasPrefix("https://"){
                                actualURL = url
                            }else{
                                actualURL = "http://\(url)"
                            }
                            //general scenario textedit, safari, udemy
                            NSPasteboard.general.setString("<a href=\"\(actualURL)\">\(url)</a>", forType: NSPasteboard.PasteboardType.init("public.html"))
                            //some scenario don't utilize html type, only recognize utf8 like chrome, leetcode
                            NSPasteboard.general.setString(url, forType: NSPasteboard.PasteboardType.init("public.utf8-plain-text"))
                        }
                    }
                }
            }
        }
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

