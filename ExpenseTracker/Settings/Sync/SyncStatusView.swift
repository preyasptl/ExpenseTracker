//
//  SyncStatusView.swift
//  ExpenseTracker
//
//  Created by iMacPro on 09/09/25.
//
import SwiftUI

struct SyncStatusView: View {
    @EnvironmentObject var expenseStore: ExpenseStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Current Status") {
                    HStack {
                        Circle()
                            .fill(syncStatusColor)
                            .frame(width: 12, height: 12)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sync Status")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(expenseStore.syncStatus)
                                .font(.caption)
                                .foregroundColor(ThemeColors.secondaryText)
                        }
                        
                        Spacer()
                    }
                    
                    if let lastSync = expenseStore.lastSyncDate {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(ThemeColors.secondaryText)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Last Sync")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(formatDate(lastSync))
                                    .font(.caption)
                                    .foregroundColor(ThemeColors.secondaryText)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    if expenseStore.hasPendingChanges {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(ThemeColors.accent)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Pending Changes")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Some changes are waiting to sync")
                                    .font(.caption)
                                    .foregroundColor(ThemeColors.secondaryText)
                            }
                            
                            Spacer()
                        }
                    }
                }
                
                Section("Actions") {
                    Button("Sync Now") {
                        expenseStore.performManualSync()
                    }
                }
            }
            .navigationTitle("Sync Status")
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
    
    private var syncStatusColor: Color {
        switch expenseStore.syncStatus {
        case "Ready", "Synced":
            return ThemeColors.success
        case let status where status.contains("Syncing"):
            return ThemeColors.accent
        case let status where status.contains("Error"):
            return ThemeColors.error
        default:
            return ThemeColors.secondaryText
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
