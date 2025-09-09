//
//  SettingsView.swift
//  ExpenseTracker
//
//  Created by iMacPro on 09/09/25.
//


import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var expenseStore: ExpenseStore
    @StateObject private var paymentModeStore = PaymentModeStore()
    @State private var showingAddPaymentMode = false
    @State private var showingExportSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var paymentModeToDelete: PaymentMode?
    @State private var selectedCurrency = "USD"
    @State private var showingSyncStatus = false
    
    private let currencies = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "INR", "CNY"]
    
    var body: some View {
        NavigationView {
            List {
                // Sync & Data Section
                syncDataSection
                
                // Payment Modes Section
                paymentModesSection
                
                // Export & Backup Section
                exportSection
                
                // App Preferences Section
                preferencesSection
                
                // About Section
                aboutSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAddPaymentMode) {
                AddPaymentModeView(paymentModeStore: paymentModeStore)
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportDataView(expenses: expenseStore.expenses)
            }
            .sheet(isPresented: $showingSyncStatus) {
                SyncStatusView()
                    .environmentObject(expenseStore)
            }
            .alert("Delete Payment Mode", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let paymentMode = paymentModeToDelete {
                        paymentModeStore.deletePaymentMode(paymentMode)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this payment mode? This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Sync & Data Section
    private var syncDataSection: some View {
        Section("Sync & Data") {
            // Sync Status
            HStack {
                Image(systemName: "icloud.and.arrow.up")
                    .foregroundColor(syncStatusColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sync Status")
                        .font(.subheadline)
                    Text(expenseStore.syncStatus)
                        .font(.caption)
                        .foregroundColor(ThemeColors.secondaryText)
                }
                
                Spacer()
                
                Button("Details") {
                    showingSyncStatus = true
                }
                .font(.caption)
                .foregroundColor(ThemeColors.primary)
            }
            
            // Manual Sync
            Button(action: performManualSync) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(ThemeColors.primary)
                    Text("Sync Now")
                    Spacer()
                }
            }
            
            // Data Summary
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                    .foregroundColor(ThemeColors.accent)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Expenses")
                        .font(.subheadline)
                    Text("\(expenseStore.expenses.count) entries")
                        .font(.caption)
                        .foregroundColor(ThemeColors.secondaryText)
                }
                
                Spacer()
                
                Text(formatCurrency(expenseStore.totalExpenses))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
    }
    
    // MARK: - Payment Modes Section
    private var paymentModesSection: some View {
        Section("Payment Modes") {
            // Add new payment mode
            Button(action: { showingAddPaymentMode = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(ThemeColors.primary)
                    Text("Add Payment Mode")
                        .foregroundColor(ThemeColors.primary)
                    Spacer()
                }
            }
            
            // Existing payment modes
            ForEach(paymentModeStore.paymentModes, id: \.id) { paymentMode in
                HStack {
                    Image(systemName: paymentMode.icon)
                        .foregroundColor(paymentMode.swiftUIColor)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(paymentMode.name)
                                .font(.subheadline)
                            
                            if paymentMode.isDefault {
                                Text("DEFAULT")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(ThemeColors.accent.opacity(0.2))
                                    .foregroundColor(ThemeColors.accent)
                                    .cornerRadius(4)
                            }
                        }
                        
                        if !paymentMode.isDefault {
                            Button("Set as Default") {
                                paymentModeStore.setDefaultPaymentMode(paymentMode)
                            }
                            .font(.caption)
                            .foregroundColor(ThemeColors.primary)
                        }
                    }
                    
                    Spacer()
                    
                    if !paymentMode.isDefault {
                        Button(action: {
                            paymentModeToDelete = paymentMode
                            showingDeleteConfirmation = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    // MARK: - Export Section
    private var exportSection: some View {
        Section("Export & Backup") {
            Button(action: { showingExportSheet = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(ThemeColors.success)
                    Text("Export Data")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(ThemeColors.secondaryText)
                }
            }
            
            Button(action: shareAppData) {
                HStack {
                    Image(systemName: "paperplane")
                        .foregroundColor(ThemeColors.primary)
                    Text("Share Expenses")
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Preferences Section
    private var preferencesSection: some View {
        Section("Preferences") {
            // Currency Selection
            HStack {
                Image(systemName: "dollarsign.circle")
                    .foregroundColor(ThemeColors.primary)
                Text("Currency")
                Spacer()
                Picker("Currency", selection: $selectedCurrency) {
                    ForEach(currencies, id: \.self) { currency in
                        Text(currency).tag(currency)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            // Notifications (placeholder)
            HStack {
                Image(systemName: "bell")
                    .foregroundColor(ThemeColors.accent)
                Text("Notifications")
                Spacer()
                Toggle("", isOn: .constant(false))
                    .disabled(true) // Placeholder
            }
            
            // Theme (placeholder)
            HStack {
                Image(systemName: "paintbrush")
                    .foregroundColor(ThemeColors.success)
                Text("Theme")
                Spacer()
                Text("System")
                    .foregroundColor(ThemeColors.secondaryText)
                    .font(.subheadline)
            }
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        Section("About") {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(ThemeColors.primary)
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(ThemeColors.secondaryText)
                    .font(.subheadline)
            }
            
            Button(action: openPrivacyPolicy) {
                HStack {
                    Image(systemName: "hand.raised")
                        .foregroundColor(ThemeColors.accent)
                    Text("Privacy Policy")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundColor(ThemeColors.secondaryText)
                }
            }
            
            Button(action: contactSupport) {
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(ThemeColors.success)
                    Text("Contact Support")
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Computed Properties
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
    
    // MARK: - Helper Methods
    private func performManualSync() {
        expenseStore.performManualSync()
    }
    
    private func shareAppData() {
        // Implement share functionality
        print("Sharing app data...")
    }
    
    private func openPrivacyPolicy() {
        // Open privacy policy URL
        print("Opening privacy policy...")
    }
    
    private func contactSupport() {
        // Open support contact
        print("Contacting support...")
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}
