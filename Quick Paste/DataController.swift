//
//  DateController.swift
//  Quick Paste
//
//  Created by 张壹弛 on 10/5/19.
//  Copyright © 2019 张壹弛. All rights reserved.
//

import Foundation
import CoreData
import Cocoa

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
                logger.log(category: .data, message: "Unresolved error \(error)")
                fatalError("Unresolved error \(error)")
            }
        })
        return container
    }()
    //this stored property doesn't make sense, it make persistentContainer declared as lazy var no used
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    // MARK: - Core Data Saving support
    func saveContext () {
        let context = persistentContainer.viewContext
        if !context.commitEditing() {
            logger.log(category: .data, message: "\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Customize this code block to include application-specific recovery steps.
                let nserror = error as NSError
                NSApplication.shared.presentError(nserror)
                print(nserror.userInfo)
            }
        }
    }
    //path is default param(could be omit), data is optional
    public func createCopied(id: Int, title: String, path: String = "", type: String, data: Data? = nil, timestamp: Date, device: String = "mac"){
        let copied = NSEntityDescription.insertNewObject(forEntityName: "Copied", into: context) as! Copied
        copied.id = Int64(id)
        copied.name = title
        copied.path = path
        copied.thumbnail = data
        copied.timestamp = timestamp
        copied.type = type
        copied.device = device
        logger.log(category: .data, message: "copied object \(copied.id) is set")
        do{
            try context.save()
            logger.log(category: .data, message: "✅  Copied saved successfully")
            let defaults = UserDefaults.standard
            defaults.set(String(id+1), forKey: "maxId")            
        }catch let error{
            logger.log(category: .data, message: "❌ Failed to create Copied \(error.localizedDescription) ", type: .error)
        }
    }
    public func removeCopied(item: Copied){
        do{
            context.delete(item)
            logger.log(category: .data, message: "✅  Copied \(item.id) removed successfully")
        }catch let error{
            logger.log(category: .data, message: "❌ Failed to remove Copied \(error.localizedDescription) ")
        }
    }
    public func deleteAll(){
        logger.log(category: .app, message: "-------- begin delete All --------")
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Copied")
        fetchRequest.predicate = NSPredicate(format: "id>%lld", Int64(-1))
        let batchRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchRequest.resultType = NSBatchDeleteRequestResultType.resultTypeObjectIDs
        let privateMOC = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateMOC.parent = context
        privateMOC.perform(){
            do{
                let res = try privateMOC.execute(batchRequest) as? NSBatchDeleteResult
                let objectIDArray = res?.result as? [NSManagedObjectID]
//                dump(objectIDArray)
                let changes = [NSDeletedObjectsKey : objectIDArray]
//                dump(changes)
//                try privateMOC.save()
                //avoid starting with non-zero id after clear, set maxId to "" right after batchDelete execute
                let defaults = UserDefaults.standard
                defaults.set("", forKey: "maxId")
                self.context.performAndWait {
                    do{
                        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.context])
                        try self.context.save()
                    }catch let error{
                        logger.log(category: .data, message: "❌ Failed to merge changes or context on main queue fail to save: \(error)")
                    }
                }
            }catch let error{
                logger.log(category: .data, message: "❌ Failed to batch delete or private queue fail to save: \(error)")
            }
        }
        logger.log(category: .app, message: "-------- finish delete All --------")
    }
    
    public func fetch(id: Int)->Copied?{
//        construct fetchRequest
        let fetchRequest = NSFetchRequest<Copied>(entityName: "Copied")
//        use predicate filter fetchRequest
        fetchRequest.predicate = NSPredicate(format: "id==%lld", Int64(id) )
        var res:Copied?
        do{
            //even if no record fetched the result set is not nil
            let copieds = try context.fetch(fetchRequest)
            guard  copieds.count > 0 else{
                return res
            }
            print("\(copieds[0].id)")
            print("\(copieds[0].name ?? "NAME")")
            print("\(copieds[0].path ?? "PATH")")
            print("\(copieds[0].timestamp ?? Date.init(timeIntervalSince1970: 1))")
            print("\(copieds[0].type ?? "TYPE" ) ")
            res = copieds[0]
        }catch let error{
            logger.log(category: .data, message: "❌ Failed to fetch Copied: \(error)")
        }
        return res
    }
    
}


