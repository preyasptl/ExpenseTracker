//
//  ExportDataView.swift
//  ExpenseTracker
//
//  Created by iMacPro on 09/09/25.
//
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Updated ExportDataView with Actual Export Functionality
struct ExportDataView: View {
    let expenses: [Expense]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: ExportFormat = .csv
    @State private var selectedDateRange: DateRange = .allTime
    @State private var includeLentMoney = true
    @State private var includeNotes = true
    @State private var isExporting = false
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?
    
    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case json = "JSON"
        
        var fileExtension: String {
            switch self {
            case .csv: return "csv"
            case .json: return "json"
            }
        }
        
        var contentType: UTType {
            switch self {
            case .csv: return .commaSeparatedText
            case .json: return .json
            }
        }
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
                    
                    if includeLentMoney {
                        let lentAmount = filteredExpenses.filter { $0.isLentMoney }.reduce(0) { $0 + $1.amount }
                        if lentAmount > 0 {
                            HStack {
                                Text("Lent Money")
                                Spacer()
                                Text(formatCurrency(lentAmount))
                                    .fontWeight(.medium)
                                    .foregroundColor(ThemeColors.accent)
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: exportData) {
                        HStack {
                            if isExporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "square.and.arrow.up")
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
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }
    
    // MARK: - Computed Properties
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
        }.sorted { $0.date > $1.date }
    }
    
    // MARK: - Export Functions
    private func exportData() {
        isExporting = true
        
        Task {
            do {
                let fileURL = try await generateExportFile()
                await MainActor.run {
                    self.exportedFileURL = fileURL
                    self.isExporting = false
                    self.showingShareSheet = true
                }
            } catch {
                await MainActor.run {
                    self.isExporting = false
                    print("Export error: \(error)")
                }
            }
        }
    }
    
    private func generateExportFile() async throws -> URL {
        let fileName = "expenses_export_\(dateFormatter.string(from: Date())).\(selectedFormat.fileExtension)"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        let content: String
        switch selectedFormat {
        case .csv:
            content = generateCSVContent()
        case .json:
            content = try generateJSONContent()
        }
        
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    private func generateCSVContent() -> String {
        var csvContent = ""
        
        // Header
        var headers = ["Date", "Title", "Amount", "Category"]
        
        if includeLentMoney {
            headers.append(contentsOf: ["Is Lent Money", "Lent To Person", "Is Repaid", "Repaid Date"])
        }
        
        headers.append("Payment Mode")
        
        if includeNotes {
            headers.append("Notes")
        }
        
        csvContent += headers.joined(separator: ",") + "\n"
        
        // Data rows
        for expense in filteredExpenses {
            var row: [String] = []
            
            // Basic fields
            row.append(dateFormatter.string(from: expense.date))
            row.append("\"\(expense.title.replacingOccurrences(of: "\"", with: "\"\""))\"")
            row.append("\(expense.amount)")
            row.append(expense.category.rawValue)
            
            // Lent money fields
            if includeLentMoney {
                row.append(expense.isLentMoney ? "Yes" : "No")
                row.append("\"\(expense.lentToPersonName ?? "")\"")
                row.append(expense.isRepaid ? "Yes" : "No")
                row.append(expense.repaidDate != nil ? dateFormatter.string(from: expense.repaidDate!) : "")
            }
            
            // Payment mode
            row.append("\"\(expense.paymentMode.name)\"")
            
            // Notes
            if includeNotes {
                let notes = expense.notes?.replacingOccurrences(of: "\"", with: "\"\"") ?? ""
                row.append("\"\(notes)\"")
            }
            
            csvContent += row.joined(separator: ",") + "\n"
        }
        
        return csvContent
    }
    
    private func generateJSONContent() throws -> String {
        let exportData = filteredExpenses.map { expense -> [String: Any] in
            var data: [String: Any] = [
                "id": expense.id.uuidString,
                "date": dateFormatter.string(from: expense.date),
                "title": expense.title,
                "amount": expense.amount,
                "category": expense.category.rawValue,
                "paymentMode": [
                    "name": expense.paymentMode.name,
                    "icon": expense.paymentMode.icon,
                    "color": expense.paymentMode.color
                ]
            ]
            
            if includeLentMoney {
                data["isLentMoney"] = expense.isLentMoney
                if expense.isLentMoney {
                    data["lentToPersonName"] = expense.lentToPersonName ?? ""
                    data["isRepaid"] = expense.isRepaid
                    if let repaidDate = expense.repaidDate {
                        data["repaidDate"] = dateFormatter.string(from: repaidDate)
                    }
                }
            }
            
            if includeNotes, let notes = expense.notes, !notes.isEmpty {
                data["notes"] = notes
            }
            
            return data
        }
        
        let exportObject: [String: Any] = [
            "exportInfo": [
                "exportDate": dateFormatter.string(from: Date()),
                "dateRange": selectedDateRange.rawValue,
                "totalExpenses": filteredExpenses.count,
                "totalAmount": filteredExpenses.reduce(0) { $0 + $1.amount },
                "includeLentMoney": includeLentMoney,
                "includeNotes": includeNotes
            ],
            "expenses": exportData
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: exportObject, options: .prettyPrinted)
        return String(data: jsonData, encoding: .utf8) ?? ""
    }
    
    // MARK: - Helper Methods
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }
}

// MARK: - Share Sheet for iOS
#if os(iOS)
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

// MARK: - Share Sheet for macOS
#if os(macOS)
struct ShareSheet: NSViewRepresentable {
    let activityItems: [Any]
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        
        DispatchQueue.main.async {
            guard let url = activityItems.first as? URL else { return }
            
            let sharingServicePicker = NSSharingServicePicker(items: [url])
            sharingServicePicker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}
#endif
