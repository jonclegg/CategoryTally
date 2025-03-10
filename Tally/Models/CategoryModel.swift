import Foundation

struct Category: Identifiable, Codable {
    var id = UUID()
    var name: String
    var items: [ExpenseItem] = []
    
    var total: Double {
        items.reduce(0) { $0 + $1.amount }
    }
}

struct ExpenseItem: Identifiable, Codable {
    var id = UUID()
    var amount: Double
    var description: String
    var date: Date
}

class DataStore: ObservableObject {
    @Published var categories: [Category] = []
    
    private let saveKey = "SavedCategories"
    
    init() {
        loadData()
    }
    
    func saveData() {
        if let encoded = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    func loadData() {
        if let data = UserDefaults.standard.data(forKey: saveKey) {
            if let decoded = try? JSONDecoder().decode([Category].self, from: data) {
                categories = decoded
                return
            }
        }
        
        // No saved data
        categories = []
    }
    
    func addCategory(name: String) {
        let newCategory = Category(name: name)
        categories.append(newCategory)
        saveData()
    }
    
    func addExpense(to categoryId: UUID, amount: Double, description: String) {
        if let index = categories.firstIndex(where: { $0.id == categoryId }) {
            let newItem = ExpenseItem(amount: amount, description: description, date: Date())
            categories[index].items.append(newItem)
            saveData()
        }
    }
    
    func deleteCategory(at indexSet: IndexSet) {
        categories.remove(atOffsets: indexSet)
        saveData()
    }
    
    func deleteExpense(from categoryId: UUID, at indexSet: IndexSet) {
        if let index = categories.firstIndex(where: { $0.id == categoryId }) {
            categories[index].items.remove(atOffsets: indexSet)
            saveData()
        }
    }
} 