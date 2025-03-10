import SwiftUI

struct CategoryDetailView: View {
    let category: Category
    @ObservedObject var dataStore: DataStore
    
    @State private var showingAddExpense = false
    @State private var newExpenseAmount = ""
    @State private var newExpenseDescription = ""
    @State private var showingEditCategory = false
    @State private var editedCategoryName = ""
    
    @State private var showingEditExpense = false
    @State private var selectedExpense: ExpenseItem? = nil
    @State private var editedExpenseAmount = ""
    @State private var editedExpenseDescription = ""
    
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
                    Button(action: {
                        selectedExpense = item
                        editedExpenseAmount = String(format: "%.2f", item.amount)
                        editedExpenseDescription = item.description
                        showingEditExpense = true
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                if !item.description.isEmpty {
                                    Text(item.description)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                                Text(dateFormatter.string(from: item.date))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("$\(String(format: "%.2f", item.amount))")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 4)
                    }
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
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button(action: {
                    editedCategoryName = category.name
                    showingEditCategory = true
                }) {
                    Text(category.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .underline(color: .gray.opacity(0.3))
                }
            }
            
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
        .sheet(isPresented: $showingEditCategory) {
            NavigationView {
                Form {
                    Section(header: Text("Edit Category")) {
                        TextField("Category Name", text: $editedCategoryName)
                    }
                }
                .navigationTitle("Edit Category")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingEditCategory = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            if !editedCategoryName.isEmpty {
                                dataStore.updateCategoryName(id: category.id, newName: editedCategoryName)
                                showingEditCategory = false
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditExpense) {
            NavigationView {
                Form {
                    Section(header: Text("Edit Expense")) {
                        TextField("Amount", text: $editedExpenseAmount)
                            .keyboardType(.decimalPad)
                        
                        TextField("Description (optional)", text: $editedExpenseDescription)
                    }
                }
                .navigationTitle("Edit Expense")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingEditExpense = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            updateExpense()
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
    
    private func updateExpense() {
        guard let expense = selectedExpense,
              let amount = Double(editedExpenseAmount.replacingOccurrences(of: ",", with: ".")) else {
            return
        }
        
        dataStore.updateExpense(in: category.id, expenseId: expense.id, amount: amount, description: editedExpenseDescription)
        showingEditExpense = false
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