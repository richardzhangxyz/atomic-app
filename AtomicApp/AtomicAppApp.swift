//
//  AtomicAppApp.swift
//  AtomicApp
//
//  Created by 张驰 on 1/19/26.
//

import SwiftUI
import SwiftData
import Combine

@main
struct AtomicAppApp: App {
    @StateObject private var unlockManager = UnlockManager.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PauseEvent.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(unlockManager)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func handleIncomingURL(_ url: URL) {
        // Handle atomicapp://unlock deep links from shield
        guard url.scheme == "atomicapp" else { return }
        
        if url.host == "unlock" {
            unlockManager.checkPendingUnlockRequest()
        }
    }
}

/// Manages unlock requests from the shield extension
class UnlockManager: ObservableObject {
    static let shared = UnlockManager()
    
    @Published var hasPendingUnlock: Bool = false
    @Published var pendingAppName: String?
    @Published var showUnlockModal: Bool = false
    
    private init() {
        // Check on app launch if there's a pending request
        checkPendingUnlockRequest()
    }
    
    func checkPendingUnlockRequest() {
        let defaults = UserDefaults(suiteName: "group.com.01labs.kaizen")
        
        guard let isPending = defaults?.bool(forKey: "pendingUnlockRequest"), isPending else {
            hasPendingUnlock = false
            return
        }
        
        // Check if the request is recent (within 5 minutes)
        if let timestamp = defaults?.double(forKey: "pendingUnlockTimestamp") {
            let requestTime = Date(timeIntervalSince1970: timestamp)
            let elapsed = Date().timeIntervalSince(requestTime)
            
            if elapsed > 300 { // 5 minutes
                // Request expired
                clearPendingRequest()
                return
            }
        }
        
        pendingAppName = defaults?.string(forKey: "pendingUnlockAppName")
        hasPendingUnlock = true
        showUnlockModal = true
        
        print("📲 Pending unlock request for: \(pendingAppName ?? "Unknown")")
    }
    
    func clearPendingRequest() {
        let defaults = UserDefaults(suiteName: "group.com.01labs.kaizen")
        defaults?.set(false, forKey: "pendingUnlockRequest")
        defaults?.removeObject(forKey: "pendingUnlockAppName")
        defaults?.removeObject(forKey: "pendingUnlockTimestamp")
        defaults?.removeObject(forKey: "pendingUnlockAppToken")
        
        hasPendingUnlock = false
        pendingAppName = nil
        showUnlockModal = false
    }
}
