//
//  DateController.swift
//  Quick Paste
//
//  Created by 张壹弛 on 10/5/19.
//  Copyright © 2019 张壹弛. All rights reserved.
//

import Foundation
import CoreData

public class DataController: NSObject{
    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Quick Paste")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error)")
            }
        })
        return container
    }()
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    public func createCopied(id: Int, title: String, path: String = "", type: String, data: Data = Data(), timestamp: Date){
        let copied = NSEntityDescription.insertNewObject(forEntityName: "Copied", into: context) as! Copied
        copied.id = Int64(id)
        copied.name = title
        copied.path = path
        copied.thumbnail = data
        copied.timestamp = timestamp
        copied.type = type
        print ("copied object \(copied.id) is set")
        do{
            try context.save()
            print ("✅  Copied saved successfully")
            let defaults = UserDefaults.standard
            defaults.set(String(id+1), forKey: "maxId")            
        }catch let error{
            print(" ❌ Failed to create Copied \(error.localizedDescription) ")
        }
    }
    
    public func fetch(id: Int)->Copied{
//        construct fetchRequest
        let fetchRequest = NSFetchRequest<Copied>(entityName: "Copied")
//        use predicate filter fetchRequest
        fetchRequest.predicate = NSPredicate(format: "id==%lld", Int64(id) )
        var res = NSEntityDescription.insertNewObject(forEntityName: "Copied", into: context) as! Copied
        res.id = Int64(-1)
        do{
            let copieds = try context.fetch(fetchRequest)
            print("\(copieds[0].id)")
            print("\(copieds[0].name ?? "NAME")")
            print("\(copieds[0].path)")
            print("\(copieds[0].timestamp ?? Date.init(timeIntervalSince1970: 1))")
            print("\(copieds[0].type ?? "TYPE" ) ")
            res = copieds[0]
        }catch let error{
            print(" ❌ Failed to fetch Copied: \(error)")
        }
        return res
    }
    
}


