//
//  DashboardView.swift
//  ExpenseTracker
//
//  Created by iMacPro on 26/06/25.
//
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var expenseStore: ExpenseStore
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Welcome back!")
                                .font(.title2)
                                .foregroundColor(ThemeColors.text)
                            HStack {
                                Text("Here's your expense overview")
                                    .font(.subheadline)
                                    .foregroundColor(ThemeColors.secondaryText)
                                
                                // Enhanced Sync Status Indicator
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(syncStatusColor)
                                        .frame(width: 8, height: 8)
                                    Text(expenseStore.syncStatus)
                                        .font(.caption)
                                        .foregroundColor(ThemeColors.secondaryText)
                                    
                                    if expenseStore.hasPendingChanges {
                                        Text("• \(pendingChangesCount) pending")
                                            .font(.caption)
                                            .foregroundColor(ThemeColors.accent)
                                    }
                                }
                            }
                        }
                        Spacer()
                        
                        // Profile Picture Placeholder with sync info
                        VStack {
                            Circle()
                                .fill(ThemeColors.primaryGradient)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.white)
                                )
                            
                            if let lastSync = expenseStore.lastSyncDate {
                                Text("Last sync: \(lastSyncFormatted(lastSync))")
                                    .font(.caption2)
                                    .foregroundColor(ThemeColors.secondaryText)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Total Expense Card
                    VStack(spacing: 16) {
                        HStack {
                            Text("Total Expenses")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(.white)
                        }
                        
                        Text(formatCurrency(expenseStore.totalExpenses))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(ThemeColors.primaryGradient)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Quick Stats
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        StatCardView(
                            title: "This Month",
                            value: formatCurrency(monthlyTotal),
                            icon: "calendar",
                            color: ThemeColors.accent
                        )
                        
                        StatCardView(
                            title: "Categories",
                            value: "\(activeCategories)",
                            icon: "tag.fill",
                            color: ThemeColors.success
                        )
                    }
                    .padding(.horizontal)
                    
                    // Recent Expenses
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Expenses")
                                .font(.headline)
                                .foregroundColor(ThemeColors.text)
                            Spacer()
                            Button("See All") {
                                // Navigate to expenses tab
                            }
                            .foregroundColor(ThemeColors.primary)
                        }
                        .padding(.horizontal)
                        
                        ForEach(recentExpenses.prefix(3)) { expense in
                            ExpenseRowView(expense: expense)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
        }
    }
    
    private var monthlyTotal: Double {
        let calendar = Calendar.current
        let now = Date()
        return expenseStore.expenses
            .filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var activeCategories: Int {
        Set(expenseStore.expenses.map { $0.category }).count
    }
    
    private var recentExpenses: [Expense] {
        expenseStore.expenses
            .sorted { $0.date > $1.date }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
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
    
    private var pendingChangesCount: Int {
        // This would need to be implemented in ExpenseStore/DataManager
        return expenseStore.hasPendingChanges ? 1 : 0
    }
    
    private func lastSyncFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Helper Views
// StatCardView.swift
struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(ThemeColors.secondaryText)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(ThemeColors.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.2)
                    .frame(minHeight: 34)
            }
        }
        .frame(maxHeight: .infinity)
        .padding()
        .background(ThemeColors.cardBackground)
        .cornerRadius(12)
    }
}

#Preview {
    StatCardView(title: "This Month", value: "1", icon: "calendar", color: ThemeColors.accent)
        .frame(width: 150, height: 100)
}
