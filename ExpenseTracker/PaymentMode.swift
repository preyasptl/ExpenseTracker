//
//  PaymentMode.swift
//  ExpenseTracker
//
//  Created by iMacPro on 27/06/25.
//
import Foundation
import SwiftUICore

// MARK: - Payment Mode Model
struct PaymentMode: Identifiable, Codable, Hashable {
    let id = UUID()
    var name: String
    var icon: String
    var color: String // Store as hex string for consistency
    var isDefault: Bool = false
    
    // Computed property for SwiftUI Color
    var swiftUIColor: Color {
        Color(hex: color) ?? .blue
    }
    
    init(name: String, icon: String, color: String, isDefault: Bool = false) {
        self.name = name
        self.icon = icon
        self.color = color
        self.isDefault = isDefault
    }
}

// MARK: - Default Payment Modes
extension PaymentMode {
    static let cash = PaymentMode(name: "Cash", icon: "banknote", color: "#4CAF50", isDefault: true)
    static let creditCard = PaymentMode(name: "Credit Card", icon: "creditcard", color: "#2196F3")
    static let debitCard = PaymentMode(name: "Debit Card", icon: "creditcard.fill", color: "#FF9800")
    static let netBanking = PaymentMode(name: "Net Banking", icon: "building.columns", color: "#9C27B0")
    static let upi = PaymentMode(name: "UPI", icon: "qrcode", color: "#E91E63")
    static let wallet = PaymentMode(name: "Digital Wallet", icon: "wallet.pass", color: "#00BCD4")
    
    static let defaultModes: [PaymentMode] = [
        .cash, .creditCard, .debitCard, .netBanking, .upi, .wallet
    ]
}
