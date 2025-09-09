//
//  CustomTextFieldStyle.swift
//  ExpenseTracker
//
//  Created by iMacPro on 09/09/25.
//
import SwiftUI

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
