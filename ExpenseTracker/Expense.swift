//
//  Expense.swift
//  ExpenseTracker
//
//  Created by iMacPro on 26/06/25.
//

import SwiftUI
import Foundation

import Foundation

struct Expense: Identifiable, Codable {
    var id = UUID()
    var title: String
    var amount: Double
    var category: ExpenseCategory
    var date: Date
    var notes: String?
    
    // New fields for enhanced functionality
    var isLentMoney: Bool = false
    var lentToPersonName: String?
    var isRepaid: Bool = false
    var repaidDate: Date?
    var paymentMode: PaymentMode = PaymentMode.cash
    
//    var formattedAmount: String {
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .currency
//        formatter.locale = Locale.current
//        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
//    }
    
    var formattedAmount: String {
            return amount.formattedAsCurrency()
        }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var displayTitle: String {
        if isLentMoney, let personName = lentToPersonName, !personName.isEmpty {
            let status = isRepaid ? "✅" : "⏳"
            return "\(title) \(status) (Lent to \(personName))"
        }
        return title
    }
    
    var isOutstanding: Bool {
        return isLentMoney && !isRepaid
    }
    
    // Keep your existing initializer for backward compatibility
    init(id: UUID = UUID(), title: String, amount: Double, category: ExpenseCategory, date: Date, notes: String?) {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.date = date
        self.notes = notes
        // New fields will use default values
        self.isLentMoney = false
        self.lentToPersonName = nil
        self.isRepaid = false
        self.repaidDate = nil
        self.paymentMode = PaymentMode.cash
    }
    
    // New enhanced initializer
    init(id: UUID = UUID(), title: String, amount: Double, category: ExpenseCategory, date: Date, notes: String?, isLentMoney: Bool, lentToPersonName: String?, paymentMode: PaymentMode) {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.date = date
        self.notes = notes
        self.isLentMoney = isLentMoney
        self.lentToPersonName = lentToPersonName
        self.paymentMode = paymentMode
        self.isRepaid = false
        self.repaidDate = nil
    }
}

enum ExpenseCategory: String, CaseIterable, Codable {
    case food = "Food"
    case transportation = "Transportation"
    case entertainment = "Entertainment"
    case shopping = "Shopping"
    case bills = "Bills"
    case health = "Health"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transportation: return "car.fill"
        case .entertainment: return "tv.fill"
        case .shopping: return "bag.fill"
        case .bills: return "doc.text.fill"
        case .health: return "heart.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .food: return .orange
        case .transportation: return .blue
        case .entertainment: return .purple
        case .shopping: return .pink
        case .bills: return .red
        case .health: return .green
        case .other: return .gray
        }
    }
}
