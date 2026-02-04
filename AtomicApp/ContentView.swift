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
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selection = FamilyActivitySelection()
    @State private var isPresented = false
    @State private var dailyLimitMinutes: Int = 1
    @State private var activityName = DeviceActivityName("DailyLimit")
    @State private var isMonitoring: Bool = false
    @State private var showPauseModal: Bool = false
    @State private var showEventLog: Bool = false
    @State private var showAnalytics: Bool = false
    @State private var isBlocked: Bool = false
    @State private var attemptCount: Int = 0
    
    // Toast state
    @State private var toastMessage: String = ""
    @State private var showToast: Bool = false
    
    // MARK: - Adaptive Color System
    
    // Background: Vivid gold in light mode, dark in dark mode
    private var backgroundColor: Color {
        colorScheme == .dark 
            ? Color(red: 0.1, green: 0.1, blue: 0.1) 
            : Color(red: 1.0, green: 0.85, blue: 0.0) // #FFD900
    }
    
    // Primary text: Black in light mode, bright yellow in dark mode
    private var primaryTextColor: Color {
        colorScheme == .dark
            ? Color(red: 1.0, green: 0.929, blue: 0.161) // #FFED29
            : Color.black
    }
    
    // Secondary text: Dark gray in light mode, dimmer yellow in dark mode
    private var secondaryTextColor: Color {
        colorScheme == .dark
            ? Color(red: 0.9, green: 0.836, blue: 0.145)
            : Color(red: 0.15, green: 0.15, blue: 0.15)
    }
    
    // Card background: Semi-transparent white in light, semi-transparent yellow in dark
    private var cardBackgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 1.0, green: 0.929, blue: 0.161).opacity(0.15)
            : Color.white.opacity(0.35)
    }
    
    // Card background hover: Slightly more opaque
    private var cardBackgroundColorHover: Color {
        colorScheme == .dark
            ? Color(red: 1.0, green: 0.929, blue: 0.161).opacity(0.25)
            : Color.white.opacity(0.5)
    }
    
    // Accent color for icons/highlights
    private var accentColor: Color {
        colorScheme == .dark
            ? Color(red: 1.0, green: 0.929, blue: 0.161)
            : Color.black
    }
    
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
            // Adaptive background: Gold in light mode, dark in dark mode
            backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        HStack {
                            Spacer()
                            
                            VStack(spacing: 8) {
                                Text("⚡ ATOMIC")
                                    .font(.system(size: 40, weight: .black, design: .rounded))
                                    .foregroundColor(primaryTextColor)
                                
                                Text("App time limits that actually work")
                                    .font(.subheadline)
                                    .foregroundColor(secondaryTextColor)
                            }
                            
                            Spacer()
                        }
                        
                        // Analytics Button - Prominent placement
                        Button {
                            showAnalytics = true
                        } label: {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .font(.headline)
                                Text("View Analytics")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(colorScheme == .dark ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(colorScheme == .dark ? accentColor : Color.black)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                    }
                    .padding(.top, 20)
                    
                    // BLOCKED STATE - High urgency
                    if isBlocked {
                        VStack(spacing: 16) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 50))
                                .foregroundColor(Color(red: 0.757, green: 0.071, blue: 0.122))
                            
                            Text("APPS BLOCKED")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(primaryTextColor)
                            
                            Text("Time limit reached")
                                .font(.body)
                                .foregroundColor(secondaryTextColor)
                            
                            Button {
                                showPauseModal = true
                            } label: {
                                Text("Unlock")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color(red: 0.757, green: 0.071, blue: 0.122))
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 20)
                        .background(cardBackgroundColor)
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    
                    // SETUP SECTION
                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            HStack {
                                Text("SETUP")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(primaryTextColor)
                                Spacer()
                            }
                        }
                        .padding(.horizontal)
                        
                        // App Selection
                        VStack(spacing: 12) {
                            Button {
                                isPresented = true
                            } label: {
                                HStack {
                                    Image(systemName: selection.applications.isEmpty ? "app.badge.plus" : "app.badge.checkmark.fill")
                                        .font(.title2)
                                        .foregroundColor(accentColor)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(selection.applications.isEmpty ? "Choose Apps to Control" : "Apps Selected")
                                            .font(.headline)
                                            .foregroundColor(primaryTextColor)
                                        
                                        if !selection.applications.isEmpty {
                                            Text("\(selection.applications.count) app(s) · \(selection.categories.count) category · \(selection.webDomains.count) domain(s)")
                                                .font(.caption)
                                                .foregroundColor(secondaryTextColor)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(secondaryTextColor.opacity(0.5))
                                }
                                .padding(20)
                                .background(cardBackgroundColor)
                                .cornerRadius(16)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Time Limit
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .font(.title2)
                                    .foregroundColor(accentColor)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Daily Limit")
                                        .font(.headline)
                                        .foregroundColor(primaryTextColor)
                                    Text("Set your boundary")
                                        .font(.caption)
                                        .foregroundColor(secondaryTextColor)
                                }
                                
                                Spacer()
                                
                                Text("\(dailyLimitMinutes) min")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(primaryTextColor)
                            }
                            .padding(20)
                            .background(cardBackgroundColor)
                            .cornerRadius(16)
                            
                            Stepper("", value: $dailyLimitMinutes, in: 1...480, step: 1)
                                .labelsHidden()
                                .padding(.horizontal)
                        }
                        .padding(.horizontal)
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            if !isMonitoring {
                                Button {
                                    setUpMonitoring()
                                    isMonitoring = true
                                } label: {
                                    HStack {
                                        Image(systemName: "bolt.fill")
                                            .font(.title2)
                                        Text("Start Monitoring")
                                            .font(.system(size: 18, weight: .bold))
                                    }
                                    .foregroundColor(colorScheme == .dark ? Color.black : Color.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(colorScheme == .dark ? Color(red: 1.0, green: 0.929, blue: 0.161) : Color.black)
                                    .cornerRadius(12)
                                }
                                .disabled(selection.applications.isEmpty)
                                .opacity(selection.applications.isEmpty ? 0.5 : 1.0)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // MONITORING STATUS
                    if isMonitoring {
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 12, height: 12)
                                
                                Text("ACTIVE")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(primaryTextColor)
                                
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Monitoring")
                                        .font(.subheadline)
                                        .foregroundColor(secondaryTextColor)
                                    Spacer()
                                    Text("\(selection.applications.count) app(s)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(primaryTextColor)
                                }
                                
                                HStack {
                                    Text("Daily Limit")
                                        .font(.subheadline)
                                        .foregroundColor(secondaryTextColor)
                                    Spacer()
                                    Text("\(dailyLimitMinutes) min")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(primaryTextColor)
                                }
                            }
                        }
                        .padding(20)
                        .background(cardBackgroundColor)
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    
                    // TESTING & LOGS (condensed)
                    VStack(spacing: 12) {
                        HStack {
                            Text("⚙️ TESTING")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(secondaryTextColor.opacity(0.7))
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            Button {
                                unlockApps()
                                setUpMonitoringWithSeconds(5)
                                isMonitoring = true
                                showToast(message: "⚡ 5 sec test started")
                            } label: {
                                HStack {
                                    Image(systemName: "hare.fill")
                                    Text("5s Test")
                                        .fontWeight(.semibold)
                                }
                                .font(.subheadline)
                                .foregroundColor(primaryTextColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(cardBackgroundColorHover)
                                .cornerRadius(12)
                            }
                            
                            Button {
                                showPauseModal = true
                            } label: {
                                HStack {
                                    Image(systemName: "shield.fill")
                                    Text("Test Shield")
                                        .fontWeight(.semibold)
                                }
                                .font(.subheadline)
                                .foregroundColor(primaryTextColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(cardBackgroundColorHover)
                                .cornerRadius(12)
                            }
                            
                            Button {
                                showEventLog = true
                            } label: {
                                HStack {
                                    Image(systemName: "chart.bar.fill")
                                    Text("Log")
                                        .fontWeight(.semibold)
                                }
                                .font(.subheadline)
                                .foregroundColor(primaryTextColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(cardBackgroundColorHover)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            
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
                minutesSpent: dailyLimitMinutes,
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
        .fullScreenCover(isPresented: $showAnalytics) {
            AnalyticsDashboardView()
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
