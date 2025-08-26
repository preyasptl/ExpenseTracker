//
//  CDExpense.swift
//  ExpenseTracker
//
//  Created by iMacPro on 27/06/25.
//


import CoreData
import Foundation

@objc(CDExpense)
public class CDExpense: NSManagedObject {
    
}


extension CDExpense {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDExpense> {
        return NSFetchRequest<CDExpense>(entityName: "CDExpense")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var amount: Double
    @NSManaged public var category: String?
    @NSManaged public var date: Date?
    @NSManaged public var notes: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var isRemoved: Bool
    @NSManaged public var firebaseId: String?
    @NSManaged public var lastSyncedAt: Date?
    @NSManaged public var needsSync: Bool
    @NSManaged public var isLentMoney: Bool
    @NSManaged public var lentToPersonName: String?
    @NSManaged public var isRepaid: Bool
    @NSManaged public var repaidDate: Date?
    
}

// Convenience methods
extension CDExpense {
    var wrappedId: UUID {
        id ?? UUID()
    }
    
    var wrappedTitle: String {
        title ?? "Unknown Expense"
    }
    
    var wrappedCategory: String {
        category ?? "other"
    }
    
    var wrappedDate: Date {
        date ?? Date()
    }
    
    var expenseCategory: ExpenseCategory {
        ExpenseCategory(rawValue: wrappedCategory) ?? .other
    }
    
    func toExpense() -> Expense {
        var expense = Expense(
            id: wrappedId,
            title: wrappedTitle,
            amount: amount,
            category: expenseCategory,
            date: wrappedDate,
            notes: notes
        )
        expense.isLentMoney = isLentMoney
        expense.lentToPersonName = lentToPersonName
        expense.isRepaid = isRepaid
        expense.repaidDate = repaidDate
        return expense
    }
    
    func updateFromExpense(_ expense: Expense) {
        self.id = expense.id
        self.title = expense.title
        self.amount = expense.amount
        self.category = expense.category.rawValue
        self.date = expense.date
        self.notes = expense.notes
        self.updatedAt = Date()
        self.needsSync = true
        // New fields
        self.isLentMoney = expense.isLentMoney
        self.lentToPersonName = expense.lentToPersonName
        self.isRepaid = expense.isRepaid
        self.repaidDate = expense.repaidDate
    }
}
