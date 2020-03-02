//
//  Logger.swift
//  Quick Paste
//
//  Created by 张壹弛 on 2/28/20.
//  Copyright © 2020 张壹弛. All rights reserved.
//

import Cocoa
import os

class Logger: NSObject {

    enum Category: String{
        case app
        case event
        case ui
        case data
    }
    enum AccessLevel{
        //to use reserved word as identifier, wrap it with backtick
        case `private`
        case `public`
    }
    private func createOSLog(category: Category) -> OSLog{
        return OSLog(subsystem: Bundle.main.bundleIdentifier ?? "-" , category: category.rawValue)
    }
    func log(category: Logger.Category, message: String, access: Logger.AccessLevel = .private, type: OSLogType = .debug, file: String = #file, function: String = #function, line: Int = #line){
        //default file parameter to #file.basename in signature would let all log file portion showing as Looger.swift [confuse]
        let file = file.basename
        let line = String(line)
        switch access{
        case .private:
            os_log("[%{private}@:%{private}@ %{private}@] | %{private}@", log: createOSLog(category: category), type: type, file, function, line, message)
        case .public:
            os_log("[%{public}@:%{public}@ %{public}@] | %{public}@", log: createOSLog(category: category), type: type,file, function, line, message)
        }
    }
    
}
extension String{
    var fileURL: URL {
        return URL(fileURLWithPath: self)
    }
    var basename: String{
        return fileURL.lastPathComponent
    }
    public var fourCharCodeValue: Int {
      var result: Int = 0
      if let data = self.data(using: String.Encoding.macOSRoman) {
        data.withUnsafeBytes({ (rawBytes) in
          let bytes = rawBytes.bindMemory(to: UInt8.self)
          for i in 0 ..< data.count {
            result = result << 8 + Int(bytes[i])
          }
        })
      }
      return result
    }
}
