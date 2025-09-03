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
    }
}

