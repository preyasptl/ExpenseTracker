//
//  CSVImportView.swift
//  ExpenseTracker
//
//  Created by iMacPro on 13/09/25.
//
import SwiftUI

struct CSVImportView: View {
    @EnvironmentObject var expenseStore: ExpenseStore
    @StateObject private var importManager = CSVImportManager()
    @Environment(\.dismiss) private var dismiss
    @State private var showingFilePicker = false
    @State private var showingSampleSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                if importManager.isImporting {
                    importProgressSection
                } else {
                    // Import options
                    importOptionsSection
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Import from CSV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.commaSeparatedText, .text],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
            .sheet(isPresented: $showingSampleSheet) {
                SampleCSVView()
            }
            .sheet(isPresented: $importManager.showingResults) {
                ImportResultsView(results: importManager.importResults!)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(ThemeColors.primary)
            
            VStack(spacing: 8) {
                Text("Import Expenses from CSV")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("Restore your expenses from a CSV file or migrate data from another app")
                    .font(.subheadline)
                    .foregroundColor(ThemeColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var importProgressSection: some View {
        VStack(spacing: 16) {
            ProgressView("Importing expenses...", value: importManager.importProgress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: ThemeColors.primary))
            
            Text("\(Int(importManager.importProgress * 100))% Complete")
                .font(.caption)
                .foregroundColor(ThemeColors.secondaryText)
        }
        .padding()
        .background(ThemeColors.cardBackground)
        .cornerRadius(12)
    }
    
    private var importOptionsSection: some View {
        VStack(spacing: 16) {
            // View Sample CSV
            Button(action: { showingSampleSheet = true }) {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(ThemeColors.accent)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("View Sample CSV Format")
                            .font(.headline)
                            .foregroundColor(ThemeColors.text)
                        
                        Text("See the required format and download template")
                            .font(.caption)
                            .foregroundColor(ThemeColors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(ThemeColors.secondaryText)
                        .font(.caption)
                }
                .padding()
                .background(ThemeColors.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ThemeColors.accent.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Import CSV File
            Button(action: { showingFilePicker = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(.white)
                        .frame(width: 24)
                    
                    Text("Import CSV File")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding()
                .background(ThemeColors.primaryGradient)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Instructions
            VStack(alignment: .leading, spacing: 12) {
                Text("Instructions:")
                    .font(.headline)
                    .foregroundColor(ThemeColors.text)
                
                VStack(alignment: .leading, spacing: 8) {
                    instructionRow("1.", "Download the sample CSV template")
                    instructionRow("2.", "Add your expense data following the format")
                    instructionRow("3.", "Import the CSV file using the button above")
                    instructionRow("4.", "Review import results and resolve any errors")
                }
            }
            .padding()
            .background(ThemeColors.cardBackground.opacity(0.5))
            .cornerRadius(12)
        }
    }
    
    private func instructionRow(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(ThemeColors.primary)
                .frame(width: 20, alignment: .leading)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(ThemeColors.secondaryText)
            
            Spacer()
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                let csvContent = try String(contentsOf: url)
                Task {
                    await importManager.importFromCSV(csvContent, expenseStore: expenseStore)
                }
            } catch {
                print("Error reading CSV file: \(error)")
            }
            
        case .failure(let error):
            print("File selection error: \(error)")
        }
    }
}
