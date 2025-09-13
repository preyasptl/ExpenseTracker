//
//  CSVImportManager.swift
//  ExpenseTracker
//
//  Created by iMacPro on 13/09/25.
//


import SwiftUI
import UniformTypeIdentifiers

// MARK: - CSV Import Manager
class CSVImportManager: ObservableObject {
    @Published var isImporting = false
    @Published var importProgress: Double = 0
    @Published var importResults: ImportResults?
    @Published var showingResults = false
    
    struct ImportResults {
        let totalRows: Int
        let successfulImports: Int
        let failedImports: Int
        let errors: [String]
        let duplicates: Int
        
        var hasErrors: Bool { !errors.isEmpty }
        var successRate: Double {
            totalRows > 0 ? Double(successfulImports) / Double(totalRows) : 0
        }
    }
    
    // Sample CSV template
    static let sampleCSVContent = """
    Date,Title,Amount,Category,Is Lent Money,Lent To Person,Is Repaid,Repaid Date,Payment Mode,Notes
    2024-01-15,Coffee,4.50,Food,No,,,,Cash,Morning coffee
    2024-01-15,Lunch with John,25.00,Food,Yes,John,No,,Credit Card,Team lunch - John will pay back
    2024-01-16,Gas,45.00,Transportation,No,,,,Debit Card,
    2024-01-16,Movie tickets,24.00,Entertainment,No,,,,Cash,Weekend movie
    2024-01-17,Grocery shopping,67.89,Shopping,No,,,,Credit Card,Weekly groceries
    2024-01-18,Doctor visit,120.00,Health,No,,,,Net Banking,Regular checkup
    2024-01-20,Coffee,4.50,Food,Yes,Sarah,Yes,2024-01-22,Cash,Paid Sarah back
    """
    
    func importFromCSV(_ csvContent: String, expenseStore: ExpenseStore) async -> ImportResults {
        await MainActor.run {
            isImporting = true
            importProgress = 0
        }
        
        let lines = csvContent.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        guard lines.count > 1 else {
            let result = ImportResults(totalRows: 0, successfulImports: 0, failedImports: 0, errors: ["CSV file is empty or has no data rows"], duplicates: 0)
            await MainActor.run {
                isImporting = false
                importResults = result
                showingResults = true
            }
            return result
        }
        
        // Parse header
        let headers = parseCSVRow(lines[0]).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let dataRows = Array(lines.dropFirst())
        
        var successfulImports = 0
        var failedImports = 0
        var errors: [String] = []
        var duplicates = 0
        
        // Validate required headers
        let requiredHeaders = ["Date", "Title", "Amount", "Category"]
        let missingHeaders = requiredHeaders.filter { !headers.contains($0) }
        
        if !missingHeaders.isEmpty {
            let result = ImportResults(
                totalRows: dataRows.count,
                successfulImports: 0,
                failedImports: dataRows.count,
                errors: ["Missing required columns: \(missingHeaders.joined(separator: ", "))"],
                duplicates: 0
            )
            await MainActor.run {
                isImporting = false
                importResults = result
                showingResults = true
            }
            return result
        }
        
        // Process each row
        for (index, row) in dataRows.enumerated() {
            await MainActor.run {
                importProgress = Double(index) / Double(dataRows.count)
            }
            
            let values = parseCSVRow(row)
            
            guard values.count == headers.count else {
                errors.append("Row \(index + 2): Column count mismatch")
                failedImports += 1
                continue
            }
            
            do {
                let expense = try await parseExpenseFromRow(headers: headers, values: values, rowNumber: index + 2)
                
                // Check for duplicates
                let isDuplicate = await expenseStore.expenses.contains { existing in
                    existing.title == expense.title &&
                    existing.amount == expense.amount &&
                    Calendar.current.isDate(existing.date, inSameDayAs: expense.date)
                }
                
                if isDuplicate {
                    duplicates += 1
                } else {
                    await MainActor.run {
                        expenseStore.addExpense(expense)
                    }
                }
                successfulImports += 1
                
            } catch {
                errors.append("Row \(index + 2): \(error.localizedDescription)")
                failedImports += 1
            }
            
            // Small delay for progress animation
            try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        }
        
        let result = ImportResults(
            totalRows: dataRows.count,
            successfulImports: successfulImports,
            failedImports: failedImports,
            errors: errors,
            duplicates: duplicates
        )
        
        await MainActor.run {
            isImporting = false
            importProgress = 1.0
            importResults = result
            showingResults = true
        }
        
        return result
    }
    
