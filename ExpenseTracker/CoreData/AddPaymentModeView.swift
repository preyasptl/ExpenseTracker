//
//  AddPaymentModeView.swift
//  ExpenseTracker
//
//  Created by iMacPro on 27/06/25.
//
import SwiftUI

struct AddPaymentModeView: View {
    let paymentModeStore: PaymentModeStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedIcon = "creditcard"
    @State private var selectedColor = Color.blue
    @State private var isDefault = false
    
    private let availableIcons = [
        "creditcard", "creditcard.fill", "banknote", "dollarsign.circle",
        "building.columns", "qrcode", "wallet.pass", "phone",
        "applewatch", "desktopcomputer", "globe", "icloud"
    ]
    
    private let availableColors: [Color] = [
        .blue, .green, .orange, .red, .purple, .pink, .yellow, .indigo, .teal, .cyan
    ]
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Preview
                    previewSection
                    
                    // Form fields
                    VStack(spacing: 20) {
                        nameSection
                        iconSection
                        colorSection
                        defaultSection
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 20)
            }
            .navigationTitle("Add Payment Mode")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePaymentMode()
                    }
                    .disabled(!isFormValid)
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePaymentMode()
                    }
                    .disabled(!isFormValid)
                }
                #endif
            }
        }
    }
    
    private var previewSection: some View {
        VStack(spacing: 12) {
            Text("Preview")
                .font(.headline)
                .foregroundColor(ThemeColors.secondaryText)
            
            PaymentModeCard(
                paymentMode: PaymentMode(
                    name: name.isEmpty ? "Payment Mode" : name,
                    icon: selectedIcon,
                    color: selectedColor.toHex(),
                    isDefault: isDefault
                ),
                isSelected: true
            ) { }
            .disabled(true)
        }
        .padding()
    }
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Name", systemImage: "textformat")
                .font(.headline)
                .foregroundColor(ThemeColors.text)
            
            TextField("Enter payment mode name", text: $name)
                .textFieldStyle(CustomTextFieldStyle())
        }
    }
    
    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Icon", systemImage: selectedIcon)
                .font(.headline)
                .foregroundColor(ThemeColors.text)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(availableIcons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                        } label: {
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundColor(selectedIcon == icon ? .white : ThemeColors.text)
                                .frame(width: 44, height: 44)
                                .background(
                                    selectedIcon == icon
                                        ? selectedColor
                                        : ThemeColors.cardBackground
                                )
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Color", systemImage: "paintpalette")
                .font(.headline)
                .foregroundColor(ThemeColors.text)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(availableColors.enumerated()), id: \.offset) { index, color in
                        Button {
                            selectedColor = color
                        } label: {
                            Circle()
                                .fill(color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(ThemeColors.primary, lineWidth: selectedColor == color ? 2 : 0)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var defaultSection: some View {
        HStack {
            Label("Set as Default", systemImage: "star")
                .font(.headline)
                .foregroundColor(ThemeColors.text)
            
            Spacer()
            
            Toggle("", isOn: $isDefault)
                .toggleStyle(SwitchToggleStyle(tint: ThemeColors.primary))
        }
        .padding()
        .background(ThemeColors.cardBackground)
        .cornerRadius(12)
    }
    
    private func savePaymentMode() {
        let paymentMode = PaymentMode(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            icon: selectedIcon,
            color: selectedColor.toHex(),
            isDefault: isDefault
        )
        
        paymentModeStore.addPaymentMode(paymentMode)
        
        if isDefault {
            paymentModeStore.setDefaultPaymentMode(paymentMode)
        }
        
        dismiss()
    }
}
