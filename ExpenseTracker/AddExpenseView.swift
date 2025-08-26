//
//  AddExpenseView.swift
//  ExpenseTracker
//
//  Created by iMacPro on 27/06/25.
//
import SwiftUI

import SwiftUI

struct AddExpenseView: View {
    @EnvironmentObject var expenseStore: ExpenseStore
    @StateObject private var paymentModeStore = PaymentModeStore()
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var amount = ""
    @State private var selectedCategory = ExpenseCategory.food
    @State private var selectedDate = Date()
    @State private var notes = ""
    @State private var showingCategoryPicker = false
    @State private var showingPaymentModePicker = false
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // New fields for enhanced functionality
    @State private var isLentMoney = false
    @State private var lentToPersonName = ""
    @State private var selectedPaymentMode: PaymentMode = PaymentMode.cash
    
    // Form validation
    private var isFormValid: Bool {
        let titleValid = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let amountValid = !amount.isEmpty && Double(amount) != nil && Double(amount)! > 0
        let lentPersonValid = !isLentMoney || !lentToPersonName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        return titleValid && amountValid && lentPersonValid
    }
    
    private var formattedAmount: String {
        if let value = Double(amount), value > 0 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = Locale.current
            return formatter.string(from: NSNumber(value: value)) ?? ""
        }
        return ""
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                ThemeColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Form Content
                        VStack(spacing: 20) {
                            titleSection
                            amountSection
                            categorySection
                            paymentModeSection
                            dateSection
                            lentMoneySection
                            notesSection
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 20)
                }
                
                // Save Button (Floating)
                VStack {
                    Spacer()
                    saveButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                }
            }
            .navigationTitle("Add Expense")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    cancelButton
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    cancelButton
                }
                #endif
            }
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerView(selectedCategory: $selectedCategory)
            }
            .sheet(isPresented: $showingPaymentModePicker) {
                PaymentModePickerView(
                    selectedPaymentMode: $selectedPaymentMode,
                    paymentModeStore: paymentModeStore
                )
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                selectedPaymentMode = paymentModeStore.defaultPaymentMode
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: isLentMoney ? "person.2.fill" : "plus.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(isLentMoney ? ThemeColors.accent : ThemeColors.primary)
                .scaleEffect(isLoading ? 0.8 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isLoading)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isLentMoney)
            
            Text(isLentMoney ? "Lent Money" : "New Expense")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(ThemeColors.text)
            
            Text(isLentMoney ? "Track money lent to others" : "Track your spending")
                .font(.subheadline)
                .foregroundColor(ThemeColors.secondaryText)
        }
        .padding()
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Title", systemImage: "textformat")
                .font(.headline)
                .foregroundColor(ThemeColors.text)
            
            TextField("Enter expense title", text: $title)
                .textFieldStyle(CustomTextFieldStyle())
                #if os(iOS)
                .submitLabel(.next)
                #endif
        }
    }
    
    // MARK: - Amount Section
    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Amount", systemImage: "dollarsign.circle")
                    .font(.headline)
                    .foregroundColor(ThemeColors.text)
                
                Spacer()
                
                if !formattedAmount.isEmpty {
                    Text(formattedAmount)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(ThemeColors.primary)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }
            
            TextField("0.00", text: $amount)
                .textFieldStyle(CustomTextFieldStyle())
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
                #if os(iOS)
                .submitLabel(.next)
                #endif
                .onChange(of: amount) { oldValue, newValue in
                    // Allow digits and one decimal point
                    let filtered = newValue.filter { "0123456789.".contains($0) }
                    if filtered != newValue {
                        amount = filtered
                        return
                    }
                    
                    // Handle decimal point logic
                    let components = filtered.components(separatedBy: ".")
                    if components.count > 2 {
                        // More than one decimal point - remove the last character
                        amount = String(filtered.dropLast())
                        return
                    }
                    
                    if components.count == 2 {
                        // Has decimal point - limit decimal places to 2
                        let decimalPart = components[1]
                        if decimalPart.count > 2 {
                            let wholePart = components[0]
                            let limitedDecimal = String(decimalPart.prefix(2))
                            amount = "\(wholePart).\(limitedDecimal)"
                        }
                    }
                    
                    // No artificial limit on whole number digits
                }
        }
    }
    
    // MARK: - Category Section
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Category", systemImage: "tag")
                .font(.headline)
                .foregroundColor(ThemeColors.text)
            
            Button(action: {
                showingCategoryPicker = true
            }) {
                HStack {
                    Image(systemName: selectedCategory.icon)
                        .font(.title2)
                        .foregroundColor(selectedCategory.color)
                        .frame(width: 30)
                    
                    Text(selectedCategory.rawValue)
                        .font(.body)
                        .foregroundColor(ThemeColors.text)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(ThemeColors.secondaryText)
                }
                .padding()
                .background(ThemeColors.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selectedCategory.color.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Payment Mode Section
    private var paymentModeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Payment Mode", systemImage: "creditcard")
                .font(.headline)
                .foregroundColor(ThemeColors.text)
            
            Button(action: {
                showingPaymentModePicker = true
            }) {
                HStack {
                    Image(systemName: selectedPaymentMode.icon)
                        .font(.title2)
                        .foregroundColor(selectedPaymentMode.swiftUIColor)
                        .frame(width: 30)
                    
                    Text(selectedPaymentMode.name)
                        .font(.body)
                        .foregroundColor(ThemeColors.text)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(ThemeColors.secondaryText)
                }
                .padding()
                .background(ThemeColors.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selectedPaymentMode.swiftUIColor.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Date Section
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Date", systemImage: "calendar")
                .font(.headline)
                .foregroundColor(ThemeColors.text)
            
            DatePicker("Select date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .accentColor(ThemeColors.primary)
                .padding()
                .background(ThemeColors.cardBackground)
                .cornerRadius(12)
        }
    }
    
    // MARK: - Lent Money Section
    private var lentMoneySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Toggle for lent money
            HStack {
                Label("Lent Money", systemImage: "person.2")
                    .font(.headline)
                    .foregroundColor(ThemeColors.text)
                
                Spacer()
                
                Toggle("", isOn: $isLentMoney)
                    .toggleStyle(SwitchToggleStyle(tint: ThemeColors.accent))
            }
            .padding()
            .background(ThemeColors.cardBackground)
            .cornerRadius(12)
            
            // Person name field (only shown when lent money is enabled)
            if isLentMoney {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Lent to Person", systemImage: "person.circle")
                        .font(.subheadline)
                        .foregroundColor(ThemeColors.text)
                    
                    TextField("Enter person's name", text: $lentToPersonName)
                        .textFieldStyle(CustomTextFieldStyle())
                        #if os(iOS)
                        .submitLabel(.next)
                        #endif
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isLentMoney)
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notes", systemImage: "note.text")
                .font(.headline)
                .foregroundColor(ThemeColors.text)
            
            TextField("Optional notes...", text: $notes, axis: .vertical)
                .textFieldStyle(CustomTextFieldStyle())
                .lineLimit(3...6)
        }
    }
    
    // MARK: - Action Buttons
    private var cancelButton: some View {
        Button("Cancel") {
            dismiss()
        }
        .foregroundColor(ThemeColors.secondaryText)
    }
    
    private var saveButton: some View {
        Button(action: saveExpense) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: isLentMoney ? "person.badge.plus" : "checkmark")
                        .font(.headline)
                }
                
                Text(isLoading ? "Saving..." : (isLentMoney ? "Save Lent Money" : "Save Expense"))
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                isFormValid && !isLoading
                    ? (isLentMoney ? LinearGradient(colors: [ThemeColors.accent], startPoint: .leading, endPoint: .trailing) : ThemeColors.primaryGradient)
                    : LinearGradient(colors: [Color.gray.opacity(0.6)], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(16)
            .shadow(
                color: isFormValid ? (isLentMoney ? ThemeColors.accent.opacity(0.3) : ThemeColors.primary.opacity(0.3)) : Color.clear,
                radius: 10, x: 0, y: 5
            )
            .scaleEffect(isLoading ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isLoading)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isLentMoney)
        }
        .disabled(!isFormValid || isLoading)
        .buttonStyle(PlainButtonStyle())
    }
    
    private func saveExpense() {
        guard let amountValue = Double(amount) else { return }
        
        let expense = Expense(
            title: title,
            amount: amountValue,
            category: selectedCategory,
            date: selectedDate,
            notes: notes.isEmpty ? nil : notes,
            isLentMoney: isLentMoney,
            lentToPersonName: isLentMoney ? lentToPersonName : nil,
            paymentMode: PaymentMode.cash
        )
        
        expenseStore.addExpense(expense)
        dismiss()
    }
}


// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(ThemeColors.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ThemeColors.primary.opacity(0.2), lineWidth: 1)
            )
    }
}
