//
//  AnalyticsDashboardView.swift
//  AtomicApp
//
//  Real-time analytics dashboard with visual charts
//

import SwiftUI
import SwiftData
import Charts

struct AnalyticsDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    // Real-time data query - automatically updates when new events are added
    @Query(sort: \PauseEvent.createdAt, order: .reverse) private var allEvents: [PauseEvent]
    
    @State private var selectedTimeRange: TimeRange = .week
    @State private var isRefreshing: Bool = false
    
    enum TimeRange: String, CaseIterable {
        case week = "7D"
        case month = "30D"
        case allTime = "All"
        
        var days: Int? {
            switch self {
            case .week: return 7
            case .month: return 30
            case .allTime: return nil
            }
        }
        
        var label: String {
            switch self {
            case .week: return "Past Week"
            case .month: return "Past Month"
            case .allTime: return "All Time"
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredEvents: [PauseEvent] {
        guard let days = selectedTimeRange.days else { return allEvents }
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return allEvents.filter { $0.createdAt >= cutoffDate }
    }
    
    private var totalEvents: Int {
        filteredEvents.count
    }
    
    private var proceedRate: Double {
        guard !filteredEvents.isEmpty else { return 0 }
        let proceedCount = filteredEvents.filter { $0.didProceed }.count
        return Double(proceedCount) / Double(filteredEvents.count)
    }
    
    private var currentStreak: Int {
        calculateStreak()
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            AppTheme.Colors.background(for: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppTheme.Spacing.sectionSpacing) {
                    // Header
                    VStack(spacing: AppTheme.Spacing.md) {
                        HStack {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 18))
                                    .foregroundColor(AppTheme.Colors.textSecondary(for: colorScheme))
                                    .imageScale(.medium)
                            }
                            
                            Spacer()
                            
                            VStack(spacing: 4) {
                                Text("Analytics")
                                    .font(AppTheme.Typography.title(weight: .semibold))
                                    .foregroundColor(AppTheme.Colors.textPrimary(for: colorScheme))
                                
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(AppTheme.Colors.accent)
                                        .frame(width: 6, height: 6)
                                    Text("Live")
                                        .font(AppTheme.Typography.label(weight: .medium))
                                        .foregroundColor(AppTheme.Colors.accent)
                                }
                            }
                            
                            Spacer()
                            
                            // Placeholder for symmetry
                            Color.clear
                                .frame(width: 44, height: 44)
                        }
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        .padding(.top, AppTheme.Spacing.xl)
                    }
                    
                    // Time Range Selector
                    HStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Button {
                                withAnimation(AppTheme.Animation.quick) {
                                    selectedTimeRange = range
                                }
                            } label: {
                                Text(range.rawValue)
                                    .font(AppTheme.Typography.caption(weight: .semibold))
                                    .foregroundColor(
                                        selectedTimeRange == range 
                                            ? AppTheme.Colors.background 
                                            : AppTheme.Colors.textSecondary
                                    )
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm)
                                            .fill(
                                                selectedTimeRange == range
                                                    ? AppTheme.Colors.accent
                                                    : AppTheme.Colors.surface
                                            )
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    
                    // Key Metrics Cards
                    VStack(spacing: AppTheme.Spacing.cardSpacing) {
                        HStack(spacing: AppTheme.Spacing.cardSpacing) {
                            MetricCard(
                                icon: "shield",
                                value: "\(totalEvents)",
                                label: "Total Blocks",
                                color: AppTheme.Colors.accent
                            )
                            
                            MetricCard(
                                icon: "flame",
                                value: "\(currentStreak)",
                                label: "Day Streak",
                                color: AppTheme.Colors.warning
                            )
                        }
                        
                        HStack(spacing: AppTheme.Spacing.cardSpacing) {
                            MetricCard(
                                icon: "checkmark.shield",
                                value: "\(Int((1 - proceedRate) * 100))%",
                                label: "Stayed Blocked",
                                color: AppTheme.Colors.success
                            )
                            
                            MetricCard(
                                icon: "lock.open",
                                value: "\(Int(proceedRate * 100))%",
                                label: "Unlocked",
                                color: AppTheme.Colors.destructive
                            )
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .transition(.opacity.combined(with: .scale))
                    .id(selectedTimeRange)
                    
                    // Charts
                    if !filteredEvents.isEmpty {
                        ChartCard(
                            title: "Proceed Rate Trend",
                            subtitle: "Daily unlock percentage"
                        ) {
                            ProceedRateTrendChart(
                                events: filteredEvents
                            )
                        }
                        
                        ChartCard(
                            title: "Time of Day Pattern",
                            subtitle: "When you're most tempted"
                        ) {
                            TimeOfDayHeatmap(
                                events: filteredEvents
                            )
                        }
                        
                        ChartCard(
                            title: "Top Blocked Apps",
                            subtitle: "Most frequent blocks"
                        ) {
                            TopAppsChart(
                                events: filteredEvents
                            )
                        }
                        
                        ChartCard(
                            title: "Your Response Patterns",
                            subtitle: "Most common answers"
                        ) {
                            ResponsePatternsView(
                                events: filteredEvents
                            )
                        }
                    } else {
                        // Empty State
                        VStack(spacing: AppTheme.Spacing.lg) {
                            Image(systemName: "chart.xyaxis.line")
                                .font(.system(size: 48))
                                .foregroundColor(AppTheme.Colors.textMuted(for: colorScheme))
                                .imageScale(.large)
                            
                            Text("No Data Yet")
                                .font(AppTheme.Typography.title(weight: .semibold))
                                .foregroundColor(AppTheme.Colors.textPrimary(for: colorScheme))
                            
                            Text("Analytics will appear after your first block")
                                .font(AppTheme.Typography.body())
                                .foregroundColor(AppTheme.Colors.textSecondary(for: colorScheme))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                        .themeCard(colorScheme: colorScheme)
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        
                        // Insights Section
                        ChartCard(
                            title: "Insights & Tips",
                            subtitle: "Based on your patterns"
                        ) {
                            InsightsView(
                                events: filteredEvents,
                                streak: currentStreak,
                                proceedRate: proceedRate
                            )
                        }
                    }
                    
                    // Data Info Footer
                    if !filteredEvents.isEmpty {
                        HStack(spacing: AppTheme.Spacing.md) {
                            Image(systemName: "chart.bar.doc.horizontal")
                                .font(AppTheme.Typography.caption())
                                .foregroundColor(AppTheme.Colors.textMuted(for: colorScheme))
                            
                            Text("\(filteredEvents.count) events in \(selectedTimeRange.label.lowercased())")
                                .font(AppTheme.Typography.caption())
                                .foregroundColor(AppTheme.Colors.textMuted(for: colorScheme))
                            
                            Spacer()
                            
                            Text("Updated now")
                                .font(AppTheme.Typography.caption())
                                .foregroundColor(AppTheme.Colors.textMuted(for: colorScheme))
                        }
                        .padding(AppTheme.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                                .fill(AppTheme.Colors.surface(for: colorScheme).opacity(0.5))
                        )
                        .padding(.horizontal, AppTheme.Spacing.xl)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func calculateStreak() -> Int {
        guard !allEvents.isEmpty else { return 0 }
        
        // Group events by date (ignoring time)
        let calendar = Calendar.current
        let eventsByDate = Dictionary(grouping: allEvents) { event in
            calendar.startOfDay(for: event.createdAt)
        }
        
        // Count consecutive days with at least one "stayed blocked" event
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        while true {
            if let eventsOnDay = eventsByDate[currentDate],
               eventsOnDay.contains(where: { !$0.didProceed }) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else if streak == 0 {
                // If today has no events, check yesterday to start streak
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                if let eventsOnDay = eventsByDate[currentDate],
                   eventsOnDay.contains(where: { !$0.didProceed }) {
                    streak += 1
                    currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                } else {
                    break
                }
            } else {
                break
            }
        }
        
        return streak
    }
}

// MARK: - Metric Card Component

struct MetricCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .imageScale(.medium)
            
            Text(value)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.Colors.textPrimary(for: colorScheme))
                .contentTransition(.numericText())
            
            Text(label)
                .font(AppTheme.Typography.caption())
                .foregroundColor(AppTheme.Colors.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xl)
        .themeCard(colorScheme: colorScheme)
        .animation(AppTheme.Animation.standard, value: value)
    }
}

// MARK: - Chart Card Component

struct ChartCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: () -> Content
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.Typography.headline(weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary(for: colorScheme))
                
                Text(subtitle)
                    .font(AppTheme.Typography.caption())
                    .foregroundColor(AppTheme.Colors.textSecondary(for: colorScheme))
            }
            
            content()
        }
        .padding(AppTheme.Spacing.cardPadding)
        .themeCard(colorScheme: colorScheme)
        .padding(.horizontal, AppTheme.Spacing.xl)
    }
}

