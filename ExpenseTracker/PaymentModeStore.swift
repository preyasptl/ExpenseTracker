//
//  PaymentModeStore.swift
//  ExpenseTracker
//
//  Created by iMacPro on 27/06/25.
//
import SwiftUI


// MARK: - Payment Mode Store
@MainActor
class PaymentModeStore: ObservableObject {
    @Published var paymentModes: [PaymentMode] = []
    
    private let userDefaults = UserDefaults.standard
    private let paymentModesKey = "SavedPaymentModes"
    
    init() {
        loadPaymentModes()
    }
    
    func addPaymentMode(_ paymentMode: PaymentMode) {
        paymentModes.append(paymentMode)
        savePaymentModes()
    }
    
    func updatePaymentMode(_ paymentMode: PaymentMode) {
        if let index = paymentModes.firstIndex(where: { $0.id == paymentMode.id }) {
            paymentModes[index] = paymentMode
            savePaymentModes()
        }
    }
    
    func deletePaymentMode(_ paymentMode: PaymentMode) {
        paymentModes.removeAll { $0.id == paymentMode.id }
        savePaymentModes()
    }
    
    func setDefaultPaymentMode(_ paymentMode: PaymentMode) {
        // Remove default from all others
        for index in paymentModes.indices {
            paymentModes[index].isDefault = false
        }
        
        // Set as default
        if let index = paymentModes.firstIndex(where: { $0.id == paymentMode.id }) {
            paymentModes[index].isDefault = true
            savePaymentModes()
        }
    }
    
    var defaultPaymentMode: PaymentMode {
        return paymentModes.first { $0.isDefault } ?? PaymentMode.cash
    }
    
    private func savePaymentModes() {
        if let encoded = try? JSONEncoder().encode(paymentModes) {
            userDefaults.set(encoded, forKey: paymentModesKey)
        }
    }
    
    private func loadPaymentModes() {
        if let data = userDefaults.data(forKey: paymentModesKey),
           let decoded = try? JSONDecoder().decode([PaymentMode].self, from: data) {
            paymentModes = decoded
        } else {
            // First time - load default modes
            paymentModes = PaymentMode.defaultModes
            savePaymentModes()
        }
    }
}
