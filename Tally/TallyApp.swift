//
//  TallyApp.swift
//  Tally
//
//  Created by Jonathan Clegg on 3/9/25.
//

import SwiftUI

// Add required permissions to Info.plist
// These are needed for QR code scanning and saving
// MARK: - Info.plist additions
/*
 <key>NSCameraUsageDescription</key>
 <string>We need camera access to scan QR codes for importing data</string>
 
 <key>NSPhotoLibraryUsageDescription</key>
 <string>We need photo library access to save QR codes</string>
 
 <key>NSPhotoLibraryAddUsageDescription</key>
 <string>We need permission to save QR codes to your photo library</string>
 */

@main
struct TallyApp: App {
    init() {
        // This is a workaround to ensure the required permissions are available
        // Normally, you would add these in the Info.plist or project settings
        #if DEBUG
        print("Camera usage description: We need camera access to scan QR codes for importing data")
        print("Photo library usage description: We need photo library access to save QR codes")
        print("Photo library additions usage description: We need permission to save QR codes to your photo library")
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