// MARK: - Proceed Rate Trend Chart

struct ProceedRateTrendChart: View {
    let events: [PauseEvent]
    
    struct DailyProceedRate: Identifiable {
        let id = UUID()
        let date: Date
        let rate: Double
        let stayedBlockedRate: Double
    }
    
    private var dailyData: [DailyProceedRate] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: events) { event in
            calendar.startOfDay(for: event.createdAt)
        }
        
        return grouped.map { date, events in
            let proceedCount = events.filter { $0.didProceed }.count
            let rate = Double(proceedCount) / Double(events.count)
            return DailyProceedRate(date: date, rate: rate, stayedBlockedRate: 1 - rate)
        }
        .sorted { $0.date < $1.date }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Chart {
                ForEach(dailyData) { data in
                    LineMark(
                        x: .value("Date", data.date, unit: .day),
                        y: .value("Stayed Blocked %", data.stayedBlockedRate * 100)
                    )
                    .foregroundStyle(AppTheme.Colors.success)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Date", data.date, unit: .day),
                        y: .value("Stayed Blocked %", data.stayedBlockedRate * 100)
                    )
                    .foregroundStyle(AppTheme.Colors.success.opacity(0.15))
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Date", data.date, unit: .day),
                        y: .value("Stayed Blocked %", data.stayedBlockedRate * 100)
                    )
                    .foregroundStyle(AppTheme.Colors.success)
                }
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let intValue = value.as(Double.self) {
                            Text("\(Int(intValue))%")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(AppTheme.Colors.divider)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel(format: .dateTime.month().day(), centered: true)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
            .frame(height: 180)
        }
    }
}

