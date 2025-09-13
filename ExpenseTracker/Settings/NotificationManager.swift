//
//  NotificationManager.swift
//  ExpenseTracker
//
//  Created by iMacPro on 11/09/25.
//


import SwiftUI
import UserNotifications

// MARK: - Notification Manager
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isNotificationsEnabled = false
    @Published var dailyReminderEnabled = false
    @Published var weeklyReportEnabled = false
    @Published var lentMoneyRemindersEnabled = false
    @Published var dailyReminderTime = Date()
    
    private let center = UNUserNotificationCenter.current()
    
    private init() {
        loadSettings()
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                self.isNotificationsEnabled = granted
                self.saveSettings()
            }
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }
    
    func checkAuthorizationStatus() {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isNotificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Notification Scheduling
    func scheduleDailyReminder() {
        guard isNotificationsEnabled && dailyReminderEnabled else { return }
        
        // Remove existing daily reminders
        center.removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])
        
        let content = UNMutableNotificationContent()
        content.title = "Track Your Expenses"
        content.body = "Don't forget to log today's expenses!"
        content.sound = .default
        content.badge = 1
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: dailyReminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily_reminder",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling daily reminder: \(error)")
            }
        }
    }
    
    func scheduleWeeklyReport() {
        guard isNotificationsEnabled && weeklyReportEnabled else { return }
        
        // Remove existing weekly reports
        center.removePendingNotificationRequests(withIdentifiers: ["weekly_report"])
        
        let content = UNMutableNotificationContent()
        content.title = "Weekly Expense Report"
        content.body = "Check out your spending summary for this week!"
        content.sound = .default
        
        // Schedule for Sunday at 6 PM
        var components = DateComponents()
        components.weekday = 1 // Sunday
        components.hour = 18
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "weekly_report",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling weekly report: \(error)")
            }
        }
    }
    
    func scheduleLentMoneyReminders(for expenses: [Expense]) {
        guard isNotificationsEnabled && lentMoneyRemindersEnabled else { return }
        
        // Remove existing lent money reminders
        center.removePendingNotificationRequests(withIdentifiers: expenses.map { "lent_\($0.id.uuidString)" })
        
        let outstandingLoans = expenses.filter { $0.isLentMoney && !$0.isRepaid }
        
        for expense in outstandingLoans {
            // Schedule reminder 7 days after lending
            let reminderDate = Calendar.current.date(byAdding: .day, value: 7, to: expense.date) ?? Date()
            
            // Only schedule if the reminder date is in the future
            guard reminderDate > Date() else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = "Outstanding Loan Reminder"
            content.body = "You lent \(expense.formattedAmount) to \(expense.lentToPersonName ?? "someone"). Consider following up!"
            content.sound = .default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: reminderDate.timeIntervalSinceNow, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "lent_\(expense.id.uuidString)",
                content: content,
                trigger: trigger
            )
            
            center.add(request) { error in
                if let error = error {
                    print("Error scheduling lent money reminder: \(error)")
                }
            }
        }
    }
    
    // MARK: - Settings Management
    func updateDailyReminder(_ enabled: Bool) {
        dailyReminderEnabled = enabled
        saveSettings()
        
        if enabled {
            scheduleDailyReminder()
        } else {
            center.removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])
        }
    }
    
    func updateWeeklyReport(_ enabled: Bool) {
        weeklyReportEnabled = enabled
        saveSettings()
        
        if enabled {
            scheduleWeeklyReport()
        } else {
            center.removePendingNotificationRequests(withIdentifiers: ["weekly_report"])
        }
    }
    
    func updateLentMoneyReminders(_ enabled: Bool) {
        lentMoneyRemindersEnabled = enabled
        saveSettings()
        
        if !enabled {
            // Remove all lent money reminders
            center.getPendingNotificationRequests { requests in
                let lentIdentifiers = requests.filter { $0.identifier.hasPrefix("lent_") }.map { $0.identifier }
                self.center.removePendingNotificationRequests(withIdentifiers: lentIdentifiers)
            }
        }
    }
    
    func updateDailyReminderTime(_ time: Date) {
        dailyReminderTime = time
        saveSettings()
        
        if dailyReminderEnabled {
            scheduleDailyReminder()
        }
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(isNotificationsEnabled, forKey: "notificationsEnabled")
        UserDefaults.standard.set(dailyReminderEnabled, forKey: "dailyReminderEnabled")
        UserDefaults.standard.set(weeklyReportEnabled, forKey: "weeklyReportEnabled")
        UserDefaults.standard.set(lentMoneyRemindersEnabled, forKey: "lentMoneyRemindersEnabled")
        UserDefaults.standard.set(dailyReminderTime, forKey: "dailyReminderTime")
    }
    
    private func loadSettings() {
        dailyReminderEnabled = UserDefaults.standard.bool(forKey: "dailyReminderEnabled")
        weeklyReportEnabled = UserDefaults.standard.bool(forKey: "weeklyReportEnabled")
        lentMoneyRemindersEnabled = UserDefaults.standard.bool(forKey: "lentMoneyRemindersEnabled")
        
        if let savedTime = UserDefaults.standard.object(forKey: "dailyReminderTime") as? Date {
            dailyReminderTime = savedTime
        } else {
            // Default to 8 PM
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = 20
            components.minute = 0
            dailyReminderTime = calendar.date(from: components) ?? Date()
        }
    }
}
// MARK: - Notification Settings View
struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @EnvironmentObject var expenseStore: ExpenseStore
    @Environment(\.dismiss) private var dismiss
    @State private var showingPermissionAlert = false
    
    var body: some View {
        List {
            // Main toggle
            Section {
                HStack {
                    Image(systemName: "bell.badge")
                        .foregroundColor(ThemeColors.primary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable Notifications")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(notificationManager.isNotificationsEnabled ? "Notifications are enabled" : "Allow notifications to get reminders")
                            .font(.caption)
                            .foregroundColor(ThemeColors.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Fixed code:
                    Toggle("", isOn: Binding(
                        get: { notificationManager.isNotificationsEnabled },
                        set: { enabled in
                            if enabled {
                                requestPermission()
                            } else {
                                // User wants to disable notifications
                                notificationManager.isNotificationsEnabled = false
                                notificationManager.updateDailyReminder(false)
                                notificationManager.updateWeeklyReport(false)
                                notificationManager.updateLentMoneyReminders(false)
                                
                                // Remove all pending notifications
                                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                            }
                        }
                    ))
                }
            } footer: {
                if !notificationManager.isNotificationsEnabled {
                    Button("Enable Notifications") {
                        requestPermission()
                    }
                    .foregroundColor(ThemeColors.primary)
                }
            }
            
            // Notification types (only shown if notifications are enabled)
            if notificationManager.isNotificationsEnabled {
                Section("Reminder Types") {
                    // Daily reminder
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(ThemeColors.accent)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Daily Reminder")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("Remind me to track expenses")
                                    .font(.caption)
                                    .foregroundColor(ThemeColors.secondaryText)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { notificationManager.dailyReminderEnabled },
                                set: { notificationManager.updateDailyReminder($0) }
                            ))
                        }
                        
                        if notificationManager.dailyReminderEnabled {
                            HStack {
                                Text("Time:")
                                    .font(.caption)
                                    .foregroundColor(ThemeColors.secondaryText)
                                
                                DatePicker("", selection: Binding(
                                    get: { notificationManager.dailyReminderTime },
                                    set: { notificationManager.updateDailyReminderTime($0) }
                                ), displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .scaleEffect(0.9)
                            }
                            .padding(.leading, 24)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.easeInOut, value: notificationManager.dailyReminderEnabled)
                    
                    // Weekly report
                    HStack {
                        Image(systemName: "chart.bar")
                            .foregroundColor(ThemeColors.success)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Weekly Report")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("Sunday evening spending summary")
                                .font(.caption)
                                .foregroundColor(ThemeColors.secondaryText)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { notificationManager.weeklyReportEnabled },
                            set: { notificationManager.updateWeeklyReport($0) }
                        ))
                    }
                    
                    // Lent money reminders
                    HStack {
                        Image(systemName: "person.2")
                            .foregroundColor(ThemeColors.accent)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Lent Money Reminders")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("Follow up on outstanding loans")
                                .font(.caption)
                                .foregroundColor(ThemeColors.secondaryText)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { notificationManager.lentMoneyRemindersEnabled },
                            set: {
                                notificationManager.updateLentMoneyReminders($0)
                                if $0 {
                                    notificationManager.scheduleLentMoneyReminders(for: expenseStore.expenses)
                                }
                            }
                        ))
                    }
                }
                
                // Current notifications
                Section("Active Reminders") {
                    if notificationManager.dailyReminderEnabled {
                        HStack {
                            Image(systemName: "bell")
                                .foregroundColor(ThemeColors.primary)
                            Text("Daily reminder at \(formatTime(notificationManager.dailyReminderTime))")
                                .font(.subheadline)
                        }
                    }
                    
                    if notificationManager.weeklyReportEnabled {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(ThemeColors.success)
                            Text("Weekly report on Sundays at 6:00 PM")
                                .font(.subheadline)
                        }
                    }
                    
                    if notificationManager.lentMoneyRemindersEnabled {
                        let outstandingCount = expenseStore.expenses.filter { $0.isLentMoney && !$0.isRepaid }.count
                        HStack {
                            Image(systemName: "clock.badge.exclamationmark")
                                .foregroundColor(ThemeColors.accent)
                            Text("Lent money follow-ups (\(outstandingCount) active)")
                                .font(.subheadline)
                        }
                    }
                    
                    if !notificationManager.dailyReminderEnabled &&
                       !notificationManager.weeklyReportEnabled &&
                       !notificationManager.lentMoneyRemindersEnabled {
                        Text("No active reminders")
                            .font(.subheadline)
                            .foregroundColor(ThemeColors.secondaryText)
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Enable Notifications", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                openAppSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To receive expense reminders, please enable notifications in Settings.")
        }
    }
    
    private func requestPermission() {
        Task {
            let granted = await notificationManager.requestNotificationPermission()
            if !granted {
                showingPermissionAlert = true
            }
        }
    }
    
    private func openAppSettings() {
        #if os(iOS)
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
        #endif
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
