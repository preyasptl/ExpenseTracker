//
//  PersistenceController.swift
//  ExpenseTracker
//
//  Created by iMacPro on 27/06/25.
//


import CoreData
import Foundation

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    
    lazy var container: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "ExpenseModel")
        
        // Configure for CloudKit sync (optional - enhances Core Data with iCloud sync)
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber,
                                                               forKey: NSPersistentHistoryTrackingKey)
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber,
                                                               forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print("Core Data error: \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Save error: \(error)")
            }
        }
    }
    
    // MARK: - Preview Data
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        
        // Create sample data for previews
        let sampleExpense = CDExpense(context: context)
        sampleExpense.id = UUID()
        sampleExpense.title = "Coffee"
        sampleExpense.amount = 4.50
        sampleExpense.category = "food"
        sampleExpense.date = Date()
        sampleExpense.notes = "Morning coffee"
        sampleExpense.createdAt = Date()
        sampleExpense.updatedAt = Date()
        sampleExpense.isRemoved = false
        
        try? context.save()
        return controller
    }()
    
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "ExpenseModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
