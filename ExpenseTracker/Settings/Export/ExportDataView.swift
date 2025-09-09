//
//  ExportDataView.swift
//  ExpenseTracker
//
//  Created by iMacPro on 09/09/25.
//
import SwiftUI

// MARK: - Supporting Views
struct ExportDataView: View {
    let expenses: [Expense]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: ExportFormat = .csv
    @State private var selectedDateRange: DateRange = .allTime
    @State private var includeLentMoney = true
    @State private var includeNotes = true
    @State private var isExporting = false
    
    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case json = "JSON"
    }
    
    enum DateRange: String, CaseIterable {
        case thisMonth = "This Month"
        case last3Months = "Last 3 Months"
        case thisYear = "This Year"
        case allTime = "All Time"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Export Format") {
                    Picker("Format", selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Date Range") {
                    Picker("Range", selection: $selectedDateRange) {
                        ForEach(DateRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                }
                
                Section("Include") {
                    Toggle("Lent Money Details", isOn: $includeLentMoney)
                    Toggle("Notes", isOn: $includeNotes)
                }
                
                Section("Summary") {
                    HStack {
                        Text("Expenses to Export")
                        Spacer()
                        Text("\(filteredExpenses.count)")
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Total Amount")
                        Spacer()
                        Text(formatCurrency(filteredExpenses.reduce(0) { $0 + $1.amount }))
                            .fontWeight(.medium)
                    }
                }
                
                Section {
                    Button(action: exportData) {
                        HStack {
                            if isExporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(isExporting ? "Exporting..." : "Export Data")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(isExporting || filteredExpenses.isEmpty)
                }
            }
            .navigationTitle("Export Data")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #endif
            }
        }
    }
    
    private var filteredExpenses: [Expense] {
        let calendar = Calendar.current
        let now = Date()
        
        return expenses.filter { expense in
            switch selectedDateRange {
            case .thisMonth:
                return calendar.isDate(expense.date, equalTo: now, toGranularity: .month)
            case .last3Months:
                return expense.date >= calendar.date(byAdding: .month, value: -3, to: now) ?? now
            case .thisYear:
                return calendar.isDate(expense.date, equalTo: now, toGranularity: .year)
            case .allTime:
                return true
            }
        }
    }
    
    private func exportData() {
        isExporting = true
        
        // Simulate export process
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isExporting = false
            // Here you would implement actual export functionality
            // For now, just dismiss the view
            dismiss()
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}
