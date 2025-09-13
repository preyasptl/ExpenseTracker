//
//  CurrencyManager.swift
//  ExpenseTracker
//
//  Created by iMacPro on 09/09/25.
//


import SwiftUI
import Foundation

// MARK: - Currency Manager for App-wide Currency Handling
class CurrencyManager: ObservableObject {
    static let shared = CurrencyManager()
    
    var currentLocale: Locale {
        return selectedCurrency.locale
    }
    
    @Published var selectedCurrency: Currency {
        didSet {
            UserDefaults.standard.set(selectedCurrency.code, forKey: "selectedCurrency")
        }
    }
    
    private init() {
        let savedCurrencyCode = UserDefaults.standard.string(forKey: "selectedCurrency") ?? "USD"
        self.selectedCurrency = Currency.allCurrencies.first { $0.code == savedCurrencyCode } ?? .usd
    }
    
    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = selectedCurrency.code
        formatter.locale = selectedCurrency.locale
        return formatter.string(from: NSNumber(value: amount)) ?? "\(selectedCurrency.symbol)\(amount)"
    }
    
    func formatCurrencyShort(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = selectedCurrency.code
        formatter.locale = selectedCurrency.locale
        formatter.maximumFractionDigits = 0
        
        if amount >= 1000 {
            let thousands = amount / 1000
            return "\(selectedCurrency.symbol)\(Int(thousands))K"
        }
        return formatter.string(from: NSNumber(value: amount)) ?? "\(selectedCurrency.symbol)\(Int(amount))"
    }
}

// MARK: - Currency Model
struct Currency: Identifiable, Equatable {
    let id = UUID()
    let code: String
    let name: String
    let symbol: String
    let locale: Locale
    
    static let allCurrencies: [Currency] = [
        Currency(code: "USD", name: "US Dollar", symbol: "$", locale: Locale(identifier: "en_US")),
        Currency(code: "EUR", name: "Euro", symbol: "€", locale: Locale(identifier: "de_DE")),
        Currency(code: "GBP", name: "British Pound", symbol: "£", locale: Locale(identifier: "en_GB")),
        Currency(code: "JPY", name: "Japanese Yen", symbol: "¥", locale: Locale(identifier: "ja_JP")),
        Currency(code: "INR", name: "Indian Rupee", symbol: "₹", locale: Locale(identifier: "hi_IN")),
        Currency(code: "CAD", name: "Canadian Dollar", symbol: "C$", locale: Locale(identifier: "en_CA")),
        Currency(code: "AUD", name: "Australian Dollar", symbol: "A$", locale: Locale(identifier: "en_AU")),
        Currency(code: "CNY", name: "Chinese Yuan", symbol: "¥", locale: Locale(identifier: "zh_CN")),
        Currency(code: "CHF", name: "Swiss Franc", symbol: "CHF", locale: Locale(identifier: "de_CH")),
        Currency(code: "SGD", name: "Singapore Dollar", symbol: "S$", locale: Locale(identifier: "en_SG"))
    ]
    
    static let usd = allCurrencies.first { $0.code == "USD" }!
    static let eur = allCurrencies.first { $0.code == "EUR" }!
    static let gbp = allCurrencies.first { $0.code == "GBP" }!
    static let jpy = allCurrencies.first { $0.code == "JPY" }!
    static let inr = allCurrencies.first { $0.code == "INR" }!
}
