//
//  DataManager.swift
//  ExpenseTracker
//
//  Created by iMacPro on 27/06/25.
//


import CoreData
import Combine
import Foundation
import FirebaseFirestore

@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    private let persistenceController = PersistenceController.shared
    private let firebaseService = FirebaseService.shared
    
    @Published var expenses: [Expense] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var syncStatus: FirebaseService.SyncStatus = .idle
    
    private var cancellables = Set<AnyCancellable>()
    private var firebaseListener: ListenerRegistration?
    
    init() {
        print("📊 DataManager: Initializing...")
        
        // Monitor Firebase sync status
        firebaseService.$syncStatus
            .assign(to: \.syncStatus, on: self)
            .store(in: &cancellables)
        
        // Monitor authentication state - FIXED: Only set up listener once
        firebaseService.$isSignedIn
            .sink { [weak self] isSignedIn in
                print("🔐 DataManager: Auth state changed - isSignedIn: \(isSignedIn)")
                if isSignedIn {
                    print("✅ DataManager: User signed in, setting up Firebase listener")
                    self?.setupFirebaseListener()
                    // Only sync pending expenses, not all expenses (listener handles that)
                    Task {
                        await self?.syncPendingExpensesOnly()
                    }
                } else {
                    print("❌ DataManager: User signed out, removing Firebase listener")
                    self?.firebaseListener?.remove()
                }
            }
            .store(in: &cancellables)
        
        // Load local data immediately
        loadLocalExpenses()
        
        // Sign in anonymously if not signed in
        if !firebaseService.isSignedIn {
            print("🔄 DataManager: Attempting anonymous sign in...")
            Task {
                do {
                    try await firebaseService.signInAnonymously()
                    print("✅ DataManager: Anonymous sign in successful")
                } catch {
                    print("❌ DataManager: Anonymous sign in failed: \(error)")
                }
            }
        }
    }
    
    deinit {
        firebaseListener?.remove()
    }
    
    // Add this new method that only syncs pending expenses
    private func syncPendingExpensesOnly() async {
        print("🔄 DataManager: Syncing pending expenses...")
        let context = persistenceController.viewContext
        let request: NSFetchRequest<CDExpense> = CDExpense.fetchRequest()
        request.predicate = NSPredicate(format: "needsSync == YES AND isRemoved == NO")
        
        do {
            let pendingExpenses = try context.fetch(request)
            print("📋 DataManager: Found \(pendingExpenses.count) pending expenses to sync")
            
            for cdExpense in pendingExpenses {
                let expense = Expense(
                    id: cdExpense.wrappedId,
                    title: cdExpense.wrappedTitle,
                    amount: cdExpense.amount,
                    category: cdExpense.expenseCategory,
                    date: cdExpense.wrappedDate,
                    notes: cdExpense.notes
                )
                
                do {
                    let firebaseId = try await firebaseService.createExpense(expense)
                    await updateFirebaseId(for: expense.id, firebaseId: firebaseId)
                    print("✅ DataManager: Synced pending expense: \(expense.title)")
                } catch {
                    print("❌ DataManager: Failed to sync pending expense: \(error)")
                }
            }
        } catch {
            print("❌ DataManager: Failed to fetch pending expenses: \(error)")
        }
    }
    // MARK: - Core Data Operations
    private func loadLocalExpenses() {
        print("💾 DataManager: Loading local expenses...")
        let request: NSFetchRequest<CDExpense> = CDExpense.fetchRequest()
        request.predicate = NSPredicate(format: "isRemoved == NO")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDExpense.date, ascending: false)]
        
        do {
            let cdExpenses = try persistenceController.viewContext.fetch(request)
            print("💾 DataManager: Loaded \(cdExpenses.count) local expenses")
            
            // Convert CDExpense to Expense (simplified for now)
            self.expenses = cdExpenses.map { cdExpense in
                Expense(
                    id: cdExpense.wrappedId,
                    title: cdExpense.wrappedTitle,
                    amount: cdExpense.amount,
                    category: cdExpense.expenseCategory,
                    date: cdExpense.wrappedDate,
                    notes: cdExpense.notes
                )
            }
            print("✅ DataManager: Local expenses loaded successfully")
        } catch {
            print("❌ DataManager: Failed to load local expenses: \(error)")
            self.errorMessage = "Failed to load local expenses: \(error.localizedDescription)"
        }
    }
    
    // MARK: - CRUD Operations with Debug Logging
    func addExpense(_ expense: Expense) async {
        print("➕ DataManager: Adding expense: \(expense.title) - $\(expense.amount)")
        
        // Save locally first
        await saveExpenseLocally(expense)
        
        // Sync to Firebase
        if firebaseService.isSignedIn {
            print("🔥 DataManager: Syncing to Firebase...")
            do {
                let firebaseId = try await firebaseService.createExpense(expense)
                print("✅ DataManager: Firebase sync successful, ID: \(firebaseId)")
                await updateFirebaseId(for: expense.id, firebaseId: firebaseId)
            } catch {
                print("❌ DataManager: Firebase sync failed: \(error)")
                await markExpenseForSync(expense.id)
            }
        } else {
            print("⚠️ DataManager: Not signed in to Firebase, marking for later sync")
            await markExpenseForSync(expense.id)
        }
    }
    
    func updateExpense(_ expense: Expense) async {
        print("✏️ DataManager: Updating expense: \(expense.title)")
        await updateExpenseLocally(expense)
        
        if firebaseService.isSignedIn {
            if let cdExpense = await fetchCDExpense(by: expense.id),
               let firebaseId = cdExpense.firebaseId {
                do {
                    try await firebaseService.updateExpense(expense, firebaseId: firebaseId)
                    print("✅ DataManager: Firebase update successful")
                } catch {
                    print("❌ DataManager: Firebase update failed: \(error)")
                    await markExpenseForSync(expense.id)
                }
            }
        }
    }
    
    func deleteExpense(_ expense: Expense) async {
        print("🗑️ DataManager: Deleting expense: \(expense.title)")
        await deleteExpenseLocally(expense.id)
        
        if firebaseService.isSignedIn {
            if let cdExpense = await fetchCDExpense(by: expense.id),
               let firebaseId = cdExpense.firebaseId {
                do {
                    try await firebaseService.deleteExpense(firebaseId: firebaseId)
                    print("✅ DataManager: Firebase delete successful")
                } catch {
                    print("❌ DataManager: Firebase delete failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Private Core Data Helpers
    private func saveExpenseLocally(_ expense: Expense) async {
        print("💾 DataManager: Saving expense locally: \(expense.title)")
        let context = persistenceController.viewContext
        
        let cdExpense = CDExpense(context: context)
        cdExpense.id = expense.id
        cdExpense.title = expense.title
        cdExpense.amount = expense.amount
        cdExpense.category = expense.category.rawValue
        cdExpense.date = expense.date
        cdExpense.notes = expense.notes
        cdExpense.createdAt = Date()
        cdExpense.updatedAt = Date()
        cdExpense.needsSync = true
        cdExpense.isRemoved = false
        
        // Handle new fields safely
        if expense.isLentMoney {
            cdExpense.isLentMoney = expense.isLentMoney
            cdExpense.lentToPersonName = expense.lentToPersonName
        }
        
        persistenceController.save()
        
        await MainActor.run {
            loadLocalExpenses()
        }
        print("✅ DataManager: Local save completed")
    }
    
    private func updateExpenseLocally(_ expense: Expense) async {
        guard let cdExpense = await fetchCDExpense(by: expense.id) else {
            print("❌ DataManager: Could not find expense to update")
            return
        }
        
        cdExpense.title = expense.title
        cdExpense.amount = expense.amount
        cdExpense.category = expense.category.rawValue
        cdExpense.date = expense.date
        cdExpense.notes = expense.notes
        cdExpense.updatedAt = Date()
        cdExpense.needsSync = true
        
        persistenceController.save()
        
        await MainActor.run {
            loadLocalExpenses()
        }
    }
    
    private func deleteExpenseLocally(_ expenseId: UUID) async {
        guard let cdExpense = await fetchCDExpense(by: expenseId) else { return }
        
        cdExpense.isRemoved = true
        cdExpense.updatedAt = Date()
        
        persistenceController.save()
        await MainActor.run {
            loadLocalExpenses()
        }
    }
    
    private func fetchCDExpense(by id: UUID) async -> CDExpense? {
        let context = persistenceController.viewContext
        let request: NSFetchRequest<CDExpense> = CDExpense.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        return try? context.fetch(request).first
    }
    
    private func updateFirebaseId(for expenseId: UUID, firebaseId: String) async {
        guard let cdExpense = await fetchCDExpense(by: expenseId) else { return }
        
        cdExpense.firebaseId = firebaseId
        cdExpense.needsSync = false
        cdExpense.lastSyncedAt = Date()
        
        persistenceController.save()
    }
    
    private func markExpenseForSync(_ expenseId: UUID) async {
        guard let cdExpense = await fetchCDExpense(by: expenseId) else { return }
        
        cdExpense.needsSync = true
        persistenceController.save()
    }
    
    // MARK: - Firebase Integration
    private func setupFirebaseListener() {
        // Remove existing listener to prevent duplicates
        firebaseListener?.remove()
        
        print("👂 DataManager: Setting up Firebase listener...")
        firebaseListener = firebaseService.listenToExpenses { [weak self] firebaseExpenses in
            print("🔥 DataManager: Received \(firebaseExpenses.count) expenses from Firebase")
            Task { @MainActor in
                await self?.handleFirebaseExpenses(firebaseExpenses)
            }
        }
    }
    
    private func handleFirebaseExpenses(_ firebaseExpenses: [FirebaseExpense]) async {
        print("🔄 DataManager: Processing Firebase expenses...")
        
        // Convert Firebase expenses to Expense objects
        var updatedExpenses: [Expense] = []
        
        for firebaseExpense in firebaseExpenses {
            print("📄 Firebase expense: \(firebaseExpense.title) - isLentMoney: \(firebaseExpense.isLentMoney)")
            
            let convertedExpense = firebaseExpense.toExpense()
            print("📄 Converted expense: \(convertedExpense.title) - isLentMoney: \(convertedExpense.isLentMoney)")
            
            updatedExpenses.append(convertedExpense)
        }
        
        // Update the published expenses array immediately
        await MainActor.run {
            self.expenses = updatedExpenses.sorted { $0.date > $1.date }
            print("🔄 DataManager: Updated expenses array with \(self.expenses.count) expenses")
            
            // Debug: Check if the lent money expense is in the array
            for expense in self.expenses {
                if expense.isLentMoney {
                    print("✅ Found lent money expense in array: \(expense.title) - lentTo: \(expense.lentToPersonName ?? "nil")")
                }
            }
        }
        
        // Also update Core Data in the background (optional)
        await updateCoreDataFromFirebase(updatedExpenses)
    }

    // Helper method to update Core Data
    private func updateCoreDataFromFirebase(_ expenses: [Expense]) async {
        let context = persistenceController.viewContext
        
        for expense in expenses {
            // Check if expense already exists in Core Data
            let request: NSFetchRequest<CDExpense> = CDExpense.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", expense.id as CVarArg)
            request.fetchLimit = 1
            
            do {
                let existingExpenses = try context.fetch(request)
                
                if let existingExpense = existingExpenses.first {
                    // Update existing expense
                    existingExpense.updateFromExpense(expense)
                } else {
                    // Create new expense
                    let newCDExpense = CDExpense(context: context)
                    newCDExpense.updateFromExpense(expense)
                    newCDExpense.createdAt = Date()
                    newCDExpense.needsSync = false
                }
            } catch {
                print("❌ Error updating Core Data: \(error)")
            }
        }
        
        // Save Core Data changes
        persistenceController.save()
        print("💾 DataManager: Updated Core Data with Firebase expenses")
    }
    
    private func performInitialSync() async {
        print("🔄 DataManager: Performing initial Firebase sync...")
        do {
            let firebaseExpenses = try await firebaseService.fetchAllExpenses()
            print("✅ DataManager: Initial sync completed, received \(firebaseExpenses.count) expenses")
            
            // Remove this line - the listener will handle the data
            // await handleFirebaseExpenses(firebaseExpenses)
            
            await syncPendingExpenses()
        } catch {
            print("❌ DataManager: Initial sync failed: \(error)")
        }
    }
    
    private func syncPendingExpenses() async {
        print("🔄 DataManager: Syncing pending expenses...")
        let context = persistenceController.viewContext
        let request: NSFetchRequest<CDExpense> = CDExpense.fetchRequest()
        request.predicate = NSPredicate(format: "needsSync == YES AND isRemoved == NO")
        
        do {
            let pendingExpenses = try context.fetch(request)
            print("📋 DataManager: Found \(pendingExpenses.count) pending expenses to sync")
            
            for cdExpense in pendingExpenses {
                let expense = Expense(
                    id: cdExpense.wrappedId,
                    title: cdExpense.wrappedTitle,
                    amount: cdExpense.amount,
                    category: cdExpense.expenseCategory,
                    date: cdExpense.wrappedDate,
                    notes: cdExpense.notes
                )
                
                do {
                    let firebaseId = try await firebaseService.createExpense(expense)
                    await updateFirebaseId(for: expense.id, firebaseId: firebaseId)
                    print("✅ DataManager: Synced pending expense: \(expense.title)")
                } catch {
                    print("❌ DataManager: Failed to sync pending expense: \(error)")
                }
            }
        } catch {
            print("❌ DataManager: Failed to fetch pending expenses: \(error)")
        }
    }
    
    // MARK: - Computed Properties
    var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    func expensesForCategory(_ category: ExpenseCategory) -> [Expense] {
        expenses.filter { $0.category == category }
    }
}


extension DataManager {
    func testFirebaseConnection() async {
        print("🧪 Testing Firebase connection...")
        
        if !firebaseService.isSignedIn {
            print("🔐 Not signed in, attempting sign in...")
            do {
                try await firebaseService.signInAnonymously()
                print("✅ Sign in successful")
            } catch {
                print("❌ Sign in failed: \(error)")
                return
            }
        }
        
        // Try to write a test document
        let testExpense = Expense(
            title: "Test Expense",
            amount: 1.0,
            category: .other,
            date: Date(),
            notes: "Test from app"
        )
        
        do {
            let firebaseId = try await firebaseService.createExpense(testExpense)
            print("✅ Test expense created with ID: \(firebaseId)")
        } catch {
            print("❌ Test expense creation failed: \(error)")
        }
    }
}
