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
    
    // Toast state
    @State private var toastMessage: String = ""
    @State private var showToast: Bool = false
    
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
    
    /// Quick testing function with seconds instead of minutes
    func setUpMonitoringWithSeconds(_ seconds: Int) {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        let applicationTokens = selection.applications.compactMap { $0.token }
        let eventName = DeviceActivityEvent.Name("LimitReached")
        let event = DeviceActivityEvent(
            applications: Set(applicationTokens),
            threshold: DateComponents(second: seconds)
        )
        
        let center = DeviceActivityCenter()
        saveSelectionToAppGroup()
        
        do {
            try center.startMonitoring(
                activityName,
                during: schedule,
                events: [eventName: event]
            )
            print("⚡ TEST MODE: Monitoring started with \(seconds) SECOND limit")
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
    
    func showToast(message: String) {
        toastMessage = message
        withAnimation(.easeInOut(duration: 0.3)) {
            showToast = true
        }
        
        // Auto-hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showToast = false
            }
        }
    }
    
    var body: some View {
        ZStack {
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
            
            HStack(spacing: 12) {
                Button("Start Monitoring") {
                    setUpMonitoring()
                    isMonitoring = true
                }
                .buttonStyle(.borderedProminent)
                
                // Quick 5-second test button
                Button("5 sec test") {
                    // First, clear all existing restrictions
                    unlockApps()
                    
                    // Then set up fresh monitoring with 5 second limit
                    setUpMonitoringWithSeconds(5)
                    isMonitoring = true
                    
                    // Show toast
                    showToast(message: "✓ Reset & started 5 sec limit for \(selection.applications.count) app(s)")
                }
                .buttonStyle(.bordered)
                .foregroundColor(.orange)
            }
            
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
            
            Button("💀 Test Brutal Modal") {
                showPauseModal = true
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
            
            // Debug: Show expected shield colors
            VStack(spacing: 4) {
                Text("Expected Shield Colors:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                HStack(spacing: 8) {
                    VStack {
                        Rectangle()
                            .fill(Color(red: 1.0, green: 0.929, blue: 0.161)) // #FFED29
                            .frame(width: 50, height: 30)
                            .cornerRadius(4)
                        Text("Light")
                            .font(.caption2)
                    }
                    VStack {
                        Rectangle()
                            .fill(Color(red: 0.702, green: 0.631, blue: 0.106)) // #B3A11B
                            .frame(width: 50, height: 30)
                            .cornerRadius(4)
                        Text("Dark")
                            .font(.caption2)
                    }
                }
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Button("📊 View Pause Log") {
                showEventLog = true
            }
            .buttonStyle(.bordered)
            .foregroundColor(.purple)
        }
        .padding()
        
            // Toast overlay
            if showToast {
                VStack {
                    Spacer()
                    
                    Text(toastMessage)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.85))
                        )
                        .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        } // end ZStack
        .familyActivityPicker(isPresented: $isPresented, selection: $selection)
        .fullScreenCover(isPresented: $showPauseModal) {
            BrutalBlockModalView(
                appName: unlockManager.pendingAppName ?? (selection.applications.isEmpty ? "Blocked App" : "App"),
                minutesSpent: dailyLimitMinutes, // Using limit as proxy for time spent
                onUnlock: {
                    unlockApps()
                    unlockManager.clearPendingRequest()
                    showPauseModal = false
                    print("🔴 User unlocked — consequences accepted")
                },
                onStayBlocked: {
                    showPauseModal = false
                    unlockManager.showUnlockModal = false
                    attemptCount += 1
                    let defaults = UserDefaults(suiteName: "group.com.01labs.kaizen")
                    defaults?.set(attemptCount, forKey: "attemptCount")
                    print("💪 User stayed blocked — doing the hard thing")
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