    private func parseCSVRow(_ row: String) -> [String] {
        var result: [String] = []
        var currentField = ""
        var insideQuotes = false
        var i = row.startIndex
        
        while i < row.endIndex {
            let char = row[i]
            
            if char == "\"" {
                if insideQuotes && i < row.index(before: row.endIndex) && row[row.index(after: i)] == "\"" {
                    // Double quote inside quoted field
                    currentField += "\""
                    i = row.index(after: i)
                } else {
                    insideQuotes.toggle()
                }
            } else if char == "," && !insideQuotes {
                result.append(currentField.trimmingCharacters(in: .whitespacesAndNewlines))
                currentField = ""
            } else {
                currentField += String(char)
            }
            
            i = row.index(after: i)
        }
        
        result.append(currentField.trimmingCharacters(in: .whitespacesAndNewlines))
        return result
    }
    
    private func mapToClosestCategory(_ categoryStr: String) -> ExpenseCategory? {
        let lowercased = categoryStr.lowercased()
        
        // Common category mappings
        let categoryMappings: [String: ExpenseCategory] = [
            "groceries": .shopping,
            "grocery": .shopping,
            "transport": .transportation,
            "gas": .transportation,
            "fuel": .transportation,
            "movie": .entertainment,
            "movies": .entertainment,
            "restaurant": .food,
            "dining": .food,
            "medical": .health,
            "doctor": .health,
            "medicine": .health,
            "utilities": .bills,
            "rent": .bills,
            "mortgage": .bills,
            "clothes": .shopping,
            "clothing": .shopping
        ]
        
        // Direct mapping
        if let mapped = categoryMappings[lowercased] {
            return mapped
        }
        
        // Partial matching
        for (key, value) in categoryMappings {
            if lowercased.contains(key) || key.contains(lowercased) {
                return value
            }
        }
        
        return nil // Will default to .other
    }
    
    @MainActor private func parseExpenseFromRow(headers: [String], values: [String], rowNumber: Int) throws -> Expense {
        func getValue(for header: String) -> String {
            if let index = headers.firstIndex(of: header), index < values.count {
                return values[index]
            }
            return ""
        }
        
        // Required fields
        let dateStr = getValue(for: "Date")
        let title = getValue(for: "Title")
        let amountStr = getValue(for: "Amount")
        let categoryStr = getValue(for: "Category")
        
        // Validate required fields
        guard !title.isEmpty else {
            throw ImportError.invalidData("Title is required")
        }
        
        guard let amount = Double(amountStr), amount >= 0 else {
            throw ImportError.invalidData("Invalid amount: \(amountStr)")
        }
        
        // Parse date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = dateFormatter.date(from: dateStr) else {
            throw ImportError.invalidData("Invalid date format: \(dateStr). Expected: YYYY-MM-DD")
        }
        
        // Parse category
        // Parse category - with flexible matching and fallback
        let category: ExpenseCategory
        if let matchedCategory = ExpenseCategory.allCases.first(where: { $0.rawValue.lowercased() == categoryStr.lowercased() }) {
            category = matchedCategory
        } else {
            // Try partial matching for common variations
            category = mapToClosestCategory(categoryStr) ?? .other
        }
        
        // Optional fields
        let isLentMoney = getValue(for: "Is Lent Money").lowercased() == "yes"
        let lentToPersonName = isLentMoney ? getValue(for: "Lent To Person") : nil
        let isRepaid = getValue(for: "Is Repaid").lowercased() == "yes"
        
        let repaidDate: Date?
        if isRepaid, !getValue(for: "Repaid Date").isEmpty {
            repaidDate = dateFormatter.date(from: getValue(for: "Repaid Date"))
        } else {
            repaidDate = nil
        }
        
        let paymentModeName = getValue(for: "Payment Mode")
        let paymentMode: PaymentMode
        if !paymentModeName.isEmpty {
            // Try to find existing payment mode or create a default one
            let existingModes = PaymentModeStore().paymentModes
            paymentMode = existingModes.first { $0.name.lowercased() == paymentModeName.lowercased() } ?? PaymentMode.cash
        } else {
            paymentMode = PaymentMode.cash
        }
        
        let notes = getValue(for: "Notes")
        
        var expense = Expense(
            title: title,
            amount: amount,
            category: category,
            date: date,
            notes: notes.isEmpty ? nil : notes
        )
        
        expense.isLentMoney = isLentMoney
        expense.lentToPersonName = lentToPersonName
        expense.isRepaid = isRepaid
        expense.repaidDate = repaidDate
        expense.paymentMode = paymentMode
        
        return expense
    }
    
    enum ImportError: LocalizedError {
        case invalidData(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidData(let message):
                return message
            }
        }
    }
}
