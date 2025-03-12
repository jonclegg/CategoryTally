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
    
    // MARK: - QR Code Export
    
    enum ExportError: Error, LocalizedError {
        case encodingFailed
        case compressionFailed
        case dataTooLarge
        case qrGenerationFailed
        
        var errorDescription: String? {
            switch self {
            case .encodingFailed:
                return "Failed to encode data"
            case .compressionFailed:
                return "Failed to compress data"
            case .dataTooLarge:
                return "Data is too large for a QR code. Try removing some categories or expenses."
            case .qrGenerationFailed:
                return "Failed to generate QR code"
            }
        }
    }
    
    func exportAsQRCode() throws -> UIImage {
        // Step 1: Encode data to JSON
        guard let jsonData = try? JSONEncoder().encode(categories) else {
            throw ExportError.encodingFailed
        }
        
        // Step 2: Compress data
        guard let compressedData = compressData(jsonData) else {
            throw ExportError.compressionFailed
        }
        
        // Step 3: Check if data is too large for QR code
        // QR code version 40 with high error correction can store up to about 2,953 bytes
        let maxQRCodeCapacity = 2953
        if compressedData.count > maxQRCodeCapacity {
            throw ExportError.dataTooLarge
        }
        
        // Step 4: Generate QR code
        guard let qrImage = generateQRCode(from: compressedData) else {
            throw ExportError.qrGenerationFailed
        }
        
        return qrImage
    }
    
    private func compressData(_ data: Data) -> Data? {
        // Use zlib compression
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        defer {
            destinationBuffer.deallocate()
        }
        
        let sourceBytes = [UInt8](data)
        var sourceBuffer = sourceBytes
        
        var stream = z_stream()
        stream.next_in = UnsafeMutablePointer<UInt8>(mutating: &sourceBuffer)
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
    
    private func generateQRCode(from data: Data) -> UIImage? {
        // Convert data to base64 string for QR code
        let base64String = data.base64EncodedString()
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        // Set highest correction level
        filter.correctionLevel = "H"
        filter.setValue(base64String.data(using: .utf8), forKey: "inputMessage")
        
        guard let outputImage = filter.outputImage else {
            return nil
        }
        
        // Scale up the image for better visibility and sharing
        let scale = 10.0
        let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        // Create a larger context for the QR code with white background
        let size = CGSize(width: transformedImage.extent.width + 40, height: transformedImage.extent.height + 40)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        if let graphicsContext = UIGraphicsGetCurrentContext() {
            // Fill background with white
            graphicsContext.setFillColor(UIColor.white.cgColor)
            graphicsContext.fill(CGRect(origin: .zero, size: size))
            
            // Convert CIImage to CGImage using CIContext
            if let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) {
                let imageRect = CGRect(
                    x: (size.width - transformedImage.extent.width) / 2,
                    y: (size.height - transformedImage.extent.height) / 2,
                    width: transformedImage.extent.width,
                    height: transformedImage.extent.height
                )
                graphicsContext.draw(cgImage, in: imageRect)
            }
        }
        
        // Get the image from the context
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return result
    }
    
    // MARK: - QR Code Import
    
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
                return "Invalid QR code data"
            }
        }
    }
    
    func importFromQRCodeData(_ data: Data) throws {
        // Step 1: Decompress data
        guard let decompressedData = decompressData(data) else {
            throw ImportError.decompressFailed
        }
        
        // Step 2: Decode JSON
        guard let decodedCategories = try? JSONDecoder().decode([Category].self, from: decompressedData) else {
            throw ImportError.decodingFailed
        }
        
        // Step 3: Update categories
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
        
        var sourceBytes = [UInt8](data)
        
        var stream = z_stream()
        stream.next_in = UnsafeMutablePointer<UInt8>(mutating: &sourceBytes)
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