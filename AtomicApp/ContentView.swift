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
    let center = AuthorizationCenter.shared
    
    @State private var selection = FamilyActivitySelection()
    @State private var isPresented = false
    @State private var dailyLimitMinutes: Int = 1
    @State private var activityName = DeviceActivityName("DailyLimit")
    @State private var isMonitoring: Bool = false
    
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
        
        let applicationTokens = selection.applications.compactMap { $0.token }
        let eventName = DeviceActivityEvent.Name("LimitReached")
        let event = DeviceActivityEvent(
            applications: Set(applicationTokens),
            threshold: DateComponents(minute: dailyLimitMinutes)
        )
        
        let center = DeviceActivityCenter()
        saveSelectionToAppGroup()
        
        do {
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
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(selection)
            defaults?.set(data, forKey: "selectedApps")
            defaults?.set(dailyLimitMinutes, forKey: "dailyLimit")
            defaults?.set(true, forKey: "isMonitoring")
            print("✅ Saved selection to App Group")
        } catch {
            print("❌ Failed to save selection: \(error)")
        }
    }
    
    func loadSavedSelection() {
        guard let defaults = UserDefaults(suiteName: "group.com.01labs.kaizen"),
              let data = defaults.data(forKey: "selectedApps"),
              let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            print("📭 No saved selection found")
            return
        }
        
        selection = saved
        dailyLimitMinutes = defaults.integer(forKey: "dailyLimit")
        isMonitoring = defaults.bool(forKey: "isMonitoring")
        print("✅ Loaded \(saved.applications.count) apps from previous session")
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
                isMonitoring = true
            }
            .buttonStyle(.borderedProminent)
            
            if isMonitoring {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(.green)
                            .frame(width: 10, height: 10)
                        Text("Active")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Text("Monitoring \(selection.applications.count) app(s)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Limit: \(dailyLimitMinutes) min/day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
            
            Button("🔓 Manual Unblock (Testing)") {
                let store = ManagedSettingsStore()
                store.clearAllSettings()
                print("Manually cleared all shields")
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
        }
        .padding()
        .familyActivityPicker(isPresented: $isPresented, selection: $selection)
        .task {
            await requestAuthorization()
        }
        .onAppear {
            loadSavedSelection()
        }
    }
}

#Preview {
    ContentView()
}
