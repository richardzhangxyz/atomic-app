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
    
    @EnvironmentObject var unlockManager: UnlockManager
    
    @State private var selection = FamilyActivitySelection()
    @State private var isPresented = false
    @State private var dailyLimitMinutes: Int = 1
    @State private var activityName = DeviceActivityName("DailyLimit")
    @State private var isMonitoring: Bool = false
    @State private var showPauseModal: Bool = false
    @State private var showEventLog: Bool = false
    @State private var isBlocked: Bool = false
    @State private var attemptCount: Int = 0
    
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
        isBlocked = defaults.bool(forKey: "isBlocked")
        attemptCount = defaults.integer(forKey: "attemptCount")
        print("✅ Loaded \(saved.applications.count) apps from previous session")
    }
    
    func checkBlockedStatus() {
        let defaults = UserDefaults(suiteName: "group.com.01labs.kaizen")
        isBlocked = defaults?.bool(forKey: "isBlocked") ?? false
        attemptCount = defaults?.integer(forKey: "attemptCount") ?? 0
    }
    
    func unlockApps() {
        let store = ManagedSettingsStore()
        store.clearAllSettings()
        
        let defaults = UserDefaults(suiteName: "group.com.01labs.kaizen")
        defaults?.set(false, forKey: "isBlocked")
        defaults?.set(0, forKey: "attemptCount")
        
        isBlocked = false
        attemptCount = 0
        print("✅ Apps unlocked")
    }
    
    var body: some View {
        VStack (spacing: 10){
            // Unlock section when apps are blocked
            if isBlocked {
                VStack(spacing: 12) {
                    Text("⏸️ Apps Blocked")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Your apps have reached their time limit.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        showPauseModal = true
                    } label: {
                        Text("Unlock Apps")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.5, green: 0.4, blue: 0.7),
                                        Color(red: 0.4, green: 0.5, blue: 0.75)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
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
            
            Button("⏸️ Test Pause Modal") {
                showPauseModal = true
            }
            .buttonStyle(.bordered)
            .foregroundColor(.blue)
            
            Button("📊 View Pause Log") {
                showEventLog = true
            }
            .buttonStyle(.bordered)
            .foregroundColor(.purple)
        }
        .padding()
        .familyActivityPicker(isPresented: $isPresented, selection: $selection)
        .fullScreenCover(isPresented: $showPauseModal) {
            PauseModalView(
                appName: unlockManager.pendingAppName ?? (selection.applications.isEmpty ? "Blocked App" : "App"),
                attemptCount: max(attemptCount, 1),
                onProceed: {
                    unlockApps()
                    unlockManager.clearPendingRequest()
                    showPauseModal = false
                    print("✅ User proceeded intentionally - apps unlocked")
                },
                onClose: {
                    showPauseModal = false
                    unlockManager.showUnlockModal = false
                    attemptCount += 1
                    let defaults = UserDefaults(suiteName: "group.com.01labs.kaizen")
                    defaults?.set(attemptCount, forKey: "attemptCount")
                    print("❌ User closed without proceeding - attempt count: \(attemptCount)")
                }
            )
        }
        .sheet(isPresented: $showEventLog) {
            PauseEventLogView()
        }
        .task {
            await requestAuthorization()
        }
        .onAppear {
            loadSavedSelection()
            checkBlockedStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            checkBlockedStatus()
            // Check for pending unlock requests from shield
            unlockManager.checkPendingUnlockRequest()
        }
        .onChange(of: unlockManager.showUnlockModal) { _, shouldShow in
            if shouldShow && !showPauseModal {
                showPauseModal = true
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(UnlockManager.shared)
}