// MARK: - Time of Day Heatmap

struct TimeOfDayHeatmap: View {
    let events: [PauseEvent]
    
    struct HourData: Identifiable {
        let id = UUID()
        let hour: Int
        let count: Int
        let label: String
    }
    
    private var hourlyData: [HourData] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: events) { event in
            calendar.component(.hour, from: event.createdAt)
        }
        
        return (0..<24).map { hour in
            let count = grouped[hour]?.count ?? 0
            let label: String
            switch hour {
            case 0..<6: label = "Night"
            case 6..<12: label = "Morning"
            case 12..<17: label = "Afternoon"
            case 17..<22: label = "Evening"
            default: label = "Night"
            }
            return HourData(hour: hour, count: count, label: label)
        }
    }
    
    var body: some View {
        Chart {
            ForEach(hourlyData) { data in
                BarMark(
                    x: .value("Hour", data.hour),
                    y: .value("Count", data.count)
                )
                .foregroundStyle(
                    data.count > 0
                        ? AppTheme.Colors.accent.gradient
                        : AppTheme.Colors.surface.gradient
                )
                .cornerRadius(4)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(AppTheme.Colors.divider)
            }
        }
        .chartXAxis {
            AxisMarks(values: [0, 6, 12, 18, 23]) { value in
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue):00")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                }
            }
        }
        .frame(height: 160)
    }
}

// MARK: - Top Apps Chart

struct TopAppsChart: View {
    let events: [PauseEvent]
    @Environment(\.colorScheme) private var colorScheme
    
    struct AppData: Identifiable {
        let id = UUID()
        let name: String
        let count: Int
    }
    
    private var topApps: [AppData] {
        let grouped = Dictionary(grouping: events) { event in
            event.appName ?? "Unknown"
        }
        
        return grouped.map { name, events in
            AppData(name: name, count: events.count)
        }
        .sorted { $0.count > $1.count }
        .prefix(5)
        .map { $0 }
    }
    
    var body: some View {
        if topApps.isEmpty {
            Text("No app data yet")
                .font(AppTheme.Typography.body())
                .foregroundColor(AppTheme.Colors.textSecondary(for: colorScheme))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, AppTheme.Spacing.xl)
        } else {
            VStack(spacing: AppTheme.Spacing.md) {
                ForEach(Array(topApps.enumerated()), id: \.element.id) { index, app in
                    HStack(spacing: AppTheme.Spacing.md) {
                        Text("#\(index + 1)")
                            .font(AppTheme.Typography.caption(weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textSecondary(for: colorScheme))
                            .frame(width: 30, alignment: .leading)
                        
                        Text(app.name)
                            .font(AppTheme.Typography.body())
                            .foregroundColor(AppTheme.Colors.textPrimary(for: colorScheme))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("\(app.count)")
                            .font(AppTheme.Typography.headline(weight: .semibold))
                            .foregroundColor(AppTheme.Colors.accent)
                    }
                    
                    if index < topApps.count - 1 {
                        ThemeDivider()
                    }
                }
            }
        }
    }
}

// MARK: - Insights View

struct InsightsView: View {
    let events: [PauseEvent]
    let streak: Int
    let proceedRate: Double
    @Environment(\.colorScheme) private var colorScheme
    
    struct Insight {
        let icon: String
        let text: String
        let type: InsightType
        
        enum InsightType {
            case positive
            case neutral
            case warning
            
            var color: Color {
                switch self {
                case .positive: return .green
                case .neutral: return .blue
                case .warning: return .orange
                }
            }
        }
    }
    
