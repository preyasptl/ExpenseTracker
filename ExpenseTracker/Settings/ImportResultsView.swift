//
//  ImportResultsView.swift
//  ExpenseTracker
//
//  Created by iMacPro on 13/09/25.
//
import SwiftUI

// MARK: - Import Results View
struct ImportResultsView: View {
    let results: CSVImportManager.ImportResults
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Results summary
                VStack(spacing: 16) {
                    Image(systemName: results.hasErrors ? "exclamationmark.triangle" : "checkmark.circle")
                        .font(.system(size: 60))
                        .foregroundColor(results.hasErrors ? ThemeColors.accent : ThemeColors.success)
                    
                    Text("Import Complete")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Successfully imported \(results.successfulImports) of \(results.totalRows) expenses")
                        .font(.subheadline)
                        .foregroundColor(ThemeColors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                // Statistics
                VStack(spacing: 12) {
                    resultRow("Total Rows", "\(results.totalRows)")
                    resultRow("Successful", "\(results.successfulImports)", color: ThemeColors.success)
                    resultRow("Failed", "\(results.failedImports)", color: results.failedImports > 0 ? ThemeColors.error : ThemeColors.secondaryText)
                    resultRow("Duplicates Skipped", "\(results.duplicates)", color: ThemeColors.accent)
                    resultRow("Success Rate", "\(Int(results.successRate * 100))%", color: ThemeColors.primary)
                }
                .padding()
                .background(ThemeColors.cardBackground)
                .cornerRadius(12)
                
                // Errors (if any)
                if results.hasErrors {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Errors:")
                            .font(.headline)
                            .foregroundColor(ThemeColors.error)
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(Array(results.errors.enumerated()), id: \.offset) { index, error in
                                    Text("• \(error)")
                                        .font(.caption)
                                        .foregroundColor(ThemeColors.secondaryText)
                                }
                            }
                        }
                        .frame(maxHeight: 120)
                    }
                    .padding()
                    .background(ThemeColors.error.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Import Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func resultRow(_ label: String, _ value: String, color: Color = ThemeColors.text) -> some View {
        HStack {
            Text(label)
                .foregroundColor(ThemeColors.secondaryText)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}
