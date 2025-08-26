//
//  ContentView.swift
//  ExpenseTracker
//
//  Created by iMacPro on 26/06/25.
//

// ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var expenseStore: ExpenseStore
    @State private var selectedTab = 0
    @State private var showingAddExpense = false
    
    var body: some View {
        #if os(iOS)
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
                .tag(0)
            
            // Expenses Tab
            ExpenseListView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Expenses")
                }
                .tag(1)
            
            // Analytics Tab
            AnalyticsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Analytics")
                }
                .tag(2)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(3)
        }
        .accentColor(ThemeColors.primary)
        .overlay(
            // Floating Add Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingAddExpense = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(ThemeColors.primaryGradient)
                            .clipShape(Circle())
                            .shadow(color: ThemeColors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 90)
                    .scaleEffect(showingAddExpense ? 0.9 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showingAddExpense)
                }
            }
        )
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView()
        }
        #else
        // macOS Navigation using NavigationSplitView
        NavigationSplitView {
            SidebarView(selectedTab: $selectedTab)
        } detail: {
            Group {
                switch selectedTab {
                case 0:
                    DashboardView()
                case 1:
                    ExpenseListView()
                case 2:
                    AnalyticsView()
                case 3:
                    SettingsView()
                default:
                    DashboardView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showingAddExpense = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(ThemeColors.primary)
                }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView()
        }
        #endif
    }
}

#if os(macOS)
// MARK: - macOS Sidebar
struct SidebarView: View {
    @Binding var selectedTab: Int
    
    private let sidebarItems = [
        SidebarItem(id: 0, title: "Dashboard", icon: "house.fill"),
        SidebarItem(id: 1, title: "Expenses", icon: "list.bullet"),
        SidebarItem(id: 2, title: "Analytics", icon: "chart.bar.fill"),
        SidebarItem(id: 3, title: "Settings", icon: "gearshape.fill")
    ]
    
    var body: some View {
        List(sidebarItems, id: \.id, selection: $selectedTab) { item in
            NavigationLink(value: item.id) {
                Label(item.title, systemImage: item.icon)
            }
        }
        .navigationTitle("ExpenseTracker")
        .frame(minWidth: 200)
    }
}

struct SidebarItem {
    let id: Int
    let title: String
    let icon: String
}
#endif

#Preview {
    ContentView()
}
