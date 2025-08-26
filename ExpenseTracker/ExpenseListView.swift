//
//  ExpenseListView.swift
//  ExpenseTracker
//
//  Created by iMacPro on 26/06/25.
//


// MARK: - Enhanced Expense List View
import SwiftUI

struct ExpenseListView: View {
    @EnvironmentObject var expenseStore: ExpenseStore
    @State private var searchText = ""
    @State private var selectedFilterCategory: ExpenseCategory? = nil
    @State private var showingFilterOptions = false
    @State private var showingAddExpense = false
    @State private var selectedExpense: Expense? = nil
    @State private var showingExpenseDetail = false
    
    // Filter options
    @State private var filterShowLentMoney = false
    @State private var filterShowRepaidOnly = false
    @State private var selectedDateRange: DateRange = .all
    
    enum DateRange: String, CaseIterable {
        case all = "All Time"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case last30Days = "Last 30 Days"
    }
    
    var filteredExpenses: [Expense] {
        var expenses = expenseStore.expenses
        
        // Search filter
        if !searchText.isEmpty {
            expenses = expenses.filter { expense in
                expense.title.localizedCaseInsensitiveContains(searchText) ||
                expense.notes?.localizedCaseInsensitiveContains(searchText) == true ||
                (expense.lentToPersonName?.localizedCaseInsensitiveContains(searchText) == true)
            }
        }
        
        // Category filter
        if let category = selectedFilterCategory {
            expenses = expenses.filter { $0.category == category }
        }
        
        // Lent money filter
        if filterShowLentMoney {
            expenses = expenses.filter { $0.isLentMoney }
            
            if filterShowRepaidOnly {
                expenses = expenses.filter { $0.isRepaid }
            }
        }
        
        // Date range filter
        expenses = expenses.filter { expense in
            switch selectedDateRange {
            case .all:
                return true
            case .thisWeek:
                return Calendar.current.isDateInWeek(expense.date, Date())
            case .thisMonth:
                return Calendar.current.isDate(expense.date, equalTo: Date(), toGranularity: .month)
            case .last30Days:
                return expense.date >= Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            }
        }
        
        return expenses.sorted { $0.date > $1.date }
    }
    
