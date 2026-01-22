//
//  ContentView.swift
//  AtomicApp
//
//  Created by 张驰 on 1/19/26.
//

import SwiftUI
import FamilyControls
import ManagedSettings
import DeviceActivity

struct ContentView: View {
    // object with shared property shared across the app
    // checks if this app has the permission to adjust screen time
    let center = AuthorizationCenter.shared
    
    // Stores which apps the user picks
    // FamilyActivitySelection is Apple's privacy-protected struct that contains apps, websites, and categories
    @State private var selection = FamilyActivitySelection()
    // Controls whether the picker sheet is showing
    @State private var isPresented = false
    @State private var dailyLimitMinutes: Int = 1
    // Unique identifier for your monitoring schedule
    @State private var activityName = DeviceActivityName("DailyLimit")
    
    func requestAuthorization() async {
        do {
            try await center.requestAuthorization(for: .individual)
        } catch {
            print("Authorization failed: \(error)")
        }
    }
    
    func setUpMonitoring() {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        // Transform each item in the set and extract just its token
        let applicationTokens = selection.applications.compactMap { $0.token }
        
        // Creates a unique identifier for this specific event.
        let eventName = DeviceActivityEvent.Name("LimitReached")
        // Struct as rule for when to trigger the event
        let event = DeviceActivityEvent(
            // Watch these specific apps
            applications: Set(applicationTokens),
            // threshold to fire
            threshold: DateComponents(minute: dailyLimitMinutes)
        )
        
        let center = DeviceActivityCenter()
        // Save selection to App Group first
        saveSelectionToAppGroup()
        
        do {
            // Pass the event to startMonitoring
            try center.startMonitoring(
                activityName,
                during: schedule,
                events: [eventName: event]
            )
            print("Monitoring started with \(dailyLimitMinutes) min limit")
        } catch {
            print("Failed to start monitoring: \(error)")
        }
    }
    
    func saveSelectionToAppGroup() {
        let defaults = UserDefaults(suiteName: "group.com.01labs.kaizen")
        
        // Convert selection to data we can save
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(selection)
            defaults?.set(data, forKey: "selectedApps")
            print("✅ Saved selection to App Group")
        } catch {
            print("❌ Failed to save selection: \(error)")
        }
    }
    
    
    var body: some View {
        VStack (spacing: 10){
            Button("Select Apps to Limit") {
                isPresented = true
            }
            
            VStack (spacing: 10){
                Text("Selected \(selection.applications.count) apps")
                Text("Selected \(selection.categories.count) categories")
                Text("Selected \(selection.webDomains.count) web domains")
            }
            .padding()
            
            Stepper("Daily Limit: \(dailyLimitMinutes) minutes",
                    value: $dailyLimitMinutes,
                    in: 1...480,
                    step: 1)
            .padding()
            
            Button("Start Monitoring") {
                setUpMonitoring()
            }.buttonStyle(.borderedProminent)
        }
        
        // Modifiers are instructors and not sequential pieces of code
        .padding()
        // When isPresentedis true, show the FamilyActivityPicker
        .familyActivityPicker(isPresented: $isPresented, selection: $selection)
        .task {
            await requestAuthorization()
        }
    }
}  

#Preview {
    ContentView()
}
