//
//  AnalyticsView.swift
//  ExpenseTracker
//
//  Created by iMacPro on 27/08/25.
//

import SwiftUI
import Charts

struct AnalyticsView: View {
    @EnvironmentObject var expenseStore: ExpenseStore
    @State private var selectedTimeRange: TimeRange = .thisMonth
    @State private var selectedChartType: ChartType = .category
    @StateObject private var currencyManager = CurrencyManager.shared
    
    enum TimeRange: String, CaseIterable {
        case thisMonth = "This Month"
        case last30Days = "Last 30 Days"
        case last3Months = "Last 3 Months"
        case thisYear = "This Year"
        case allTime = "All Time"
    }
    
    enum ChartType: String, CaseIterable {
        case category = "By Category"
        case monthly = "Monthly Trend"
        case lentMoney = "Lent Money"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with controls
                    headerSection
                    
                    // Summary cards
                    summaryCardsSection
                    
                    // Main chart
                    mainChartSection
                    
                    // Insights section
                    insightsSection
                    
                    // Top categories/expenses
                    topSpendingSection
                }
                .padding()
            }
            .navigationTitle("Analytics")
            .background(ThemeColors.background)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Time range selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Button(range.rawValue) {
                            selectedTimeRange = range
                        }
                        .font(.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedTimeRange == range ? ThemeColors.primary : ThemeColors.cardBackground)
                        .foregroundColor(selectedTimeRange == range ? .white : ThemeColors.text)
                        .cornerRadius(20)
                    }
                }
                .padding(.horizontal)
            }
            
            // Chart type selector
            Picker("Chart Type", selection: $selectedChartType) {
                ForEach(ChartType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    // MARK: - Summary Cards
    private var summaryCardsSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            AnalyticsSummaryCard(
                title: "Total Spent",
                value: formatCurrency(filteredExpenses.reduce(0) { $0 + $1.amount }),
                icon: "dollarsign.circle.fill",
                color: ThemeColors.primary,
                trend: calculateTrend()
            )
            
            AnalyticsSummaryCard(
                title: "Avg per Day",
                value: formatCurrency(averagePerDay),
                icon: "calendar",
                color: ThemeColors.accent,
                subtitle: "\(filteredExpenses.count) expenses"
            )
            
            if lentMoneyAmount > 0 {
                AnalyticsSummaryCard(
                    title: "Lent Money",
                    value: formatCurrency(lentMoneyAmount),
                    icon: "person.2.fill",
                    color: ThemeColors.success,
                    subtitle: "\(formatCurrency(outstandingLentMoney)) outstanding"
                )
            }
            
            AnalyticsSummaryCard(
                title: "Top Category",
                value: topCategory?.category.rawValue ?? "None",
                icon: topCategory?.category.icon ?? "chart.bar",
                color: topCategory?.category.color ?? ThemeColors.primary,
                subtitle: topCategory != nil ? formatCurrency(topCategory!.total) : ""
            )
        }
    }
    
    // MARK: - Main Chart Section
    private var mainChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Analysis")
                .font(.headline)
                .foregroundColor(ThemeColors.text)
            
            Group {
                switch selectedChartType {
                case .category:
                    categoryChart
                case .monthly:
                    monthlyTrendChart
                case .lentMoney:
                    lentMoneyChart
                }
            }
            .frame(height: 300)
            .padding()
            .background(ThemeColors.cardBackground)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Category Chart
    private var categoryChart: some View {
        Chart(categoryData, id: \.category) { item in
            SectorMark(
                angle: .value("Amount", item.total),
                innerRadius: .ratio(0.4),
                angularInset: 1.5
            )
            .foregroundStyle(item.category.color)
            .opacity(0.8)
        }
        .overlay {
            VStack {
                Text("Total")
                    .font(.caption)
                    .foregroundColor(ThemeColors.secondaryText)
                Text(formatCurrency(filteredExpenses.reduce(0) { $0 + $1.amount }))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(ThemeColors.text)
                    .minimumScaleFactor(0.2)
            }
        }
    }
    
    // MARK: - Monthly Trend Chart
    private var monthlyTrendChart: some View {
        Chart(monthlyData, id: \.month) { item in
            LineMark(
                x: .value("Month", item.month),
                y: .value("Amount", item.total)
            )
            .foregroundStyle(ThemeColors.primary)
            .lineStyle(StrokeStyle(lineWidth: 3))
            
            AreaMark(
                x: .value("Month", item.month),
                y: .value("Amount", item.total)
            )
            .foregroundStyle(ThemeColors.primary.opacity(0.2))
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(formatCurrencyShort(amount))
                            .font(.caption)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date, format: .dateTime.month(.abbreviated))
                            .font(.caption)
                    }
                }
            }
        }
    }
    
    // MARK: - Lent Money Chart
    // MARK: - Lent Money Chart
    private var lentMoneyChart: some View {
        Chart(lentMoneyData, id: \.person) { item in
            BarMark(
                x: .value("Person", item.person),
                y: .value("Amount", item.amount)
            )
            .foregroundStyle(item.isRepaid ? ThemeColors.success : ThemeColors.accent)
            .cornerRadius(6)
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(formatCurrencyShort(amount))
                            .font(.caption)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let person = value.as(String.self) {
                        Text(person)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
    
    // MARK: - Insights Section
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.headline)
                .foregroundColor(ThemeColors.text)
            
            LazyVStack(spacing: 8) {
                if let insight = topSpendingInsight {
                    InsightCard(
                        icon: "chart.bar.fill",
                        title: "Top Spending",
                        description: insight,
                        color: ThemeColors.primary
                    )
                }
                
                if let insight = lentMoneyInsight {
                    InsightCard(
                        icon: "person.2.fill",
                        title: "Lent Money",
                        description: insight,
                        color: ThemeColors.accent
                    )
                }
                
                if let insight = trendInsight {
                    InsightCard(
                        icon: "arrow.up.right",
                        title: "Spending Trend",
                        description: insight,
                        color: ThemeColors.success
                    )
                }
            }
        }
    }
    
    // MARK: - Top Spending Section
    private var topSpendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Expenses")
                .font(.headline)
                .foregroundColor(ThemeColors.text)
            
            LazyVStack(spacing: 8) {
                ForEach(topExpenses.prefix(5), id: \.id) { expense in
                    HStack {
                        Image(systemName: expense.category.icon)
                            .foregroundColor(expense.category.color)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(expense.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(expense.category.rawValue)
                                .font(.caption)
                                .foregroundColor(ThemeColors.secondaryText)
                        }
                        
                        Spacer()
                        
                        Text(expense.formattedAmount)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(ThemeColors.cardBackground)
                    .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var filteredExpenses: [Expense] {
        let calendar = Calendar.current
        let now = Date()
        
        return expenseStore.expenses.filter { expense in
            switch selectedTimeRange {
            case .thisMonth:
                return calendar.isDate(expense.date, equalTo: now, toGranularity: .month)
            case .last30Days:
                return expense.date >= calendar.date(byAdding: .day, value: -30, to: now) ?? now
            case .last3Months:
                return expense.date >= calendar.date(byAdding: .month, value: -3, to: now) ?? now
            case .thisYear:
                return calendar.isDate(expense.date, equalTo: now, toGranularity: .year)
            case .allTime:
                return true
            }
        }
    }
    
    private var categoryData: [(category: ExpenseCategory, total: Double)] {
        let grouped = Dictionary(grouping: filteredExpenses) { $0.category }
        return grouped.compactMap { category, expenses in
            let total = expenses.reduce(0) { $0 + $1.amount }
            return total > 0 ? (category, total) : nil
        }.sorted { $0.total > $1.total }
    }
    
    private var monthlyData: [(month: Date, total: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredExpenses) { expense in
            calendar.dateInterval(of: .month, for: expense.date)?.start ?? expense.date
        }
        return grouped.map { month, expenses in
            (month, expenses.reduce(0) { $0 + $1.amount })
        }.sorted { $0.month < $1.month }
    }
    
    private var lentMoneyData: [(person: String, amount: Double, isRepaid: Bool)] {
        let lentExpenses = filteredExpenses.filter { $0.isLentMoney }
        let grouped = Dictionary(grouping: lentExpenses) { $0.lentToPersonName ?? "Unknown" }
        return grouped.map { person, expenses in
            let total = expenses.reduce(0) { $0 + $1.amount }
            let isRepaid = expenses.allSatisfy { $0.isRepaid }
            return (person, total, isRepaid)
        }.sorted { $0.amount > $1.amount }
    }
    
    private var topExpenses: [Expense] {
        filteredExpenses.sorted { $0.amount > $1.amount }
    }
    
    private var topCategory: (category: ExpenseCategory, total: Double)? {
        categoryData.first
    }
    
    private var lentMoneyAmount: Double {
        filteredExpenses.filter { $0.isLentMoney }.reduce(0) { $0 + $1.amount }
    }
    
    private var outstandingLentMoney: Double {
        filteredExpenses.filter { $0.isLentMoney && !$0.isRepaid }.reduce(0) { $0 + $1.amount }
    }
    
    private var averagePerDay: Double {
        guard !filteredExpenses.isEmpty else { return 0 }
        let days = daysBetween(start: filteredExpenses.map { $0.date }.min() ?? Date(), end: Date())
        let total = filteredExpenses.reduce(0) { $0 + $1.amount }
        return days > 0 ? total / Double(days) : total
    }
    
    // MARK: - Insights
    private var topSpendingInsight: String? {
        guard let topCategory = topCategory else { return nil }
        let percentage = (topCategory.total / filteredExpenses.reduce(0) { $0 + $1.amount }) * 100
        return "\(topCategory.category.rawValue) accounts for \(Int(percentage))% of your spending"
    }
    
    private var lentMoneyInsight: String? {
        guard lentMoneyAmount > 0 else { return nil }
        let outstandingCount = filteredExpenses.filter { $0.isLentMoney && !$0.isRepaid }.count
        return outstandingCount > 0 ? "You have \(outstandingCount) outstanding loans" : "All lent money has been repaid"
    }
    
    private var trendInsight: String? {
        let sortedMonthly = monthlyData.sorted { $0.month < $1.month }
        guard sortedMonthly.count >= 2 else { return nil }
        
        let recent = sortedMonthly.suffix(2)
        let current = recent.last!.total
        let previous = recent.first!.total
        
        if current > previous {
            let increase = ((current - previous) / previous) * 100
            return "Spending increased by \(Int(increase))% this period"
        } else {
            let decrease = ((previous - current) / previous) * 100
            return "Spending decreased by \(Int(decrease))% this period"
        }
    }
    
    // MARK: - Helper Methods
    private func calculateTrend() -> String? {
        // Simple trend calculation for the summary card
        return trendInsight
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = currencyManager.currentLocale
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    private func formatCurrencyShort(_ amount: Double) -> String {
        if amount >= 1000 {
            let thousands = amount / 1000
            if thousands >= 10 {
                return "$\(Int(thousands))K"
            } else {
                return String(format: "$%.1fK", thousands)
            }
        } else if amount >= 100 {
            return "$\(Int(amount))"
        } else {
            return "$\(Int(amount))"
        }
    }
    
    private func daysBetween(start: Date, end: Date) -> Int {
        Calendar.current.dateComponents([.day], from: start, to: end).day ?? 1
    }
}

// MARK: - Supporting Views
struct AnalyticsSummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var trend: String? = nil
    var subtitle: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Text(title)
                    .font(.caption)
                    .foregroundColor(ThemeColors.secondaryText)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ThemeColors.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(ThemeColors.secondaryText)
                } else if let trend = trend {
                    Text(trend)
                        .font(.caption2)
                        .foregroundColor(color)
                }
            }
        }
        .padding()
        .background(ThemeColors.cardBackground)
        .cornerRadius(12)
    }
}

struct InsightCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(ThemeColors.secondaryText)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(ThemeColors.cardBackground)
        .cornerRadius(8)
    }
}
