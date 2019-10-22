//
//  EventMonitor.swift
//  Quick Paste
//
//  Created by 张壹弛 on 10/19/19.
//  Copyright © 2019 张壹弛. All rights reserved.
//

import Foundation
import Cocoa

public class LocalEventMonitor{
    private var monitor: Any?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent?) -> NSEvent
    
    public init (mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent?) -> NSEvent){
        self.mask = mask
        self.handler = handler
    }
    
    deinit {
        stop()
    }
    
    public func start(){
        monitor = NSEvent.addLocalMonitorForEvents(matching: mask, handler: handler)
    }
    
    public func stop(){
        if monitor != nil {
            NSEvent.removeMonitor(monitor!)
            monitor = nil
        }
    }
}
