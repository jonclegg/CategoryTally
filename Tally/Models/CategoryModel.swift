import Foundation
import UIKit
import CoreImage.CIFilterBuiltins
import zlib

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
    private let steganography = SteganographyModel()
    
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
    
    func updateCategoryName(id: UUID, newName: String) {
        if let index = categories.firstIndex(where: { $0.id == id }) {
            categories[index].name = newName
            saveData()
        }
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
    
    // MARK: - Text Export/Import
    
    func exportAsJSON() throws -> String {
        // Step 1: Encode data to JSON
        guard let jsonData = try? JSONEncoder().encode(categories) else {
            throw ExportError.encodingFailed
        }
        
        // Step 2: Convert to pretty-printed JSON string
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        let prettyJsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
        
        guard let jsonString = String(data: prettyJsonData, encoding: .utf8) else {
            throw ExportError.encodingFailed
        }
        
        return jsonString
    }
    
    func importFromJSON(_ jsonString: String) throws {
        // Step 1: Convert string to data
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw ImportError.invalidData
        }
        
        // Step 2: Decode JSON
        guard let decodedCategories = try? JSONDecoder().decode([Category].self, from: jsonData) else {
            throw ImportError.decodingFailed
        }
        
        // Step 3: Update categories
        self.categories = decodedCategories
        saveData()
    }
    
    // MARK: - Steganography Export
    
    enum ExportError: Error, LocalizedError {
        case encodingFailed
        case compressionFailed
        case dataTooLarge
        case imageGenerationFailed
        
        var errorDescription: String? {
            switch self {
            case .encodingFailed:
                return "Failed to encode data"
            case .compressionFailed:
                return "Failed to compress data"
            case .dataTooLarge:
                return "Data is too large for the image. Try removing some categories or expenses."
            case .imageGenerationFailed:
                return "Failed to generate image"
            }
        }
    }
    
    func exportAsImage() throws -> UIImage {
        // Step 1: Encode data to JSON
        guard let jsonData = try? JSONEncoder().encode(categories) else {
            throw ExportError.encodingFailed
        }
        
        // Step 2: Compress data
        guard let compressedData = compressData(jsonData) else {
            throw ExportError.compressionFailed
        }
        
        // Step 3: Check if data is too large for steganography
        let maxCapacity = steganography.getMaxCapacity()
        if compressedData.count > maxCapacity {
            throw ExportError.dataTooLarge
        }
        
        // Step 4: Generate image with embedded data
        let encodedImage = steganography.encode(bytes: [UInt8](compressedData))
        
        // Step 5: Add title and date to the image
        return addTitleToImage(encodedImage)
    }
    
    private func compressData(_ data: Data) -> Data? {
        // Use zlib compression
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        defer {
            destinationBuffer.deallocate()
        }
        
        let sourceBytes = [UInt8](data)
        
        var stream = z_stream()
        
        // Use withUnsafeBufferPointer to safely access the array memory
        return sourceBytes.withUnsafeBufferPointer { sourceBufferPtr in
            stream.next_in = UnsafeMutablePointer<UInt8>(mutating: sourceBufferPtr.baseAddress)
            stream.avail_in = UInt32(data.count)
            stream.next_out = destinationBuffer
            stream.avail_out = UInt32(data.count)
            
            // Initialize deflate
            let initResult = deflateInit2_(&stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, 15 + 16, 8, Z_DEFAULT_STRATEGY, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
            
            guard initResult == Z_OK else {
                return nil
            }
            
            // Compress
            let deflateResult = deflate(&stream, Z_FINISH)
            
            // Clean up
            deflateEnd(&stream)
            
            guard deflateResult == Z_STREAM_END else {
                return nil
            }
            
            // Create compressed data
            let compressedData = Data(bytes: destinationBuffer, count: Int(stream.total_out))
            return compressedData
        }
    }
    
    private func addTitleToImage(_ image: UIImage) -> UIImage {
        // Get current date formatted as string
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateString = dateFormatter.string(from: Date())
        
        // Create a larger context for the image with white background and text
        let padding: CGFloat = 40
        let topPadding: CGFloat = 150 // Much larger top area for prominent title and date
        let bottomPadding: CGFloat = 40
        
        // Calculate width - ensure it's at least 600 points wide
        let imageWidth: CGFloat = image.size.width
        let imageHeight: CGFloat = image.size.height
        let calculatedWidth: CGFloat = imageWidth + (padding * 2)
        let finalWidth: CGFloat = calculatedWidth < 600 ? 600 : calculatedWidth
        let finalHeight: CGFloat = imageHeight + topPadding + bottomPadding
        
        // Create the size with explicit CGFloat values
        let size = CGSize(width: finalWidth, height: finalHeight)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        if let graphicsContext = UIGraphicsGetCurrentContext() {
            // Fill background with white
            graphicsContext.setFillColor(UIColor.white.cgColor)
            graphicsContext.fill(CGRect(origin: .zero, size: size))
            
            // Draw a prominent colored header background
            let headerRect = CGRect(x: 0, y: 0, width: size.width, height: topPadding)
            graphicsContext.setFillColor(UIColor(red: 0.0, green: 0.4, blue: 0.8, alpha: 1.0).cgColor) // Bright blue
            graphicsContext.fill(headerRect)
            
            // Add title at the top in large white text
            let titleText = "CATEGORY TALLY"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 40),
                .foregroundColor: UIColor.white
            ]
            
            // Add date below title in white text
            let dateText = "Exported: \(dateString)"
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24),
                .foregroundColor: UIColor.white
            ]
            
            let titleSize = titleText.size(withAttributes: titleAttributes)
            let dateSize = dateText.size(withAttributes: dateAttributes)
            
            let titleX = (size.width - titleSize.width) / 2
            let titleY: CGFloat = 30 // Fixed position from top
            
            let dateX = (size.width - dateSize.width) / 2
            let dateY = titleY + titleSize.height + 15 // Position below title
            
            titleText.draw(at: CGPoint(x: titleX, y: titleY), withAttributes: titleAttributes)
            dateText.draw(at: CGPoint(x: dateX, y: dateY), withAttributes: dateAttributes)
            
            // Draw the steganography image
            if let cgImage = image.cgImage {
                // Calculate image position
                let imageX: CGFloat = (size.width - imageWidth) / 2
                let imageY: CGFloat = topPadding
                let imageRect = CGRect(
                    x: imageX,
                    y: imageY,
                    width: imageWidth,
                    height: imageHeight
                )
                graphicsContext.draw(cgImage, in: imageRect)
            }
        }
        
        // Get the image from the context
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return result ?? image
    }
    
    // MARK: - Steganography Import
    
    enum ImportError: Error, LocalizedError {
        case decodingFailed
        case decompressFailed
        case invalidData
        
        var errorDescription: String? {
            switch self {
            case .decodingFailed:
                return "Failed to decode data"
            case .decompressFailed:
                return "Failed to decompress data"
            case .invalidData:
                return "Invalid image data"
            }
        }
    }
    
    func importFromImage(_ image: UIImage) throws {
        // Step 1: Extract data from image
        let bytes = steganography.decode(image: image)
        let data = Data(bytes)
        
        // Step 2: Decompress data
        guard let decompressedData = decompressData(data) else {
            throw ImportError.decompressFailed
        }
        
        // Step 3: Decode JSON
        guard let decodedCategories = try? JSONDecoder().decode([Category].self, from: decompressedData) else {
            throw ImportError.decodingFailed
        }
        
        // Step 4: Update categories
        self.categories = decodedCategories
        saveData()
    }
    
    private func decompressData(_ data: Data) -> Data? {
        // Prepare for decompression
        let destinationBufferSize = 1024 * 1024 * 10 // 10MB max size
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destinationBufferSize)
        defer {
            destinationBuffer.deallocate()
        }
        
        let sourceBytes = [UInt8](data)
        
        var stream = z_stream()
        
        // Use withUnsafeBufferPointer to safely access the array memory
        return sourceBytes.withUnsafeBufferPointer { sourceBufferPtr in
            stream.next_in = UnsafeMutablePointer<UInt8>(mutating: sourceBufferPtr.baseAddress)
            stream.avail_in = UInt32(data.count)
            stream.next_out = destinationBuffer
            stream.avail_out = UInt32(destinationBufferSize)
            
            // Initialize inflate
            let initResult = inflateInit2_(&stream, 15 + 16, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
            
            guard initResult == Z_OK else {
                return nil
            }
            
            // Decompress
            let inflateResult = inflate(&stream, Z_FINISH)
            
            // Clean up
            inflateEnd(&stream)
            
            guard inflateResult == Z_STREAM_END else {
                return nil
            }
            
            // Create decompressed data
            let decompressedData = Data(bytes: destinationBuffer, count: Int(stream.total_out))
            return decompressedData
        }
    }
    
    // MARK: - Demo Data Generation
    
    func generateDemoData() {
        // Clear existing data
        categories = []
        
        // Create example categories for multiple months
        let months = ["January", "February", "March"]
        
        for month in months {
            // Groceries category for each month
            var groceriesCategory = Category(name: "\(month) Groceries")
            groceriesCategory.items = createDemoExpenses(month: month, type: "Groceries")
            categories.append(groceriesCategory)
            
            // Restaurants category for each month
            var restaurantsCategory = Category(name: "\(month) Restaurants")
            restaurantsCategory.items = createDemoExpenses(month: month, type: "Restaurants")
            categories.append(restaurantsCategory)
            
            // Utilities category for each month
            var utilitiesCategory = Category(name: "\(month) Utilities")
            utilitiesCategory.items = createDemoExpenses(month: month, type: "Utilities")
            categories.append(utilitiesCategory)
            
            // Transportation category for each month
            var transportationCategory = Category(name: "\(month) Transportation")
            transportationCategory.items = createDemoExpenses(month: month, type: "Transportation")
            categories.append(transportationCategory)
        }
        
        // Save the demo data
        saveData()
    }
    
    private func createDemoExpenses(month: String, type: String) -> [ExpenseItem] {
        var expenses: [ExpenseItem] = []
        
        // Create a date formatter to generate dates in the correct month
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy"
        
        // Get the current year
        let currentYear = Calendar.current.component(.year, from: Date())
        
        // Generate different expenses based on category type
        switch type {
        case "Groceries":
            let stores = ["Whole Foods", "Trader Joe's", "Safeway", "Costco", "Local Market"]
            let amounts = [45.67, 32.18, 78.92, 120.45, 25.30]
            
            for i in 1...5 {
                let dayOfMonth = i * 5 // Spread out over the month: 5th, 10th, 15th, etc.
                let dateString = "\(month) \(dayOfMonth), \(currentYear)"
                if let date = dateFormatter.date(from: dateString) {
                    let store = stores[i-1]
                    let amount = amounts[i-1]
                    let expense = ExpenseItem(amount: amount, description: store, date: date)
                    expenses.append(expense)
                }
            }
            
        case "Restaurants":
            let restaurants = ["Olive Garden", "Cheesecake Factory", "Local Bistro", "Sushi Place", "Pizza Night"]
            let amounts = [35.45, 68.20, 42.75, 55.30, 28.50]
            
            for i in 1...5 {
                let dayOfMonth = i * 4 + 2 // Different days: 6th, 10th, 14th, etc.
                let dateString = "\(month) \(dayOfMonth), \(currentYear)"
                if let date = dateFormatter.date(from: dateString) {
                    let restaurant = restaurants[i-1]
                    let amount = amounts[i-1]
                    let expense = ExpenseItem(amount: amount, description: restaurant, date: date)
                    expenses.append(expense)
                }
            }
            
        case "Utilities":
            let utilities = ["Electricity", "Water", "Internet", "Phone", "Gas"]
            let amounts = [85.42, 45.30, 65.99, 55.00, 38.25]
            
            for i in 1...5 {
                let dayOfMonth = i * 5 + 1 // Different days
                let dateString = "\(month) \(dayOfMonth), \(currentYear)"
                if let date = dateFormatter.date(from: dateString) {
                    let utility = utilities[i-1]
                    let amount = amounts[i-1]
                    let expense = ExpenseItem(amount: amount, description: utility, date: date)
                    expenses.append(expense)
                }
            }
            
        case "Transportation":
            let items = ["Gas", "Car Maintenance", "Parking", "Uber", "Public Transit"]
            let amounts = [45.30, 120.00, 25.00, 32.45, 40.00]
            
            for i in 1...5 {
                let dayOfMonth = i * 3 + 4 // Different days
                let dateString = "\(month) \(dayOfMonth), \(currentYear)"
                if let date = dateFormatter.date(from: dateString) {
                    let item = items[i-1]
                    let amount = amounts[i-1]
                    let expense = ExpenseItem(amount: amount, description: item, date: date)
                    expenses.append(expense)
                }
            }
            
        default:
            break
        }
        
        return expenses
    }
} 