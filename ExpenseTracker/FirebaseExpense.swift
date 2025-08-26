//
//  FirebaseExpense.swift
//  ExpenseTracker
//
//  Created by iMacPro on 27/06/25.
//
import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

// MARK: - Firebase Models (Simplified)
struct FirebaseExpense: Codable, Identifiable {
    @DocumentID var documentId: String?
    let id: String
    let title: String
    let amount: Double
    let category: String
    let date: Timestamp
    let notes: String
    let createdAt: Timestamp?
    let updatedAt: Timestamp?
    let isRemoved: Bool
    
    // New fields with defaults for backward compatibility
    let isLentMoney: Bool
    let lentToPersonName: String?
    let isRepaid: Bool
    let paymentModeName: String?
    
    // Initialize with defaults for missing fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        amount = try container.decode(Double.self, forKey: .amount)
        category = try container.decode(String.self, forKey: .category)
        date = try container.decode(Timestamp.self, forKey: .date)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        createdAt = try container.decodeIfPresent(Timestamp.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Timestamp.self, forKey: .updatedAt)
        isRemoved = try container.decodeIfPresent(Bool.self, forKey: .isRemoved) ?? false
        
        // New fields with defaults
        isLentMoney = try container.decodeIfPresent(Bool.self, forKey: .isLentMoney) ?? false
        lentToPersonName = try container.decodeIfPresent(String.self, forKey: .lentToPersonName)
        isRepaid = try container.decodeIfPresent(Bool.self, forKey: .isRepaid) ?? false
        paymentModeName = try container.decodeIfPresent(String.self, forKey: .paymentModeName)
    }
    
    func toExpense() -> Expense {
        var expense = Expense(
            id: UUID(uuidString: id) ?? UUID(),
            title: title,
            amount: amount,
            category: ExpenseCategory(rawValue: category) ?? .other,
            date: date.dateValue(),
            notes: notes.isEmpty ? nil : notes
        )
        
        // Explicitly set the lent money properties
        expense.isLentMoney = isLentMoney
        expense.lentToPersonName = lentToPersonName
        expense.isRepaid = isRepaid
        
        print("🔄 Converting Firebase expense: \(title) - isLentMoney: \(isLentMoney) -> \(expense.isLentMoney)")
        
        return expense
    }
}

enum FirebaseError: Error, LocalizedError {
    case notAuthenticated
    case syncFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .syncFailed(let message):
            return "Sync failed: \(message)"
        }
    }
}
