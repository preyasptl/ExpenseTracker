//
//  SettingsView.swift
//  ExpenseTracker
//
//  Created by iMacPro on 09/09/25.
//


import SwiftUI
import MessageUI

struct SettingsView: View {
    @EnvironmentObject var expenseStore: ExpenseStore
    @StateObject private var paymentModeStore = PaymentModeStore()
    @State private var showingAddPaymentMode = false
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var paymentModeToDelete: PaymentMode?
    @State private var selectedCurrency = "USD"
    @State private var showingSyncStatus = false
    
    @StateObject private var currencyManager = CurrencyManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    
    private let currencies = Currency.allCurrencies
    
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
                functionalPreferencesSection
                
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
            .sheet(isPresented: $showingImportSheet) {
                CSVImportView().environmentObject(expenseStore)
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
        Section("Data Management") {
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
            
            Button(action: { showingImportSheet = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(ThemeColors.primary)
                    Text("Import from CSV")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(ThemeColors.secondaryText)
                }
            }
            
            Button(action: shareAppData) {
                HStack {
                    Image(systemName: "paperplane")
                        .foregroundColor(ThemeColors.accent)
                    Text("Share Summary")
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Preferences Section
    var functionalPreferencesSection: some View {
        Section("Preferences") {
            // Currency Selection
            NavigationLink(destination: CurrencySelectionView()) {
                HStack {
                    Image(systemName: "dollarsign.circle")
                        .foregroundColor(ThemeColors.primary)
                    Text("Currency")
                    Spacer()
                    Text(currencyManager.selectedCurrency.code)
                        .foregroundColor(ThemeColors.secondaryText)
                        .font(.subheadline)
                }
            }
            
            // Theme Selection
            NavigationLink(destination: ThemeSelectionView()) {
                HStack {
                    Image(systemName: "paintbrush")
                        .foregroundColor(ThemeColors.success)
                    Text("Theme")
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: themeManager.selectedTheme.icon)
                            .font(.caption)
                        Text(themeManager.selectedTheme.displayName)
                    }
                    .foregroundColor(ThemeColors.secondaryText)
                    .font(.subheadline)
                }
            }
            
            // Notifications - Now Functional
            NavigationLink(destination: NotificationSettingsView().environmentObject(expenseStore)) {
                HStack {
                    Image(systemName: "bell")
                        .foregroundColor(ThemeColors.accent)
                    Text("Notifications")
                    Spacer()
                    HStack(spacing: 4) {
                        if notificationManager.isNotificationsEnabled {
                            let activeCount = [
                                notificationManager.dailyReminderEnabled,
                                notificationManager.weeklyReportEnabled,
                                notificationManager.lentMoneyRemindersEnabled
                            ].filter { $0 }.count
                            
                            if activeCount > 0 {
                                Text("\(activeCount) active")
                                    .foregroundColor(ThemeColors.accent)
                            } else {
                                Text("Enabled")
                                    .foregroundColor(ThemeColors.success)
                            }
                        } else {
                            Text("Off")
                                .foregroundColor(ThemeColors.secondaryText)
                        }
                    }
                    .font(.subheadline)
                }
            }
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        Section("About") {
            // App Version
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(ThemeColors.primary)
                Text("Version")
                Spacer()
                Text(Bundle.main.appVersion)
                    .foregroundColor(ThemeColors.secondaryText)
                    .font(.subheadline)
            }
            
            // Build Number (for debugging)
            HStack {
                Image(systemName: "hammer")
                    .foregroundColor(ThemeColors.secondary)
                Text("Build")
                Spacer()
                Text(Bundle.main.buildNumber)
                    .foregroundColor(ThemeColors.secondaryText)
                    .font(.subheadline)
            }
            
            // Privacy Policy
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
            
            // Contact Support
            Button(action: contactSupport) {
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(ThemeColors.success)
                    Text("Contact Support")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(ThemeColors.secondaryText)
                }
            }
            
            // Rate App
            Button(action: rateApp) {
                HStack {
                    Image(systemName: "star")
                        .foregroundColor(ThemeColors.primary)
                    Text("Rate App")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundColor(ThemeColors.secondaryText)
                }
            }
            
            // App Website
            Button(action: openWebsite) {
                HStack {
                    Image(systemName: "globe")
                        .foregroundColor(ThemeColors.accent)
                    Text("Website")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundColor(ThemeColors.secondaryText)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private func rateApp() {
#if os(iOS)
        if let url = URL(string: "itms-apps://itunes.apple.com/app/id123456789") {
            UIApplication.shared.open(url)
        }
#elseif os(macOS)
        if let url = URL(string: "macappstore://itunes.apple.com/app/id123456789") {
            NSWorkspace.shared.open(url)
        }
#endif
    }
    
    private func openWebsite() {
        let websiteURL = "https://your-app-website.com"
        
#if os(iOS)
        if let url = URL(string: websiteURL) {
            UIApplication.shared.open(url)
        }
#elseif os(macOS)
        if let url = URL(string: websiteURL) {
            NSWorkspace.shared.open(url)
        }
#endif
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
    
    // MARK: - Helper Methods
    private func performManualSync() {
        expenseStore.performManualSync()
    }
    
    //    private func openPrivacyPolicy() {
    //        // Open privacy policy URL
    //        print("Opening privacy policy...")
    //    }
    //
    //    private func contactSupport() {
    //        // Open support contact
    //        print("Contacting support...")
    //    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = currencyManager.currentLocale
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

struct CurrencySelectionView: View {
    @StateObject private var currencyManager = CurrencyManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section {
                ForEach(Currency.allCurrencies) { currency in
                    Button(action: {
                        currencyManager.selectedCurrency = currency
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(currency.name)
                                    .font(.subheadline)
                                    .foregroundColor(ThemeColors.text)
                                
                                Text("\(currency.code) • \(currency.symbol)")
                                    .font(.caption)
                                    .foregroundColor(ThemeColors.secondaryText)
                            }
                            
                            Spacer()
                            
                            // Sample amount formatting
                            Text(currencyManager.formatCurrency(1234.56))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(ThemeColors.primary)
                            
                            if currency.code == currencyManager.selectedCurrency.code {
                                Image(systemName: "checkmark")
                                    .foregroundColor(ThemeColors.primary)
                                    .font(.headline)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            } header: {
                Text("Select your preferred currency for displaying amounts throughout the app")
                    .font(.caption)
                    .foregroundColor(ThemeColors.secondaryText)
            }
        }
        .navigationTitle("Currency")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Updated Currency Formatting Extensions
extension Double {
    func formattedAsCurrency() -> String {
        return CurrencyManager.shared.formatCurrency(self)
    }
    
    func formattedAsCurrencyShort() -> String {
        return CurrencyManager.shared.formatCurrencyShort(self)
    }
}

// MARK: - Update Expense Model Extension

extension SettingsView {
    func shareAppData() {
        // Generate comprehensive expense summary
        let summary = generateExpenseSummary()
        
#if os(iOS)
        presentShareSheet(with: summary)
#else
        copyToClipboard(summary)
#endif
    }
    
    private func generateExpenseSummary() -> String {
        let expenses = expenseStore.expenses
        let totalExpenses = expenses.count
        let totalAmount = expenses.reduce(0) { $0 + $1.amount }
        
        // Lent money calculations
        let lentExpenses = expenses.filter { $0.isLentMoney }
        let lentAmount = lentExpenses.reduce(0) { $0 + $1.amount }
        let outstandingExpenses = lentExpenses.filter { !$0.isRepaid }
        let outstandingAmount = outstandingExpenses.reduce(0) { $0 + $1.amount }
        let repaidAmount = lentAmount - outstandingAmount
        
        // Time period calculations
        let calendar = Calendar.current
        let now = Date()
        
        let thisMonthExpenses = expenses.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
        let thisMonthAmount = thisMonthExpenses.reduce(0) { $0 + $1.amount }
        
        let last30DaysExpenses = expenses.filter {
            $0.date >= calendar.date(byAdding: .day, value: -30, to: now) ?? now
        }
        let last30DaysAmount = last30DaysExpenses.reduce(0) { $0 + $1.amount }
        
        // Category breakdown
        let categoryTotals = Dictionary(grouping: expenses) { $0.category }
            .mapValues { expenses in expenses.reduce(0) { $0 + $1.amount } }
            .sorted { $0.value > $1.value }
        
        // Payment mode breakdown
        let paymentTotals = Dictionary(grouping: expenses) { $0.paymentMode.name }
            .mapValues { expenses in expenses.reduce(0) { $0 + $1.amount } }
            .sorted { $0.value > $1.value }
        
        // Recent expenses (last 5)
        let recentExpenses = expenses.sorted { $0.date > $1.date }.prefix(5)
        
        // Generate formatted summary
        var summary = """
        📊 My Expense Tracker Summary
        Generated on \(DateFormatter.shared.string(from: now))
        
        💰 OVERALL SUMMARY
        Total Expenses: \(totalExpenses) entries
        Total Amount: \(formatCurrency(totalAmount))
        Currency: \(CurrencyManager.shared.selectedCurrency.code)
        
        📅 TIME PERIODS
        This Month: \(formatCurrency(thisMonthAmount)) (\(thisMonthExpenses.count) expenses)
        Last 30 Days: \(formatCurrency(last30DaysAmount)) (\(last30DaysExpenses.count) expenses)
        """
        
        // Add lent money section if applicable
        if !lentExpenses.isEmpty {
            summary += """
            
            💸 LENT MONEY TRACKING
            Total Lent: \(formatCurrency(lentAmount)) (\(lentExpenses.count) transactions)
            Repaid: \(formatCurrency(repaidAmount))
            Outstanding: \(formatCurrency(outstandingAmount)) (\(outstandingExpenses.count) pending)
            """
            
            // Outstanding details
            if !outstandingExpenses.isEmpty {
                summary += "\n\nOutstanding Loans:"
                for expense in outstandingExpenses.sorted { $0.amount > $1.amount }.prefix(3) {
                    let personName = expense.lentToPersonName ?? "Unknown"
                    summary += "\n• \(personName): \(formatCurrency(expense.amount))"
                }
                if outstandingExpenses.count > 3 {
                    summary += "\n• ... and \(outstandingExpenses.count - 3) more"
                }
            }
        }
        
        // Top categories
        summary += """
        
        📂 TOP SPENDING CATEGORIES
        """
        
        for (index, category) in categoryTotals.prefix(5).enumerated() {
            let percentage = (category.value / totalAmount) * 100
            summary += "\n\(index + 1). \(category.key.rawValue): \(formatCurrency(category.value)) (\(Int(percentage))%)"
        }
        
        // Payment methods
        if paymentTotals.count > 1 {
            summary += """
            
            💳 PAYMENT METHODS
            """
            
            for (index, payment) in paymentTotals.prefix(3).enumerated() {
                let percentage = (payment.value / totalAmount) * 100
                summary += "\n\(index + 1). \(payment.key): \(formatCurrency(payment.value)) (\(Int(percentage))%)"
            }
        }
        
        // Recent activity
        if !recentExpenses.isEmpty {
            summary += """
            
            🕒 RECENT ACTIVITY
            """
            
            for expense in recentExpenses {
                let dateStr = DateFormatter.shortDate.string(from: expense.date)
                let lentIndicator = expense.isLentMoney ? (expense.isRepaid ? "✅" : "⏳") : ""
                summary += "\n• \(dateStr): \(expense.title) - \(formatCurrency(expense.amount)) \(lentIndicator)"
            }
        }
        
        // Average spending
        let daysSinceFirstExpense = expenses.isEmpty ? 1 :
        max(1, calendar.dateComponents([.day], from: expenses.map { $0.date }.min() ?? now, to: now).day ?? 1)
        let averagePerDay = totalAmount / Double(daysSinceFirstExpense)
        
        summary += """
        
        📈 SPENDING INSIGHTS
        Average per day: \(formatCurrency(averagePerDay))
        Tracking period: \(daysSinceFirstExpense) days
        Most expensive: \(expenses.max { $0.amount < $1.amount }?.title ?? "None") (\(formatCurrency(expenses.max { $0.amount < $1.amount }?.amount ?? 0)))
        """
        
        summary += """
        
        Generated by ExpenseTracker App
        """
        
        return summary
    }
    
#if os(iOS)
    private func presentShareSheet(with content: String) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: [content],
            applicationActivities: nil
        )
        
        // Configure for iPad
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        rootViewController.present(activityViewController, animated: true)
    }
#endif
    
#if os(macOS)
    private func copyToClipboard(_ content: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
        
        // Could add a toast notification here to indicate copy success
        print("Summary copied to clipboard")
    }
#endif
    
    func openPrivacyPolicy() {
        let privacyURL = "https://your-app-website.com/privacy"
        
#if os(iOS)
        if let url = URL(string: privacyURL) {
            UIApplication.shared.open(url)
        }
#elseif os(macOS)
        if let url = URL(string: privacyURL) {
            NSWorkspace.shared.open(url)
        }
#endif
    }
    
    func contactSupport() {
#if os(iOS)
        presentSupportOptions()
#elseif os(macOS)
        openMailClient()
#endif
    }
    
#if os(iOS)
    private func presentSupportOptions() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        let alertController = UIAlertController(
            title: "Contact Support",
            message: "How would you like to get help?",
            preferredStyle: .actionSheet
        )
        
        // Email option
        alertController.addAction(UIAlertAction(title: "Send Email", style: .default) { _ in
            self.openMailComposer()
        })
        
        // Copy email option
        alertController.addAction(UIAlertAction(title: "Copy Email Address", style: .default) { _ in
            UIPasteboard.general.string = "support@expensetracker.com"
            // You could show a toast here to confirm copy
        })
        
        // Cancel option
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Configure for iPad
        if let popover = alertController.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        rootViewController.present(alertController, animated: true)
    }
    
    private func openMailComposer() {
        guard MFMailComposeViewController.canSendMail() else {
            // Fallback to copying email address
            UIPasteboard.general.string = "support@expensetracker.com"
            return
        }
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = MailDelegate.shared
        mailComposer.setToRecipients(["support@expensetracker.com"])
        mailComposer.setSubject("ExpenseTracker Support Request")
        
        let deviceInfo = """
            
            
            ---
            Device Information:
            App Version: 1.0.0
            iOS Version: \(UIDevice.current.systemVersion)
            Device Model: \(UIDevice.current.model)
            Total Expenses: \(expenseStore.expenses.count)
            """
        
        mailComposer.setMessageBody("Hi ExpenseTracker Support,\n\nI need help with:\n\n[Please describe your issue here]\n\(deviceInfo)", isHTML: false)
        
        rootViewController.present(mailComposer, animated: true)
    }
#endif
    
#if os(macOS)
    private func openMailClient() {
        let subject = "ExpenseTracker Support Request"
        let body = """
            Hi ExpenseTracker Support,
            
            I need help with:
            
            [Please describe your issue here]
            
            
            ---
            Device Information:
            App Version: 1.0.0
            macOS Version: \(ProcessInfo.processInfo.operatingSystemVersionString)
            Total Expenses: \(expenseStore.expenses.count)
            """
        
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let mailtoURL = "mailto:support@expensetracker.com?subject=\(encodedSubject)&body=\(encodedBody)"
        
        if let url = URL(string: mailtoURL) {
            NSWorkspace.shared.open(url)
        }
    }
#endif
}

extension DateFormatter {
    static let shared: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter
    }()
}

// MARK: - Mail Delegate for iOS
#if os(iOS)
class MailDelegate: NSObject, MFMailComposeViewControllerDelegate {
    static let shared = MailDelegate()
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
#endif


extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var appName: String {
        return infoDictionary?["CFBundleDisplayName"] as? String ??
        infoDictionary?["CFBundleName"] as? String ?? "ExpenseTracker"
    }
}
