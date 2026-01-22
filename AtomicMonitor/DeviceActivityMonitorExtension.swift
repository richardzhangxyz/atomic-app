//
//  DeviceActivityMonitorExtension.swift
//  AtomicMonitor
//
//  Created by 张驰 on 1/21/26.
//

import DeviceActivity
import FamilyControls
import ManagedSettings
import Foundation

// Optionally override any of the functions below.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        // Handle the start of the interval.
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        // Handle the end of the interval.
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        
        print("⚠️ Time limit reached! Blocking apps now...")
        
        // Read the selection from App Group
        let defaults = UserDefaults(suiteName: "group.com.01labs.kaizen")
        
        guard let data = defaults?.data(forKey: "selectedApps") else {
            print("❌ No selection data found in App Group")
            return
        }
        
        // Decode the selection
        do {
            let decoder = JSONDecoder()
            let selection = try decoder.decode(FamilyActivitySelection.self, from: data)
            
            print("✅ Found \(selection.applications.count) apps to block")
            
            // Create the settings store and block the apps
            let store = ManagedSettingsStore()
            
            if !selection.applications.isEmpty {
                let appTokens = selection.applications.compactMap { $0.token }
                store.shield.applications = Set(appTokens)
            }
            
            if !selection.categories.isEmpty {
                let categoryTokens = selection.categories.compactMap { $0.token }
                store.shield.applicationCategories = .specific(Set(categoryTokens))
            }
            
            print("✅ Shield applied successfully")
            
        } catch {
            print("❌ Failed to decode selection: \(error)")
        }
    }
    
    
    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        
        // Handle the warning before the interval starts.
    }
    
    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        
        // Handle the warning before the interval ends.
    }
    
    override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventWillReachThresholdWarning(event, activity: activity)
        
        // Handle the warning before the event reaches its threshold.
    }
}
