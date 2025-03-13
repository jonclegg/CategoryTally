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
    @State private var showingDataExport = false
    @State private var showingDataImport = false
    @State private var showingDemoDataAlert = false
    
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
                
                // Hidden button in the bottom right corner
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color.gray.opacity(0.1)) // Slightly visible for debugging
                            .frame(width: 80, height: 80) // Larger touch area
                            .contentShape(Circle())
                            .onLongPressGesture(minimumDuration: 2.0) {
                                showingDemoDataAlert = true
                            }
                            .padding()
                            // Add a tap gesture with a print statement for debugging
                            .onTapGesture {
                                print("Tapped hidden button - long press for 2 seconds to activate")
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
                            showingDataExport = true
                        }) {
                            Label("Export Data", systemImage: "square.and.arrow.up")
                        }
                        .disabled(dataStore.categories.isEmpty)
                        
                        Button(action: {
                            showingDataImport = true
                        }) {
                            Label("Import Data", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Label("Data Options", systemImage: "doc.text")
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
            .sheet(isPresented: $showingDataExport) {
                DataExportView(dataStore: dataStore)
            }
            .sheet(isPresented: $showingDataImport) {
                DataImportView(dataStore: dataStore)
            }
            .alert(isPresented: $showingDemoDataAlert) {
                Alert(
                    title: Text("Generate Demo Data"),
                    message: Text("This will replace all your current data with example data for demonstration purposes. This action cannot be undone."),
                    primaryButton: .destructive(Text("Generate Demo Data")) {
                        dataStore.generateDemoData()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}

#Preview {
    ContentView()
}
