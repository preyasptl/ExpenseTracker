//
//  ExpenseRowView.swift
//  ExpenseTracker
//
//  Created by iMacPro on 26/06/25.
//
import SwiftUI

// ExpenseRowView.swift
struct ExpenseRowView: View {
    let expense: Expense
    
    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            Image(systemName: expense.category.icon)
                .font(.title3)
                .foregroundColor(expense.category.color)
                .frame(width: 40, height: 40)
                .background(expense.category.color.opacity(0.1))
                .cornerRadius(8)
            
            // Expense Details
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.title)
                    .font(.headline)
                    .foregroundColor(ThemeColors.text)
                Text(expense.category.rawValue)
                    .font(.caption)
                    .foregroundColor(ThemeColors.secondaryText)
            }
            
            Spacer()
            
            // Amount
            Text(expense.formattedAmount)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(ThemeColors.text)
        }
        .padding()
        .background(ThemeColors.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
