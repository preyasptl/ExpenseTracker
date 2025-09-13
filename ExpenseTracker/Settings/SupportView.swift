//
//  SupportView.swift
//  ExpenseTracker
//
//  Created by iMacPro on 11/09/25.
//
import SwiftUI

// MARK: - Alternative Support View (Optional Enhanced Version)
struct SupportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIssue: SupportIssue = .general
    @State private var customMessage = ""
    @State private var includeDeviceInfo = true
    
    enum SupportIssue: String, CaseIterable {
        case general = "General Question"
        case sync = "Sync Issues"
        case data = "Data Problems"
        case feature = "Feature Request"
        case bug = "Bug Report"
        case billing = "Billing Question"
        
        var description: String {
            switch self {
            case .general:
                return "General questions about the app"
            case .sync:
                return "Problems with data synchronization"
            case .data:
                return "Issues with expense data or export"
            case .feature:
                return "Suggestions for new features"
            case .bug:
                return "Report a problem or bug"
            case .billing:
                return "Questions about purchases or subscriptions"
            }
        }
        
        var icon: String {
            switch self {
            case .general: return "questionmark.circle"
            case .sync: return "arrow.clockwise"
            case .data: return "externaldrive"
            case .feature: return "lightbulb"
            case .bug: return "ladybug"
            case .billing: return "creditcard"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("What can we help you with?") {
                    ForEach(SupportIssue.allCases, id: \.self) { issue in
                        Button(action: {
                            selectedIssue = issue
                        }) {
                            HStack {
                                Image(systemName: issue.icon)
                                    .foregroundColor(ThemeColors.primary)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(issue.rawValue)
                                        .font(.subheadline)
                                        .foregroundColor(ThemeColors.text)
                                    
                                    Text(issue.description)
                                        .font(.caption)
                                        .foregroundColor(ThemeColors.secondaryText)
                                }
                                
                                Spacer()
                                
                                if selectedIssue == issue {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(ThemeColors.primary)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Section("Additional Details") {
                    TextField("Describe your issue or question...", text: $customMessage, axis: .vertical)
                        .lineLimit(5...10)
                    
                    Toggle("Include device information", isOn: $includeDeviceInfo)
                }
                
                Section {
                    Button("Send Support Email") {
                        sendSupportEmail()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Contact Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func sendSupportEmail() {
        var body = "Issue Type: \(selectedIssue.rawValue)\n\n"
        
        if !customMessage.isEmpty {
            body += "Description:\n\(customMessage)\n\n"
        }
        
        if includeDeviceInfo {
            body += """
            ---
            Device Information:
            App Version: \(Bundle.main.appVersion)
            Build: \(Bundle.main.buildNumber)
            """
            
            #if os(iOS)
            body += """
            iOS Version: \(UIDevice.current.systemVersion)
            Device Model: \(UIDevice.current.model)
            """
            #elseif os(macOS)
            body += """
            macOS Version: \(ProcessInfo.processInfo.operatingSystemVersionString)
            """
            #endif
        }
        
        let subject = "ExpenseTracker Support: \(selectedIssue.rawValue)"
        
        #if os(iOS)
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let mailtoURL = "mailto:support@expensetracker.com?subject=\(encodedSubject)&body=\(encodedBody)"
        
        if let url = URL(string: mailtoURL) {
            UIApplication.shared.open(url)
        }
        #elseif os(macOS)
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let mailtoURL = "mailto:support@expensetracker.com?subject=\(encodedSubject)&body=\(encodedBody)"
        
        if let url = URL(string: mailtoURL) {
            NSWorkspace.shared.open(url)
        }
        #endif
        
        dismiss()
    }
}