    private var insights: [Insight] {
        var results: [Insight] = []
        
        // Streak insights
        if streak >= 7 {
            results.append(Insight(
                icon: "flame.fill",
                text: "Amazing! You've maintained a \(streak)-day streak. Keep it going!",
                type: .positive
            ))
        } else if streak >= 3 {
            results.append(Insight(
                icon: "flame.fill",
                text: "\(streak) days strong! You're building a powerful habit.",
                type: .positive
            ))
        } else if streak == 0 && !events.isEmpty {
            results.append(Insight(
                icon: "target",
                text: "Start a streak by staying blocked next time you hit the limit.",
                type: .neutral
            ))
        }
        
        // Proceed rate insights
        let stayBlockedRate = 1 - proceedRate
        if stayBlockedRate >= 0.8 {
            results.append(Insight(
                icon: "checkmark.seal.fill",
                text: "Excellent self-control! You stay blocked \(Int(stayBlockedRate * 100))% of the time.",
                type: .positive
            ))
        } else if stayBlockedRate < 0.3 {
            results.append(Insight(
                icon: "exclamationmark.triangle.fill",
                text: "You're unlocking frequently (\(Int(proceedRate * 100))%). Try the reflection prompts.",
                type: .warning
            ))
        }
        
        // Time of day insights
        let calendar = Calendar.current
        let timeGroups = Dictionary(grouping: events) { event -> String in
            let hour = calendar.component(.hour, from: event.createdAt)
            switch hour {
            case 0..<6: return "Night"
            case 6..<12: return "Morning"
            case 12..<17: return "Afternoon"
            case 17..<22: return "Evening"
            default: return "Night"
            }
        }
        
        if let peakTime = timeGroups.max(by: { $0.value.count < $1.value.count }) {
            results.append(Insight(
                icon: "clock.fill",
                text: "\(peakTime.key) is your peak temptation time. Plan ahead!",
                type: .neutral
            ))
        }
        
        // App-specific insights
        let appGroups = Dictionary(grouping: events) { $0.appName ?? "Unknown" }
        if let topApp = appGroups.max(by: { $0.value.count < $1.value.count }),
           topApp.value.count > events.count / 2 {
            results.append(Insight(
                icon: "app.badge",
                text: "\(topApp.key) accounts for most blocks. Consider removing it entirely.",
                type: .neutral
            ))
        }
        
        // Recent activity insight
        let recentEvents = events.filter { event in
            let daysSince = Calendar.current.dateComponents([.day], from: event.createdAt, to: Date()).day ?? 0
            return daysSince == 0
        }
        
        if recentEvents.count > 5 {
            results.append(Insight(
                icon: "chart.line.uptrend.xyaxis",
                text: "\(recentEvents.count) blocks today. High usage day - be mindful.",
                type: .warning
            ))
        }
        
        // If no specific insights, show encouragement
        if results.isEmpty {
            results.append(Insight(
                icon: "sparkles",
                text: "Keep logging data to unlock personalized insights!",
                type: .neutral
            ))
        }
        
        return results
    }
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ForEach(Array(insights.enumerated()), id: \.offset) { index, insight in
                HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                    Image(systemName: insight.icon)
                        .font(.system(size: 18))
                        .foregroundColor(insight.type.color)
                        .imageScale(.medium)
                        .frame(width: 24)
                    
                    Text(insight.text)
                        .font(AppTheme.Typography.body())
                        .foregroundColor(AppTheme.Colors.textPrimary(for: colorScheme))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 2)
                
                if index < insights.count - 1 {
                    ThemeDivider()
                }
            }
        }
    }
}

// MARK: - Response Patterns View

struct ResponsePatternsView: View {
    let events: [PauseEvent]
    @Environment(\.colorScheme) private var colorScheme
    
    struct AnswerData: Identifiable {
        let id = UUID()
        let answer: String
        let count: Int
    }
    
    private var topAnswers: [AnswerData] {
        let grouped = Dictionary(grouping: events) { event in
            event.selectedAnswer
        }
        
        return grouped.map { answer, events in
            AnswerData(answer: answer, count: events.count)
        }
        .sorted { $0.count > $1.count }
        .prefix(5)
        .map { $0 }
    }
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ForEach(topAnswers) { data in
                HStack {
                    Text(data.answer)
                        .font(AppTheme.Typography.body())
                        .foregroundColor(AppTheme.Colors.textPrimary(for: colorScheme))
                    
                    Spacer()
                    
                    Text("\(data.count)×")
                        .font(AppTheme.Typography.headline(weight: .medium))
                        .foregroundColor(AppTheme.Colors.textSecondary(for: colorScheme))
                }
                .padding(.vertical, 4)
            }
        }
    }
}

#Preview {
    AnalyticsDashboardView()
        .modelContainer(for: PauseEvent.self, inMemory: true)
}
