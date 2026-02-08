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
            // Background
            AppTheme.Colors.background(for: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppTheme.Spacing.sectionSpacing) {
                    // Header
                    VStack(spacing: AppTheme.Spacing.md) {
                        VStack(spacing: AppTheme.Spacing.xs) {
                            Text("Atomic")
                                .font(AppTheme.Typography.largeTitle(weight: .medium))
                                .foregroundColor(AppTheme.Colors.textPrimary(for: colorScheme))
                            
                            Text("Intentional time boundaries")
                                .font(AppTheme.Typography.caption())
                                .foregroundColor(AppTheme.Colors.textMuted(for: colorScheme))
                        }
                        .padding(.top, AppTheme.Spacing.xl)
                        
                        // Analytics Button
                        Button {
                            showAnalytics = true
                        } label: {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                Image(systemName: "chart.xyaxis.line")
                                    .font(AppTheme.Typography.body())
                                    .imageScale(.medium)
                                Text("View Analytics")
                                    .font(AppTheme.Typography.body(weight: .medium))
                            }
                            .themePrimaryButton()
                        }
                        .padding(.horizontal, AppTheme.Spacing.xl)
                    }
                    
                    // BLOCKED STATE - Calm but firm
                    if isBlocked {
                        VStack(spacing: AppTheme.Spacing.lg) {
                            HStack(spacing: AppTheme.Spacing.md) {
                                Image(systemName: "lock.circle")
                                    .font(.system(size: 22))
                                    .foregroundColor(AppTheme.Colors.warning)
                                    .imageScale(.medium)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Time limit reached")
                                        .font(AppTheme.Typography.headline(weight: .medium))
                                        .foregroundColor(AppTheme.Colors.textPrimary(for: colorScheme))
                                    
                                    Text("Apps are paused")
                                        .font(AppTheme.Typography.caption())
                                        .foregroundColor(AppTheme.Colors.textSecondary(for: colorScheme))
                                }
                                
                                Spacer()
                            }
                            .padding(AppTheme.Spacing.cardPadding)
                            .themeCard(colorScheme: colorScheme)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                                    .stroke(AppTheme.Colors.warning.opacity(0.3), lineWidth: 1)
                                    .padding(.leading, 0)
                                    .frame(width: 3)
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                                    ),
                                alignment: .leading
                            )
                            .padding(.horizontal, AppTheme.Spacing.xl)
                            
                            Button {
                                showPauseModal = true
                            } label: {
                                Text("Unlock apps")
                                    .font(AppTheme.Typography.body(weight: .medium))
                                    .themeOutlineButton(color: AppTheme.Colors.destructive)
                            }
                            .padding(.horizontal, AppTheme.Spacing.xl)
                        }
                    }
                    
                    // SETUP SECTION
                    VStack(spacing: AppTheme.Spacing.lg) {
                        HStack {
                            Text("Setup")
                                .themeUppercaseLabel(colorScheme: colorScheme)
                            Spacer()
                        }
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        
                        // App Selection Card
                        Button {
                            isPresented = true
                        } label: {
                            HStack(spacing: AppTheme.Spacing.md) {
                                Image(systemName: selection.applications.isEmpty ? "app" : "app.badge.checkmark")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppTheme.Colors.textSecondary(for: colorScheme))
                                    .imageScale(.medium)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Apps Selected")
                                        .font(AppTheme.Typography.body(weight: .medium))
                                        .foregroundColor(AppTheme.Colors.textPrimary(for: colorScheme))
                                    
                                    Text("\(selection.applications.count) app · \(selection.categories.count) categories · \(selection.webDomains.count) domains")
                                        .font(AppTheme.Typography.caption())
                                        .foregroundColor(AppTheme.Colors.textSecondary(for: colorScheme))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.Colors.textMuted(for: colorScheme))
                            }
                            .padding(AppTheme.Spacing.cardPadding)
                            .themeCard(colorScheme: colorScheme)
                        }
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        
                        // Daily Limit Card
                        VStack(spacing: AppTheme.Spacing.cardSpacing) {
                            HStack(spacing: AppTheme.Spacing.md) {
                                Image(systemName: "clock")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppTheme.Colors.textSecondary(for: colorScheme))
                                    .imageScale(.medium)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Daily Limit")
                                        .font(AppTheme.Typography.body(weight: .medium))
                                        .foregroundColor(AppTheme.Colors.textPrimary(for: colorScheme))
                                    
                                    Text("Set your boundary")
                                        .font(AppTheme.Typography.caption())
                                        .foregroundColor(AppTheme.Colors.textSecondary(for: colorScheme))
                                }
                                
                                Spacer()
                                
                                Text("\(dailyLimitMinutes) min")
                                    .font(AppTheme.Typography.title(weight: .semibold))
                                    .foregroundColor(AppTheme.Colors.accent)
                            }
                            .padding(AppTheme.Spacing.cardPadding)
                            .themeCard(colorScheme: colorScheme)
                            
                            // Stepper controls
                            HStack(spacing: AppTheme.Spacing.md) {
                                Button {
                                    if dailyLimitMinutes > 1 {
                                        dailyLimitMinutes -= 1
                                    }
                                } label: {
                                    Image(systemName: "minus.circle")
                                        .font(.system(size: 28))
                                        .foregroundColor(AppTheme.Colors.textSecondary(for: colorScheme))
                                }
                                .disabled(dailyLimitMinutes <= 1)
                                .opacity(dailyLimitMinutes <= 1 ? 0.3 : 1.0)
                                
                                Spacer()
                                
                                Button {
                                    if dailyLimitMinutes < 480 {
                                        dailyLimitMinutes += 1
                                    }
                                } label: {
                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 28))
                                        .foregroundColor(AppTheme.Colors.textSecondary(for: colorScheme))
                                }
                                .disabled(dailyLimitMinutes >= 480)
                                .opacity(dailyLimitMinutes >= 480 ? 0.3 : 1.0)
                            }
                            .padding(.horizontal, AppTheme.Spacing.xxl)
                        }
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        
                        // Start Monitoring Button
                        if !isMonitoring {
                            Button {
                                setUpMonitoring()
                                isMonitoring = true
                            } label: {
                                HStack(spacing: AppTheme.Spacing.sm) {
                                    Image(systemName: "play.circle")
                                        .imageScale(.medium)
                                    Text("Start Monitoring")
                                        .font(AppTheme.Typography.body(weight: .medium))
                                }
                                .themePrimaryButton(isEnabled: !selection.applications.isEmpty, colorScheme: colorScheme)
                            }
                            .disabled(selection.applications.isEmpty)
                            .padding(.horizontal, AppTheme.Spacing.xl)
                        }
                    }
                    
                    // MONITORING STATUS
                    if isMonitoring {
                        VStack(spacing: AppTheme.Spacing.lg) {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                ThemeStatusIndicator(isActive: true)
                                Spacer()
                            }
                            
                            VStack(spacing: AppTheme.Spacing.md) {
                                HStack {
                                    Text("Monitoring")
                                        .font(AppTheme.Typography.body())
                                        .foregroundColor(AppTheme.Colors.textSecondary(for: colorScheme))
                                    Spacer()
                                    Text("\(selection.applications.count) app\(selection.applications.count == 1 ? "" : "s")")
                                        .font(AppTheme.Typography.body(weight: .medium))
                                        .foregroundColor(AppTheme.Colors.textPrimary(for: colorScheme))
                                }
                                
                                ThemeDivider()
                                
                                HStack {
                                    Text("Daily Limit")
                                        .font(AppTheme.Typography.body())
                                        .foregroundColor(AppTheme.Colors.textSecondary(for: colorScheme))
                                    Spacer()
                                    Text("\(dailyLimitMinutes) min")
                                        .font(AppTheme.Typography.body(weight: .medium))
                                        .foregroundColor(AppTheme.Colors.textPrimary(for: colorScheme))
                                }
                                
                                // Progress bar (placeholder for now)
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("Today's usage")
                                            .font(AppTheme.Typography.caption())
                                            .foregroundColor(AppTheme.Colors.textMuted(for: colorScheme))
                                        Spacer()
                                    }
                                    ThemeProgressBar(progress: 0.0)
                                }
                            }
                        }
                        .padding(AppTheme.Spacing.cardPadding)
                        .themeCard(colorScheme: colorScheme)
                        .padding(.horizontal, AppTheme.Spacing.xl)
                    }
                    
                    // DEBUG QUICK TEST
                    VStack(spacing: AppTheme.Spacing.lg) {
                        HStack {
                            Text("Debug")
                                .themeUppercaseLabel(colorScheme: colorScheme)
                            Spacer()
                        }
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        
                        // Prominent Debug Reset & 5s Test Button
                        Button {
                            unlockApps()
                            setUpMonitoringWithSeconds(5)
                            isMonitoring = true
                            showToast(message: "✅ Reset complete • 5s limit active")
                        } label: {
                            HStack(spacing: AppTheme.Spacing.md) {
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppTheme.Colors.accent)
                                    .imageScale(.medium)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Reset & Quick Test")
                                        .font(AppTheme.Typography.body(weight: .semibold))
                                        .foregroundColor(AppTheme.Colors.textPrimary(for: colorScheme))
                                    
                                    Text("Unlocks all apps, sets 5 second limit")
                                        .font(AppTheme.Typography.caption())
                                        .foregroundColor(AppTheme.Colors.textSecondary(for: colorScheme))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "timer")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppTheme.Colors.accent)
                            }
                            .padding(AppTheme.Spacing.cardPadding)
                            .themeCard(colorScheme: colorScheme)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                                    .stroke(AppTheme.Colors.accent.opacity(0.2), lineWidth: 1.5)
                            )
                        }
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        
                        // Other testing tools
                        HStack(spacing: AppTheme.Spacing.cardSpacing) {
                            Button {
                                showPauseModal = true
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: "shield")
                                        .font(.system(size: 18))
                                        .imageScale(.medium)
                                    Text("Shield")
                                        .font(AppTheme.Typography.caption(weight: .medium))
                                }
                                .foregroundColor(AppTheme.Colors.textSecondary(for: colorScheme))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppTheme.Spacing.lg)
                                .themeCard(colorScheme: colorScheme)
                            }
                            
                            Button {
                                showEventLog = true
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: "list.bullet")
                                        .font(.system(size: 18))
                                        .imageScale(.medium)
                                    Text("Log")
                                        .font(AppTheme.Typography.caption(weight: .medium))
                                }
                                .foregroundColor(AppTheme.Colors.textSecondary(for: colorScheme))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppTheme.Spacing.lg)
                                .themeCard(colorScheme: colorScheme)
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.xl)
                    }
                    .padding(.bottom, 40)
                }
            }
            
            // Toast overlay
            if showToast {
                VStack {
                    Spacer()
                    
                    Text(toastMessage)
                        .font(AppTheme.Typography.body(weight: .medium))
                        .foregroundColor(AppTheme.Colors.textPrimary(for: colorScheme))
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        .padding(.vertical, AppTheme.Spacing.md)
                        .background(
                            Capsule()
                                .fill(AppTheme.Colors.surfaceElevated(for: colorScheme))
                                .overlay(
                                    Capsule()
                                        .stroke(AppTheme.Colors.border(for: colorScheme), lineWidth: 1)
                                )
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
