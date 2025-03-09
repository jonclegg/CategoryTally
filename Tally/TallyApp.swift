//
//  TallyApp.swift
//  Tally
//
//  Created by Jonathan Clegg on 3/9/25.
//

import SwiftUI

@main
struct TallyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
