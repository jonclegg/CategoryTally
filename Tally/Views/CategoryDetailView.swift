import SwiftUI

struct CategoryDetailView: View {
    let category: Category
    @ObservedObject var dataStore: DataStore
    
    @State private var showingAddExpense = false
    @State private var newExpenseAmount = ""
    @State private var newExpenseDescription = ""
    
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack {
            // Header with total
            VStack {
                Text("Total")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("$\(String(format: "%.2f", category.total))")
                    .font(.system(size: 36, weight: .bold))
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)
            
            // List of expenses
            List {
                ForEach(category.items) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            if !item.description.isEmpty {
                                Text(item.description)
                                    .font(.headline)
                            }
                            Text(dateFormatter.string(from: item.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("$\(String(format: "%.2f", item.amount))")
                            .font(.headline)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indexSet in
                    dataStore.deleteExpense(from: category.id, at: indexSet)
                }
            }
            
            // Empty state
            if category.items.isEmpty {
                Spacer()
                VStack {
                    Text("No expenses yet")
                        .font(.headline)
                    Text("Tap the + button to add your first expense")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button(action: {
                        showingAddExpense = true
                    }) {
                        Label("Add Expense", systemImage: "plus.circle.fill")
                            .font(.title2)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                Spacer()
            }
        }
        .navigationTitle(category.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddExpense = true
                }) {
                    Label("Add Expense", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            NavigationView {
                Form {
                    Section(header: Text("New Expense")) {
                        TextField("Amount", text: $newExpenseAmount)
                            .keyboardType(.decimalPad)
                        
                        TextField("Description (optional)", text: $newExpenseDescription)
                    }
                }
                .navigationTitle("Add Expense")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            resetForm()
                            showingAddExpense = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            saveExpense()
                        }
                    }
                }
            }
        }
    }
    
    private func saveExpense() {
        guard let amount = Double(newExpenseAmount.replacingOccurrences(of: ",", with: ".")) else {
            return
        }
        
        dataStore.addExpense(to: category.id, amount: amount, description: newExpenseDescription)
        resetForm()
        showingAddExpense = false
    }
    
    private func resetForm() {
        newExpenseAmount = ""
        newExpenseDescription = ""
    }
}

#Preview {
    NavigationView {
        CategoryDetailView(
            category: Category(name: "Groceries", items: [
                ExpenseItem(amount: 25.99, description: "Randall's", date: Date()),
                ExpenseItem(amount: 15.50, description: "Trader Joe's", date: Date().addingTimeInterval(-86400))
            ]),
            dataStore: DataStore()
        )
    }
} 