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

// MARK: - Hybrid Core Data-First DataManager
@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    private let persistenceController = PersistenceController.shared
    private let firebaseService = FirebaseService.shared
    
    @Published var expenses: [Expense] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var syncStatus: SyncStatus = .idle
    
    // Changed from computed properties to @Published properties
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var hasPendingChanges = false
    
    // Sync state tracking
    private var cancellables = Set<AnyCancellable>()
    private let syncQueue = DispatchQueue(label: "firebase.sync", qos: .background)
    
    enum SyncStatus {
        case idle
        case syncing
        case success
        case error(String)
        
        var displayText: String {
            switch self {
            case .idle: return "Ready"
            case .syncing: return "Syncing..."
            case .success: return "Synced"
            case .error(let message): return "Error: \(message)"
            }
        }
    }
    
    init() {
        print("📊 DataManager: Initializing with Core Data-first architecture...")
        
        // Load local data immediately
        loadLocalExpenses()
        
        // Update pending changes status on init
        updatePendingChangesStatus()
        
        // Monitor Firebase auth state for sync availability
        firebaseService.$isSignedIn
            .sink { [weak self] isSignedIn in
                print("🔐 DataManager: Auth state changed - isSignedIn: \(isSignedIn)")
                if isSignedIn {
                    Task {
                        await self?.performBackgroundSync()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Authenticate if needed
        if !firebaseService.isSignedIn {
            Task {
                await authenticateFirebase()
            }
        }
    }
    
    // MARK: - Core Data Operations (Primary Data Source)
    private func loadLocalExpenses() {
        print("💾 DataManager: Loading expenses from Core Data...")
        let request: NSFetchRequest<CDExpense> = CDExpense.fetchRequest()
        request.predicate = NSPredicate(format: "isRemoved == NO")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDExpense.date, ascending: false)]
        
        do {
            let cdExpenses = try persistenceController.viewContext.fetch(request)
            print("💾 DataManager: Loaded \(cdExpenses.count) local expenses")
            
            // Convert to Expense objects
            self.expenses = cdExpenses.map { cdExpense in
                var expense = Expense(
                    id: cdExpense.wrappedId,
                    title: cdExpense.wrappedTitle,
                    amount: cdExpense.amount,
                    category: cdExpense.expenseCategory,
                    date: cdExpense.wrappedDate,
                    notes: cdExpense.notes
                )
                
                // Add lent money properties if Core Data supports them
                if let cdExpense = cdExpense as? CDExpense {
                    expense.isLentMoney = cdExpense.value(forKey: "isLentMoney") as? Bool ?? false
                    expense.lentToPersonName = cdExpense.value(forKey: "lentToPersonName") as? String
                    expense.isRepaid = cdExpense.value(forKey: "isRepaid") as? Bool ?? false
                    expense.repaidDate = cdExpense.value(forKey: "repaidDate") as? Date
                }
                
                return expense
            }
            
            // Update pending changes status after loading
            updatePendingChangesStatus()
            
            print("✅ DataManager: Local expenses loaded successfully")
        } catch {
            print("❌ DataManager: Failed to load local expenses: \(error)")
            self.errorMessage = "Failed to load expenses: \(error.localizedDescription)"
        }
    }
    
    // MARK: - CRUD Operations (Core Data First)
    func addExpense(_ expense: Expense) async {
        print("➕ DataManager: Adding expense: \(expense.title)")
        
        // 1. Save to Core Data first (immediate UI update)
        await saveExpenseLocally(expense, needsSync: true)
        
        // 2. Background sync to Firebase
        Task {
            await syncExpenseToFirebase(expense)
        }
    }
    
    func updateExpense(_ expense: Expense) async {
        print("✏️ DataManager: Updating expense: \(expense.title)")
        
        // 1. Update Core Data first
        await updateExpenseLocally(expense, needsSync: true)
        
        // 2. Background sync to Firebase
        Task {
            await syncExpenseToFirebase(expense)
        }
    }
    
    func deleteExpense(_ expense: Expense) async {
        print("🗑️ DataManager: Deleting expense: \(expense.title)")
        
        // 1. Mark as removed in Core Data
        await deleteExpenseLocally(expense.id, needsSync: true)
        
        // 2. Background sync to Firebase
        Task {
            await syncExpenseDeletionToFirebase(expense)
        }
    }
    
    // MARK: - Core Data Helpers
    private func saveExpenseLocally(_ expense: Expense, needsSync: Bool = false) async {
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
        cdExpense.needsSync = needsSync
        cdExpense.isRemoved = false
        
        // Set lent money properties safely
        cdExpense.setValue(expense.isLentMoney, forKey: "isLentMoney")
        cdExpense.setValue(expense.lentToPersonName, forKey: "lentToPersonName")
        cdExpense.setValue(expense.isRepaid, forKey: "isRepaid")
        cdExpense.setValue(expense.repaidDate, forKey: "repaidDate")
        
        persistenceController.save()
        
        // Reload UI and update status
        loadLocalExpenses()
        print("✅ DataManager: Expense saved locally")
    }
    
    private func updateExpenseLocally(_ expense: Expense, needsSync: Bool = false) async {
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
        cdExpense.needsSync = needsSync
        
        // Update lent money properties safely
        cdExpense.setValue(expense.isLentMoney, forKey: "isLentMoney")
        cdExpense.setValue(expense.lentToPersonName, forKey: "lentToPersonName")
        cdExpense.setValue(expense.isRepaid, forKey: "isRepaid")
        cdExpense.setValue(expense.repaidDate, forKey: "repaidDate")
        
        persistenceController.save()
        loadLocalExpenses()
        print("✅ DataManager: Expense updated locally")
    }
    
    private func deleteExpenseLocally(_ expenseId: UUID, needsSync: Bool = false) async {
        guard let cdExpense = await fetchCDExpense(by: expenseId) else { return }
        
        cdExpense.isRemoved = true
        cdExpense.updatedAt = Date()
        cdExpense.needsSync = needsSync
        
        persistenceController.save()
        loadLocalExpenses()
        print("✅ DataManager: Expense marked as removed locally")
    }
    
    private func fetchCDExpense(by id: UUID) async -> CDExpense? {
        let context = persistenceController.viewContext
        let request: NSFetchRequest<CDExpense> = CDExpense.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        return try? context.fetch(request).first
    }
    
    // MARK: - Pending Changes Status Update
    private func updatePendingChangesStatus() {
        let context = persistenceController.viewContext
        let request: NSFetchRequest<CDExpense> = CDExpense.fetchRequest()
        request.predicate = NSPredicate(format: "needsSync == YES")
        
        do {
            let count = try context.count(for: request)
            self.hasPendingChanges = count > 0
        } catch {
            self.hasPendingChanges = false
            print("❌ DataManager: Failed to check pending changes: \(error)")
        }
    }
    
    // MARK: - Firebase Sync Operations
    private func authenticateFirebase() async {
        print("🔐 DataManager: Authenticating with Firebase...")
        do {
            try await firebaseService.signInAnonymously()
            print("✅ DataManager: Firebase authentication successful")
        } catch {
            print("❌ DataManager: Firebase authentication failed: \(error)")
        }
    }
    
    func performManualSync() async {
        print("🔄 DataManager: Manual sync requested")
        await performBackgroundSync()
    }
    
    private func performBackgroundSync() async {
        guard firebaseService.isSignedIn else {
            print("⚠️ DataManager: Cannot sync - not authenticated")
            return
        }
        
        await MainActor.run {
            self.syncStatus = .syncing
        }
        
        print("🔄 DataManager: Starting background sync...")
        
        do {
            // 1. Upload unsynced local changes to Firebase
            await uploadPendingChanges()
            
            // 2. Download new/updated expenses from Firebase
            await downloadFirebaseChanges()
            
            await MainActor.run {
                self.syncStatus = .success
                self.lastSyncDate = Date() // Update @Published property
            }
            
            print("✅ DataManager: Background sync completed")
        } catch {
            print("❌ DataManager: Background sync failed: \(error)")
            await MainActor.run {
                self.syncStatus = .error(error.localizedDescription)
            }
        }
    }
    
    private func uploadPendingChanges() async {
        print("📤 DataManager: Uploading pending changes...")
        
        let context = persistenceController.viewContext
        let request: NSFetchRequest<CDExpense> = CDExpense.fetchRequest()
        request.predicate = NSPredicate(format: "needsSync == YES")
        
        do {
            let pendingExpenses = try context.fetch(request)
            print("📤 DataManager: Found \(pendingExpenses.count) pending changes")
            
            for cdExpense in pendingExpenses {
                if cdExpense.isRemoved {
                    // Upload deletion
                    await syncExpenseDeletionToFirebase(cdExpense)
                } else {
                    // Upload create/update
                    let expense = convertCDExpenseToExpense(cdExpense)
                    await syncExpenseToFirebase(expense)
                }
                
                // Mark as synced
                cdExpense.needsSync = false
                cdExpense.lastSyncedAt = Date()
            }
            
            persistenceController.save()
            
            // Update pending changes status
            updatePendingChangesStatus()
            
            print("✅ DataManager: Pending changes uploaded")
        } catch {
            print("❌ DataManager: Failed to upload pending changes: \(error)")
        }
    }
    
    private func downloadFirebaseChanges() async {
        print("📥 DataManager: Downloading Firebase changes...")
        
        do {
            let firebaseExpenses = try await firebaseService.fetchAllExpenses()
            print("📥 DataManager: Downloaded \(firebaseExpenses.count) expenses from Firebase")
            
            // Merge with local data using UUID deduplication
            for firebaseExpense in firebaseExpenses {
                await mergeFirebaseExpense(firebaseExpense)
            }
            
            // Reload UI after merge
            loadLocalExpenses()
            print("✅ DataManager: Firebase changes merged")
        } catch {
            print("❌ DataManager: Failed to download Firebase changes: \(error)")
            
        }
    }
    
    private func mergeFirebaseExpense(_ firebaseExpense: FirebaseExpense) async {
        let expenseId = UUID(uuidString: firebaseExpense.id) ?? UUID()
        let existingCDExpense = await fetchCDExpense(by: expenseId)
        
        if let existing = existingCDExpense {
            // Check if Firebase version is newer
            if let firebaseUpdated = firebaseExpense.updatedAt?.dateValue(),
               let localUpdated = existing.updatedAt,
               firebaseUpdated > localUpdated {
                
                print("🔄 DataManager: Updating local expense with newer Firebase version: \(firebaseExpense.title)")
                let expense = firebaseExpense.toExpense()
                await updateExpenseLocally(expense, needsSync: false)
            } else {
                print("⏩ DataManager: Local version is newer or same, skipping: \(firebaseExpense.title)")
            }
        } else {
            // New expense from Firebase
            print("➕ DataManager: Adding new expense from Firebase: \(firebaseExpense.title)")
            let expense = firebaseExpense.toExpense()
            await saveExpenseLocally(expense, needsSync: false)
        }
    }
    
    private func syncExpenseToFirebase(_ expense: Expense) async {
        guard firebaseService.isSignedIn else { return }
        
        do {
            if let cdExpense = await fetchCDExpense(by: expense.id),
               let firebaseId = cdExpense.firebaseId {
                // Update existing
                try await firebaseService.updateExpense(expense, firebaseId: firebaseId)
                print("✅ DataManager: Updated expense in Firebase: \(expense.title)")
            } else {
                // Create new
                let firebaseId = try await firebaseService.createExpense(expense)
                await updateFirebaseId(for: expense.id, firebaseId: firebaseId)
                print("✅ DataManager: Created expense in Firebase: \(expense.title)")
            }
        } catch {
            print("❌ DataManager: Failed to sync expense to Firebase: \(error)")
        }
    }
    
    private func syncExpenseDeletionToFirebase(_ expense: Expense) async {
        guard firebaseService.isSignedIn else { return }
        
        if let cdExpense = await fetchCDExpense(by: expense.id),
           let firebaseId = cdExpense.firebaseId {
            do {
                try await firebaseService.deleteExpense(firebaseId: firebaseId)
                print("✅ DataManager: Deleted expense from Firebase: \(expense.title)")
            } catch {
                print("❌ DataManager: Failed to delete expense from Firebase: \(error)")
            }
        }
    }
    
    private func syncExpenseDeletionToFirebase(_ cdExpense: CDExpense) async {
        guard firebaseService.isSignedIn,
              let firebaseId = cdExpense.firebaseId else { return }
        
        do {
            try await firebaseService.deleteExpense(firebaseId: firebaseId)
            print("✅ DataManager: Deleted expense from Firebase: \(cdExpense.wrappedTitle)")
        } catch {
            print("❌ DataManager: Failed to delete expense from Firebase: \(error)")
        }
    }
    
    private func updateFirebaseId(for expenseId: UUID, firebaseId: String) async {
        guard let cdExpense = await fetchCDExpense(by: expenseId) else { return }
        
        cdExpense.firebaseId = firebaseId
        cdExpense.needsSync = false
        cdExpense.lastSyncedAt = Date()
        persistenceController.save()
        
        // Update pending changes status
        updatePendingChangesStatus()
    }
    
    // MARK: - Helper Methods
    private func convertCDExpenseToExpense(_ cdExpense: CDExpense) -> Expense {
        var expense = Expense(
            id: cdExpense.wrappedId,
            title: cdExpense.wrappedTitle,
            amount: cdExpense.amount,
            category: cdExpense.expenseCategory,
            date: cdExpense.wrappedDate,
            notes: cdExpense.notes
        )
        
        // Add lent money properties safely
        expense.isLentMoney = cdExpense.value(forKey: "isLentMoney") as? Bool ?? false
        expense.lentToPersonName = cdExpense.value(forKey: "lentToPersonName") as? String
        expense.isRepaid = cdExpense.value(forKey: "isRepaid") as? Bool ?? false
        expense.repaidDate = cdExpense.value(forKey: "repaidDate") as? Date
        
        return expense
    }
    
    // MARK: - Public Interface
    var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    func expensesForCategory(_ category: ExpenseCategory) -> [Expense] {
        expenses.filter { $0.category == category }
    }
}
