//
//  ExpenseStore.swift
//  ExpenseTracker
//
//  Created by iMacPro on 26/06/25.
//


import Foundation
import Combine

@MainActor
class ExpenseStore: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var syncStatus: String = "Ready"
    @Published var lastSyncDate: Date?
    @Published var hasPendingChanges = false
    
    private let dataManager = DataManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Subscribe to DataManager updates
        dataManager.$expenses
            .assign(to: \.expenses, on: self)
            .store(in: &cancellables)
        
        dataManager.$isLoading
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        dataManager.$errorMessage
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
        
        // Map sync status to display text
        dataManager.$syncStatus
            .map { $0.displayText }
            .assign(to: \.syncStatus, on: self)
            .store(in: &cancellables)
        
        // Subscribe to sync metadata - now using @Published properties
        dataManager.$lastSyncDate
            .assign(to: \.lastSyncDate, on: self)
            .store(in: &cancellables)
        
        dataManager.$hasPendingChanges
            .assign(to: \.hasPendingChanges, on: self)
            .store(in: &cancellables)
    }
    
    func addExpense(_ expense: Expense) {
        Task {
            await dataManager.addExpense(expense)
        }
    }
    
    func deleteExpense(_ expense: Expense) {
        Task {
            await dataManager.deleteExpense(expense)
        }
    }
    
    func updateExpense(_ expense: Expense) {
        Task {
            await dataManager.updateExpense(expense)
        }
    }
    
    // Manual sync function for pull-to-refresh
    func performManualSync() {
        Task {
            await dataManager.performManualSync()
        }
    }
    
    var totalExpenses: Double {
        dataManager.totalExpenses
    }
    
    func expensesForCategory(_ category: ExpenseCategory) -> [Expense] {
        dataManager.expensesForCategory(category)
    }
}
