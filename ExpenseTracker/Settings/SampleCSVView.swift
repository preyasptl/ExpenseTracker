//
//  SampleCSVView.swift
//  ExpenseTracker
//
//  Created by iMacPro on 13/09/25.
//
import SwiftUI

// MARK: - Sample CSV View
struct SampleCSVView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("CSV Template")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Use this format for importing your expenses")
                        .font(.subheadline)
                        .foregroundColor(ThemeColors.secondaryText)
                }
                .padding()
                
                // CSV content
                ScrollView {
                    Text(CSVImportManager.sampleCSVContent)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(ThemeColors.cardBackground)
                        .cornerRadius(8)
                }
                
                // Field descriptions
                fieldDescriptions
                
                Spacer()
                
                // Download button
                Button(action: { showingShareSheet = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Download Template")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(ThemeColors.primaryGradient)
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("CSV Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let csvData = CSVImportManager.sampleCSVContent.data(using: .utf8) {
                    let url = createTempCSVFile(data: csvData)
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }
    
    private var fieldDescriptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Field Descriptions:")
                .font(.headline)
                .foregroundColor(ThemeColors.text)
            
            VStack(alignment: .leading, spacing: 6) {
                fieldDescription("Date", "Format: YYYY-MM-DD (e.g., 2024-01-15)", required: true)
                fieldDescription("Title", "Expense description", required: true)
                fieldDescription("Amount", "Numeric value (e.g., 4.50)", required: true)
                fieldDescription("Category", "Food, Transportation, Entertainment, Shopping, Bills, Health, Other", required: true)
                fieldDescription("Is Lent Money", "Yes or No", required: false)
                fieldDescription("Lent To Person", "Person's name (if lent money)", required: false)
                fieldDescription("Is Repaid", "Yes or No", required: false)
                fieldDescription("Repaid Date", "Format: YYYY-MM-DD", required: false)
                fieldDescription("Payment Mode", "Payment method name", required: false)
                fieldDescription("Notes", "Additional notes", required: false)
            }
        }
        .padding()
        .background(ThemeColors.cardBackground.opacity(0.5))
        .cornerRadius(12)
    }
    
    private func fieldDescription(_ name: String, _ description: String, required: Bool) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(name)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(required ? ThemeColors.primary : ThemeColors.accent)
                .frame(width: 100, alignment: .leading)
            
            Text(description)
                .font(.caption)
                .foregroundColor(ThemeColors.secondaryText)
            
            Spacer()
        }
    }
    
    private func createTempCSVFile(data: Data) -> URL {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("expense_template.csv")
        try? data.write(to: tempURL)
        return tempURL
    }
}
