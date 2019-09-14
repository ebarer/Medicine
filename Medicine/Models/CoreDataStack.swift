//
//  CoreDataStack.swift
//
//
//  Created by Fernando Rodríguez Romero on 21/02/16.
//  Copyright © 2016 udacity.com. All rights reserved.
//

import CoreData

// MARK: - CoreDataStack

struct CoreDataStack {
    
    // MARK: Properties
    
    private let model: NSManagedObjectModel
    internal let coordinator: NSPersistentStoreCoordinator
    private let modelURL: URL
    internal let dbURL: URL
    internal let persistingContext: NSManagedObjectContext
    internal let backgroundContext: NSManagedObjectContext
    let context: NSManagedObjectContext
    
    // MARK: Initializers
    
    init?() {
        // Assumes the model is in the main bundle
        guard let modelURL = Bundle.main.url(forResource: "Medicine", withExtension: "momd") else {
            NSLog("CoreData", "Unable to find DataModel in the main bundle")
            return nil
        }
        self.modelURL = modelURL
        
        // Try to create the model from the URL
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            abort()
        }
        
        self.model = model
        
        // Create the store coordinator
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        // Create a persistingContext (private queue) and a child one (main queue)
        // create a context and add connect it to the coordinator
        persistingContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        persistingContext.persistentStoreCoordinator = coordinator
        persistingContext.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.overwriteMergePolicyType)
        
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = persistingContext
        context.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        
        // Create a background context child of main context
        backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.parent = context
        
        // Add a SQLite store located in the documents folder
        let fm = FileManager.default
        
        guard let docUrl = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.com.ebarer.Medicine") else {
            NSLog("CoreData", "Unable to reach the documents folder")
            return nil
        }
        
        self.dbURL = docUrl.appendingPathComponent("Medicine.sqlite")
        
        // Create database backup
        let copyURL = docUrl.appendingPathComponent("Medicine-Backup.sqlite")
        if fm.fileExists(atPath: copyURL.absoluteString) == false {
            _ = try? fm.copyItem(at: self.dbURL, to: copyURL)
        }
        
        // Options for migration
        let options = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true
        ]
        
        do {
            try addStoreCoordinator(NSSQLiteStoreType,
                                    configuration: nil,
                                    storeURL: dbURL,
                                    options: options as [NSObject : AnyObject])
            
            NSLog("CoreData", "Opened store at: \(dbURL)")
        } catch {
            NSLog("CoreData", "Unable to add store at: \(dbURL)")
        }
    }
    
    // MARK: Utils
    
    func addStoreCoordinator(_ storeType: String, configuration: String?, storeURL: URL, options : [NSObject:AnyObject]?) throws {
        try coordinator.addPersistentStore(ofType: storeType, configurationName: configuration, at: storeURL, options: options)
    }
}

// MARK: - CoreDataStack (Migrating and Removing Data)

internal extension CoreDataStack  {
    func dropAllData() -> Bool {
        return false
    }
}

// MARK: - CoreDataStack (Batch Processing in the Background)

extension CoreDataStack {
    typealias Batch = (_ workerContext: NSManagedObjectContext) -> ()
    
    func performBackgroundBatchOperation(_ batch: @escaping Batch) {
        backgroundContext.perform() {
            batch(self.backgroundContext)
            
            do {
                try self.backgroundContext.save()
            } catch {
                NSLog("CoreData", "Unable to save background context: \(error)")
            }
        }
    }
}

// MARK: - CoreDataStack (Save Data)

extension CoreDataStack {
    func save() {
        // We call this synchronously, but it's a very fast
        // operation (it doesn't hit the disk). We need to know
        // when it ends so we can call the next save (on the persisting
        // context). This last one might take some time and is done
        // in a background queue
        context.performAndWait() {
            if self.context.hasChanges {
                do {
                    try self.context.save()
                } catch {
                    NSLog("CoreData", "Unable to save synchronous (main) context: \(error)")
                }
                
                // now we save in the background
                self.persistingContext.perform() {
                    do {
                        try self.persistingContext.save()
                        NSLog("CoreData", "Succesfully save persistent context")
                    } catch {
                        NSLog("CoreData", "Error while saving persistent context: \(error)")
                    }
                }
            }
        }
    }
}

