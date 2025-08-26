//
//  ExpenseStore.swift
//  ExpenseTracker
//
//  Created by iMacPro on 26/06/25.
//


// MARK: - Updated ExpenseStore to use DataManager
// ExpenseStore.swift
import Foundation
import Combine

@MainActor
class ExpenseStore: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var syncStatus: String = "Ready"
    
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
        
        dataManager.$syncStatus
            .map { status in
                switch status {
                case .idle:
                    return "Ready"
                case .syncing:
                    return "Syncing..."
                case .success:
                    return "Synced"
                case .error(let message):
                    return "Error: \(message)"
                }
            }
            .assign(to: \.syncStatus, on: self)
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
    
    var totalExpenses: Double {
        dataManager.totalExpenses
    }
    
    func expensesForCategory(_ category: ExpenseCategory) -> [Expense] {
        dataManager.expensesForCategory(category)
    }
}
