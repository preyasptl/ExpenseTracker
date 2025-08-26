//
//  PaymentModePickerView.swift
//  ExpenseTracker
//
//  Created by iMacPro on 27/06/25.
//
import SwiftUI

struct PaymentModePickerView: View {
    @Binding var selectedPaymentMode: PaymentMode
    let paymentModeStore: PaymentModeStore
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddPaymentMode = false
    
    let columns = Array(repeating: GridItem(.flexible()), count: 2)
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(paymentModeStore.paymentModes, id: \.id) { paymentMode in
                        PaymentModeCard(
                            paymentMode: paymentMode,
                            isSelected: paymentMode.id == selectedPaymentMode.id
                        ) {
                            selectedPaymentMode = paymentMode
                            dismiss()
                        }
                    }
                    
                    // Add new payment mode card
                    AddPaymentModeCard {
                        showingAddPaymentMode = true
                    }
                }
                .padding()
            }
            .navigationTitle("Select Payment Mode")
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
            .sheet(isPresented: $showingAddPaymentMode) {
                AddPaymentModeView(paymentModeStore: paymentModeStore)
            }
        }
    }
}

struct PaymentModeCard: View {
    let paymentMode: PaymentMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(paymentMode.swiftUIColor.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: paymentMode.icon)
                        .font(.title2)
                        .foregroundColor(paymentMode.swiftUIColor)
                }
                
                VStack(spacing: 4) {
                    Text(paymentMode.name)
                        .font(.headline)
                        .foregroundColor(ThemeColors.text)
                        .multilineTextAlignment(.center)
                    
                    if paymentMode.isDefault {
                        Text("Default")
                            .font(.caption)
                            .foregroundColor(ThemeColors.accent)
                            .fontWeight(.medium)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                isSelected
                    ? paymentMode.swiftUIColor.opacity(0.1)
                    : ThemeColors.cardBackground
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? paymentMode.swiftUIColor : Color.clear,
                        lineWidth: 2
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environmentObject(ExpenseStore())
}

struct AddPaymentModeCard: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(ThemeColors.primary.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(ThemeColors.primary)
                }
                
                Text("Add New")
                    .font(.headline)
                    .foregroundColor(ThemeColors.text)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(ThemeColors.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(ThemeColors.primary.opacity(0.3), lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
