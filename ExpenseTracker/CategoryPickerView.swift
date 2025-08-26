//
//  CategoryPickerView.swift
//  ExpenseTracker
//
//  Created by iMacPro on 27/06/25.
//
import SwiftUI

struct CategoryPickerView: View {
    @Binding var selectedCategory: ExpenseCategory
    @Environment(\.dismiss) private var dismiss
    
    let columns = Array(repeating: GridItem(.flexible()), count: 2)
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(ExpenseCategory.allCases, id: \.self) { category in
                        CategoryCard(
                            category: category,
                            isSelected: category == selectedCategory
                        ) {
                            selectedCategory = category
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Select Category")
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
        }
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let category: ExpenseCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(category.color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: category.icon)
                        .font(.title2)
                        .foregroundColor(category.color)
                }
                
                Text(category.rawValue)
                    .font(.headline)
                    .foregroundColor(ThemeColors.text)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                isSelected
                ? category.color.opacity(0.1)
                : ThemeColors.cardBackground
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? category.color : Color.clear,
                        lineWidth: 2
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
}
