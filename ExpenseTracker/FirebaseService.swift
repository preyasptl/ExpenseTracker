    //
//  FirebaseService.swift
//  ExpenseTracker
//
//  Created by iMacPro on 27/06/25.
//


import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    @Published var isSignedIn = false
    @Published var currentUserId: String?
    @Published var syncStatus: SyncStatus = .idle
    
    enum SyncStatus {
        case idle
        case syncing
        case success
        case error(String)
    }
    
    init() {
        print("🔥 FirebaseService: Initializing...")
        
        // Monitor auth state
        auth.addStateDidChangeListener { [weak self] _, user in
            print("🔐 FirebaseService: Auth state changed")
            DispatchQueue.main.async {
                self?.isSignedIn = user != nil
                self?.currentUserId = user?.uid
                print("🔐 FirebaseService: isSignedIn = \(user != nil), userId = \(user?.uid ?? "nil")")
            }
        }
    }
    
    // MARK: - Authentication
    func signInAnonymously() async throws {
        print("🔐 FirebaseService: Attempting anonymous sign in...")
        syncStatus = .syncing
        
        do {
            let result = try await auth.signInAnonymously()
            DispatchQueue.main.async {
                self.currentUserId = result.user.uid
                self.isSignedIn = true
                self.syncStatus = .success
                print("✅ FirebaseService: Anonymous sign in successful, userId: \(result.user.uid)")
            }
        } catch {
            print("❌ FirebaseService: Anonymous sign in failed: \(error)")
            DispatchQueue.main.async {
                self.syncStatus = .error(error.localizedDescription)
            }
            throw error
        }
    }
    
    func signOut() throws {
        try auth.signOut()
        DispatchQueue.main.async {
            self.isSignedIn = false
            self.currentUserId = nil
        }
    }
    
    // MARK: - Expense CRUD Operations
    private var expensesCollection: CollectionReference? {
        guard let userId = currentUserId else {
            print("❌ FirebaseService: No user ID available")
            return nil
        }
        let collection = db.collection("users").document(userId).collection("expenses")
        print("📁 FirebaseService: Using collection path: users/\(userId)/expenses")
        return collection
    }
    
    func createExpense(_ expense: Expense) async throws -> String {
        print("➕ FirebaseService: Creating expense: \(expense.title)")
        guard let collection = expensesCollection else {
            throw FirebaseError.notAuthenticated
        }
        
        let expenseData: [String: Any] = [
            "id": expense.id.uuidString,
            "title": expense.title,
            "amount": expense.amount,
            "category": expense.category.rawValue,
            "date": Timestamp(date: expense.date),
            "notes": expense.notes ?? "",
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
            "isRemoved": false,
            // New fields with safe defaults
            "isLentMoney": expense.isLentMoney,
            "lentToPersonName": expense.lentToPersonName ?? "",
            "isRepaid": expense.isRepaid,
            "paymentModeName": "Cash" // Default for now
        ]
        
        print("📤 FirebaseService: Expense data: \(expenseData)")
        
        do {
            let docRef = try await collection.addDocument(data: expenseData)
            print("✅ FirebaseService: Expense created with ID: \(docRef.documentID)")
            return docRef.documentID
        } catch {
            print("❌ FirebaseService: Failed to create expense: \(error)")
            throw error
        }
    }
    
    func updateExpense(_ expense: Expense, firebaseId: String) async throws {
        print("✏️ FirebaseService: Updating expense with Firebase ID: \(firebaseId)")
        guard let collection = expensesCollection else {
            throw FirebaseError.notAuthenticated
        }
        
        let expenseData: [String: Any] = [
            "title": expense.title,
            "amount": expense.amount,
            "category": expense.category.rawValue,
            "date": Timestamp(date: expense.date),
            "notes": expense.notes ?? "",
            "updatedAt": FieldValue.serverTimestamp(),
            "isLentMoney": expense.isLentMoney,
            "lentToPersonName": expense.lentToPersonName ?? "",
            "isRepaid": expense.isRepaid
        ]
        
        try await collection.document(firebaseId).updateData(expenseData)
        print("✅ FirebaseService: Expense updated successfully")
    }
    
    func deleteExpense(firebaseId: String) async throws {
        print("🗑️ FirebaseService: Deleting expense with Firebase ID: \(firebaseId)")
        guard let collection = expensesCollection else {
            throw FirebaseError.notAuthenticated
        }
        
        try await collection.document(firebaseId).updateData([
            "isRemoved": true,
            "updatedAt": FieldValue.serverTimestamp()
        ])
        print("✅ FirebaseService: Expense marked as removed")
    }
    
    // In your FirebaseService.swift, update the fetchAllExpenses method:
    func fetchAllExpenses() async throws -> [FirebaseExpense] {
        print("📥 FirebaseService: Fetching all expenses...")
        guard let collection = expensesCollection else {
            throw FirebaseError.notAuthenticated
        }
        
        let snapshot = try await collection
            .whereField("isRemoved", isEqualTo: false)
            .getDocuments()
        
        print("📥 FirebaseService: Fetched \(snapshot.documents.count) documents")
        
        let expenses = snapshot.documents.compactMap { document -> FirebaseExpense? in
            do {
                // Debug: Print raw document data
                print("📄 Raw Firebase document: \(document.data())")
                
                let expense = try document.data(as: FirebaseExpense.self)
                print("📄 Parsed expense: \(expense.title) - isLentMoney: \(expense.isLentMoney)")
                return expense
            } catch {
                print("❌ FirebaseService: Failed to parse expense document: \(error)")
                return nil
            }
        }
        
        return expenses.sorted { ($0.createdAt?.dateValue() ?? Date()) > ($1.createdAt?.dateValue() ?? Date()) }
    }
    
    // MARK: - Real-time Listening
    func listenToExpenses(completion: @escaping ([FirebaseExpense]) -> Void) -> ListenerRegistration? {
        print("👂 FirebaseService: Setting up real-time listener...")
        guard let collection = expensesCollection else {
            print("❌ FirebaseService: Cannot set up listener - no collection")
            return nil
        }
        
        return collection
            .whereField("isRemoved", isEqualTo: false)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ FirebaseService: Listener error: \(error)")
                    return
                }
                
                guard let snapshot = snapshot else {
                    print("❌ FirebaseService: Received nil snapshot")
                    return
                }
                
                print("👂 FirebaseService: Listener received \(snapshot.documents.count) documents")
                
                let expenses = snapshot.documents.compactMap { document -> FirebaseExpense? in
                    do {
                        return try document.data(as: FirebaseExpense.self)
                    } catch {
                        print("❌ FirebaseService: Failed to parse document in listener: \(error)")
                        return nil
                    }
                }
                
                print("✅ FirebaseService: Listener parsed \(expenses.count) expenses")
                completion(expenses)
            }
    }
}
