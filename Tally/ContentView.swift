//
//  ContentView.swift
//  Tally
//
//  Created by Jonathan Clegg on 3/9/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var dataStore = DataStore()
    @State private var showingAddCategory = false
    @State private var newCategoryName = ""
    @State private var showingQRCodeExport = false
    @State private var showingQRCodeScanner = false
    
    var body: some View {
        NavigationView {
            ZStack {
                List {
                    ForEach(dataStore.categories) { category in
                        NavigationLink(destination: CategoryDetailView(category: category, dataStore: dataStore)) {
                            VStack(alignment: .leading) {
                                Text(category.name)
                                    .font(.headline)
                                Text("Total: $\(String(format: "%.2f", category.total))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: dataStore.deleteCategory)
                }
                
                if dataStore.categories.isEmpty {
                    VStack {
                        Text("No categories yet")
                            .font(.headline)
                        Text("Tap the + button to create your first category")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button(action: {
                            showingAddCategory = true
                        }) {
                            Label("Add Category", systemImage: "plus.circle.fill")
                                .font(.title2)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }
            .navigationTitle("Tally")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddCategory = true
                    }) {
                        Label("Add Category", systemImage: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(action: {
                            showingQRCodeExport = true
                        }) {
                            Label("Export Data", systemImage: "square.and.arrow.up")
                        }
                        .disabled(dataStore.categories.isEmpty)
                        
                        Button(action: {
                            showingQRCodeScanner = true
                        }) {
                            Label("Import Data", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Label("Data Options", systemImage: "qrcode")
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                NavigationView {
                    Form {
                        Section(header: Text("New Category")) {
                            TextField("Category Name", text: $newCategoryName)
                        }
                    }
                    .navigationTitle("Add Category")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                newCategoryName = ""
                                showingAddCategory = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                if !newCategoryName.isEmpty {
                                    dataStore.addCategory(name: newCategoryName)
                                    newCategoryName = ""
                                    showingAddCategory = false
                                }
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingQRCodeExport) {
                QRCodeExportView(dataStore: dataStore)
            }
            .sheet(isPresented: $showingQRCodeScanner) {
                QRCodeScannerView(dataStore: dataStore)
            }
        }
    }
}

#Preview {
    ContentView()
}
