//
//  ShieldActionExtension.swift
//  AtomicShieldAction
//
//  Handles user actions from the shield UI
//

import Foundation
import ManagedSettings

/// This extension handles button taps on the shield
class ShieldActionExtension: ShieldActionDelegate {
    
    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            // User tapped "CONTINUE ANYWAY"
            // Store context for the main app
            let defaults = UserDefaults(suiteName: "group.com.01labs.kaizen")
            defaults?.set("App", forKey: "pendingUnlockAppName")
            defaults?.set(true, forKey: "pendingUnlockRequest")
            defaults?.set(Date().timeIntervalSince1970, forKey: "pendingUnlockTimestamp")
            
            print("🔔 Pending unlock request stored - please open the main app")
            
            // Note: Extensions cannot directly open the main app
            // User must manually open the app, which will detect the pending request
            completionHandler(.defer)
            
        case .secondaryButtonPressed:
            // User tapped "RETURN TO LIFE" - just dismiss the shield attempt
            completionHandler(.close)
            
        @unknown default:
            completionHandler(.close)
        }
    }
    
    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            let defaults = UserDefaults(suiteName: "group.com.01labs.kaizen")
            defaults?.set("Website", forKey: "pendingUnlockAppName")
            defaults?.set(true, forKey: "pendingUnlockRequest")
            defaults?.set(Date().timeIntervalSince1970, forKey: "pendingUnlockTimestamp")
            
            print("🔔 Pending unlock request stored - please open the main app")
            
            completionHandler(.defer)
            
        case .secondaryButtonPressed:
            completionHandler(.close)
            
        @unknown default:
            completionHandler(.close)
        }
    }
    
    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            let defaults = UserDefaults(suiteName: "group.com.01labs.kaizen")
            defaults?.set("Category", forKey: "pendingUnlockAppName")
            defaults?.set(true, forKey: "pendingUnlockRequest")
            defaults?.set(Date().timeIntervalSince1970, forKey: "pendingUnlockTimestamp")
            
            print("🔔 Pending unlock request stored - please open the main app")
            
            completionHandler(.defer)
            
        case .secondaryButtonPressed:
            completionHandler(.close)
            
        @unknown default:
            completionHandler(.close)
        }
    }
}