    var totalFilteredAmount: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }
    
    var outstandingLentAmount: Double {
        filteredExpenses.filter { $0.isOutstanding }.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ThemeColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search and Filter Bar
                    searchAndFilterSection
                    
                    // Summary Cards
                    if !filteredExpenses.isEmpty {
                        summarySection
                    }
                    
                    // Expense List
                    if filteredExpenses.isEmpty {
                        emptyStateView
                    } else {
                        expensesList
                    }
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    toolbarButtons
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    toolbarButtons
                }
                #endif
            }
            .sheet(isPresented: $showingFilterOptions) {
                FilterOptionsView(
                    selectedCategory: $selectedFilterCategory,
                    showLentMoney: $filterShowLentMoney,
                    showRepaidOnly: $filterShowRepaidOnly,
                    selectedDateRange: $selectedDateRange
                )
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView()
            }
            .sheet(item: $selectedExpense) { expense in
                ExpenseDetailView(expense: expense)
            }
        }
    }
    
    // MARK: - Search and Filter Section
    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(ThemeColors.secondaryText)
                
                TextField("Search expenses...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(ThemeColors.secondaryText)
                    }
                }
            }
            .padding()
            .background(ThemeColors.cardBackground)
            .cornerRadius(12)
            
            // Quick Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "All (\(expenseStore.expenses.count))",
                        isSelected: selectedFilterCategory == nil && !filterShowLentMoney,
                        action: { clearAllFilters() }
                    )
                    
                    ForEach(ExpenseCategory.allCases, id: \.self) { category in
                        let count = expenseStore.expensesForCategory(category).count
                        if count > 0 {
                            FilterChip(
                                title: "\(category.rawValue) (\(count))",
                                isSelected: selectedFilterCategory == category,
                                color: category.color,
                                action: { toggleCategoryFilter(category) }
                            )
                        }
                    }
                    
                    let lentCount = expenseStore.expenses.filter { $0.isLentMoney }.count
                    if lentCount > 0 {
                        FilterChip(
                            title: "Lent (\(lentCount))",
                            isSelected: filterShowLentMoney,
                            color: ThemeColors.accent,
                            action: { toggleLentMoneyFilter() }
                        )
                    }
                    
                    Button(action: { showingFilterOptions = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "slider.horizontal.3")
                            Text("More")
                        }
                        .font(.caption)
                        .foregroundColor(ThemeColors.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(ThemeColors.primary.opacity(0.1))
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(ThemeColors.background)
    }
    
    // MARK: - Summary Section
    private var summarySection: some View {
        HStack(spacing: 16) {
            SummaryCard(
                title: "Total",
                amount: totalFilteredAmount,
                icon: "dollarsign.circle.fill",
                color: ThemeColors.primary
            )
            
            if outstandingLentAmount > 0 {
                SummaryCard(
                    title: "Outstanding",
                    amount: outstandingLentAmount,
                    icon: "clock.fill",
                    color: ThemeColors.accent
                )
            }
            
            SummaryCard(
                title: "Count",
                count: filteredExpenses.count,
                icon: "number.circle.fill",
                color: ThemeColors.success
            )
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    // MARK: - Expenses List
    private var expensesList: some View {
        List {
            ForEach(groupedExpenses, id: \.key) { group in
                Section(header: sectionHeader(for: group.key)) {
                    ForEach(group.value) { expense in
                        ExpenseListRowView(expense: expense)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedExpense = expense
                                showingExpenseDetail = true
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                // Delete action
                                Button(role: .destructive) {
                                    deleteExpense(expense)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                // Edit action
                                Button {
                                    editExpense(expense)
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.orange)
                                
                                // Mark as repaid (for lent money)
                                if expense.isLentMoney && !expense.isRepaid {
                                    Button {
                                        markAsRepaid(expense)
                                    } label: {
                                        Label("Repaid", systemImage: "checkmark.circle")
                                    }
                                    .tint(.green)
                                }
                            }
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            // Refresh data
            await refreshData()
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: searchText.isEmpty ? "tray" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(ThemeColors.secondaryText)
            
            VStack(spacing: 8) {
                Text(searchText.isEmpty ? "No Expenses Yet" : "No Results Found")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(ThemeColors.text)
                
                Text(searchText.isEmpty ?
                     "Start tracking your expenses by adding your first one!" :
                     "Try adjusting your search or filters")
                    .font(.body)
                    .foregroundColor(ThemeColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            if searchText.isEmpty {
                Button(action: { showingAddExpense = true }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add First Expense")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(ThemeColors.primaryGradient)
                    .cornerRadius(12)
                }
            } else {
                Button("Clear Search") {
                    searchText = ""
                }
                .foregroundColor(ThemeColors.primary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Toolbar Buttons
    private var toolbarButtons: some View {
        HStack {
            Button(action: { showingFilterOptions = true }) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.title2)
            }
            
            Button(action: { showingAddExpense = true }) {
                Image(systemName: "plus")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
        }
    }
    
    // MARK: - Helper Methods
    private var groupedExpenses: [(key: String, value: [Expense])] {
        let grouped = Dictionary(grouping: filteredExpenses) { expense in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: expense.date)
        }
        
        return grouped.sorted { $0.key > $1.key }
    }
    
    private func sectionHeader(for dateString: String) -> some View {
        Text(dateString)
            .font(.headline)
            .foregroundColor(ThemeColors.primary)
            .textCase(nil)
    }
    
    private func clearAllFilters() {
        selectedFilterCategory = nil
        filterShowLentMoney = false
        filterShowRepaidOnly = false
        selectedDateRange = .all
    }
    
    private func toggleCategoryFilter(_ category: ExpenseCategory) {
        if selectedFilterCategory == category {
            selectedFilterCategory = nil
        } else {
            selectedFilterCategory = category
            filterShowLentMoney = false
        }
    }
    
    private func toggleLentMoneyFilter() {
        filterShowLentMoney.toggle()
        if filterShowLentMoney {
            selectedFilterCategory = nil
        }
    }
    
    private func deleteExpense(_ expense: Expense) {
        withAnimation {
            expenseStore.deleteExpense(expense)
        }
    }
    
    private func editExpense(_ expense: Expense) {
        // TODO: Implement edit functionality
        print("Edit expense: \(expense.title)")
    }
    
    private func markAsRepaid(_ expense: Expense) {
        var updatedExpense = expense
        updatedExpense.isRepaid = true
        updatedExpense.repaidDate = Date()
        
        withAnimation {
            expenseStore.updateExpense(updatedExpense)
        }
    }
    
    private func refreshData() async {
        // Refresh data from DataManager if needed
        print("Refreshing expense data...")
    }
}

// MARK: - Enhanced Expense Row
struct ExpenseListRowView: View {
    let expense: Expense
    
    var body: some View {
        HStack(spacing: 16) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(expense.category.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: expense.category.icon)
                    .font(.title3)
                    .foregroundColor(expense.category.color)
            }
            
            // Expense Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(expense.title)
                        .font(.headline)
                        .foregroundColor(ThemeColors.text)
                    
                    Spacer()
                    
                    // Amount
                    Text(expense.formattedAmount)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(ThemeColors.text)
                }
                
                HStack {
                    // Category and Date
                    Text(expense.category.rawValue)
                        .font(.caption)
                        .foregroundColor(ThemeColors.secondaryText)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(ThemeColors.secondaryText)
                    
                    Text(expense.formattedDate)
                        .font(.caption)
                        .foregroundColor(ThemeColors.secondaryText)
                    
                    Spacer()
                    
                    // Lent Money Status
                    if expense.isLentMoney {
                        HStack(spacing: 4) {
                            Image(systemName: expense.isRepaid ? "checkmark.circle.fill" : "clock.fill")
                                .font(.caption)
                                .foregroundColor(expense.isRepaid ? ThemeColors.success : ThemeColors.accent)
                            
                            if let personName = expense.lentToPersonName {
                                Text(personName)
                                    .font(.caption)
                                    .foregroundColor(ThemeColors.secondaryText)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            (expense.isRepaid ? ThemeColors.success : ThemeColors.accent)
                                .opacity(0.1)
                        )
                        .cornerRadius(8)
                    }
                }
                
                // Notes
                if let notes = expense.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(ThemeColors.secondaryText)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = ThemeColors.primary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected ? color : color.opacity(0.1)
                )
                .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Summary Card
struct SummaryCard: View {
    let title: String
    var amount: Double? = nil
    var count: Int? = nil
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(ThemeColors.secondaryText)
                
                if let amount = amount {
                    Text(formatCurrency(amount))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(ThemeColors.text)
                } else if let count = count {
                    Text("\(count)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(ThemeColors.text)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(ThemeColors.cardBackground)
        .cornerRadius(12)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

// MARK: - Filter Options View
struct FilterOptionsView: View {
    @Binding var selectedCategory: ExpenseCategory?
    @Binding var showLentMoney: Bool
    @Binding var showRepaidOnly: Bool
    @Binding var selectedDateRange: ExpenseListView.DateRange
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("All Categories").tag(ExpenseCategory?.none)
                        ForEach(ExpenseCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(ExpenseCategory?.some(category))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Lent Money") {
                    Toggle("Show Lent Money Only", isOn: $showLentMoney)
                    
                    if showLentMoney {
                        Toggle("Show Repaid Only", isOn: $showRepaidOnly)
                    }
                }
                
                Section("Date Range") {
                    Picker("Date Range", selection: $selectedDateRange) {
                        ForEach(ExpenseListView.DateRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section {
                    Button("Clear All Filters") {
                        selectedCategory = nil
                        showLentMoney = false
                        showRepaidOnly = false
                        selectedDateRange = .all
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Filter Options")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
                #else
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                #endif
            }
        }
    }
}

// MARK: - Expense Detail View
struct ExpenseDetailView: View {
    let expense: Expense
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(expense.category.color.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: expense.category.icon)
                            .font(.system(size: 32))
                            .foregroundColor(expense.category.color)
                    }
                    
                    VStack(spacing: 8) {
                        Text(expense.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(expense.formattedAmount)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(ThemeColors.primary)
                    }
                }
                
                // Details
                VStack(spacing: 16) {
                    HStack {
                        Text("Category")
                            .foregroundColor(ThemeColors.secondaryText)
                        Spacer()
                        Text(expense.category.rawValue)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Date")
                            .foregroundColor(ThemeColors.secondaryText)
                        Spacer()
                        Text(expense.formattedDate)
                            .fontWeight(.medium)
                    }
                    
                    if expense.isLentMoney {
                        HStack {
                            Text("Lent to")
                                .foregroundColor(ThemeColors.secondaryText)
                            Spacer()
                            Text(expense.lentToPersonName ?? "Unknown")
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("Status")
                                .foregroundColor(ThemeColors.secondaryText)
                            Spacer()
                            Text(expense.isRepaid ? "Repaid" : "Outstanding")
                                .fontWeight(.medium)
                                .foregroundColor(expense.isRepaid ? ThemeColors.success : ThemeColors.accent)
                        }
                    }
                    
                    if let notes = expense.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .foregroundColor(ThemeColors.secondaryText)
                            Text(notes)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding()
                .background(ThemeColors.cardBackground)
                .cornerRadius(16)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Expense Details")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
                #else
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                #endif
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    var valueColor: Color = ThemeColors.text
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(ThemeColors.secondaryText)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Calendar Extension
extension Calendar {
    func isDateInWeek(_ date: Date, _ referenceDate: Date) -> Bool {
        let weekOfYear1 = component(.weekOfYear, from: date)
        let weekOfYear2 = component(.weekOfYear, from: referenceDate)
        let year1 = component(.year, from: date)
        let year2 = component(.year, from: referenceDate)
        return weekOfYear1 == weekOfYear2 && year1 == year2
    }
}


// MARK: - Preview
#Preview {
    ExpenseListView()
        .environmentObject(ExpenseStore())
}
