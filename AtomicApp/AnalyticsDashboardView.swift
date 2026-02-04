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
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
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
    
    // MARK: - Adaptive Color System
    
    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.1, green: 0.1, blue: 0.1)
            : Color(red: 1.0, green: 0.85, blue: 0.0)
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark
            ? Color(red: 1.0, green: 0.929, blue: 0.161)
            : Color.black
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark
            ? Color(red: 0.9, green: 0.836, blue: 0.145)
            : Color(red: 0.15, green: 0.15, blue: 0.15)
    }
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 1.0, green: 0.929, blue: 0.161).opacity(0.15)
            : Color.white.opacity(0.35)
    }
    
    private var accentColor: Color {
        colorScheme == .dark
            ? Color(red: 1.0, green: 0.929, blue: 0.161)
            : Color.black
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
            backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        HStack {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(secondaryTextColor)
                            }
                            
                            Spacer()
                            
                            VStack(spacing: 4) {
                                HStack(spacing: 6) {
                                    Text("📊 ANALYTICS")
                                        .font(.system(size: 28, weight: .black, design: .rounded))
                                        .foregroundColor(primaryTextColor)
                                    
                                    // Live indicator
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(.green)
                                            .frame(width: 6, height: 6)
                                        Text("LIVE")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.green)
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.green.opacity(0.15))
                                    .cornerRadius(6)
                                }
                                
                                Text("Updates automatically with new data")
                                    .font(.caption)
                                    .foregroundColor(secondaryTextColor)
                            }
                            
                            Spacer()
                            
                            // Placeholder for symmetry
                            Color.clear
                                .frame(width: 44, height: 44)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                    
                    // Time Range Selector
                    HStack(spacing: 12) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTimeRange = range
                                }
                            } label: {
                                Text(range.rawValue)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(selectedTimeRange == range ? (colorScheme == .dark ? .black : .white) : primaryTextColor)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        selectedTimeRange == range
                                            ? (colorScheme == .dark ? accentColor : Color.black)
                                            : cardBackgroundColor
                                    )
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Key Metrics Cards
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            MetricCard(
                                icon: "shield.checkered",
                                value: "\(totalEvents)",
                                label: "Total Blocks",
                                color: accentColor,
                                primaryTextColor: primaryTextColor,
                                secondaryTextColor: secondaryTextColor,
                                cardBackgroundColor: cardBackgroundColor
                            )
                            
                            MetricCard(
                                icon: "flame.fill",
                                value: "\(currentStreak)",
                                label: "Day Streak",
                                color: .orange,
                                primaryTextColor: primaryTextColor,
                                secondaryTextColor: secondaryTextColor,
                                cardBackgroundColor: cardBackgroundColor
                            )
                        }
                        
                        HStack(spacing: 16) {
                            MetricCard(
                                icon: "checkmark.shield.fill",
                                value: "\(Int((1 - proceedRate) * 100))%",
                                label: "Stayed Blocked",
                                color: .green,
                                primaryTextColor: primaryTextColor,
                                secondaryTextColor: secondaryTextColor,
                                cardBackgroundColor: cardBackgroundColor
                            )
                            
                            MetricCard(
                                icon: "lock.open.fill",
                                value: "\(Int(proceedRate * 100))%",
                                label: "Unlocked",
                                color: Color(red: 0.757, green: 0.071, blue: 0.122),
                                primaryTextColor: primaryTextColor,
                                secondaryTextColor: secondaryTextColor,
                                cardBackgroundColor: cardBackgroundColor
                            )
                        }
                    }
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .scale))
                    .id(selectedTimeRange) // Force view refresh on time range change
                    
                    // Proceed Rate Trend Chart
                    if !filteredEvents.isEmpty {
                        ChartCard(
                            title: "Proceed Rate Trend",
                            subtitle: "Daily unlock percentage",
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                            cardBackgroundColor: cardBackgroundColor
                        ) {
                            ProceedRateTrendChart(
                                events: filteredEvents,
                                accentColor: accentColor,
                                secondaryTextColor: secondaryTextColor
                            )
                        }
                        
                        // Time of Day Heatmap
                        ChartCard(
                            title: "Time of Day Pattern",
                            subtitle: "When you're most tempted",
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                            cardBackgroundColor: cardBackgroundColor
                        ) {
                            TimeOfDayHeatmap(
                                events: filteredEvents,
                                accentColor: accentColor,
                                secondaryTextColor: secondaryTextColor
                            )
                        }
                        
                        // Top Blocked Apps
                        ChartCard(
                            title: "Top Blocked Apps",
                            subtitle: "Most frequent blocks",
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                            cardBackgroundColor: cardBackgroundColor
                        ) {
                            TopAppsChart(
                                events: filteredEvents,
                                accentColor: accentColor,
                                primaryTextColor: primaryTextColor,
                                secondaryTextColor: secondaryTextColor
                            )
                        }
                        
                        // Response Patterns
                        ChartCard(
                            title: "Your Response Patterns",
                            subtitle: "Most common answers",
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                            cardBackgroundColor: cardBackgroundColor
                        ) {
                            ResponsePatternsView(
                                events: filteredEvents,
                                primaryTextColor: primaryTextColor,
                                secondaryTextColor: secondaryTextColor
                            )
                        }
                    } else {
                        // Empty State
                        VStack(spacing: 16) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 60))
                                .foregroundColor(secondaryTextColor.opacity(0.5))
                            
                            Text("No Data Yet")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(primaryTextColor)
                            
                            Text("Analytics will appear after your first block")
                                .font(.subheadline)
                                .foregroundColor(secondaryTextColor)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                        .background(cardBackgroundColor)
                        .cornerRadius(16)
                        .padding(.horizontal                        )
                        
                        // Insights Section
                        ChartCard(
                            title: "💡 Insights & Tips",
                            subtitle: "Based on your patterns",
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                            cardBackgroundColor: cardBackgroundColor
                        ) {
                            InsightsView(
                                events: filteredEvents,
                                streak: currentStreak,
                                proceedRate: proceedRate,
                                primaryTextColor: primaryTextColor,
                                secondaryTextColor: secondaryTextColor,
                                accentColor: accentColor
                            )
                        }
                    }
                    
                    // Data Info Footer
                    if !filteredEvents.isEmpty {
                        VStack(spacing: 8) {
                            HStack(spacing: 12) {
                                Image(systemName: "chart.bar.doc.horizontal")
                                    .font(.caption)
                                    .foregroundColor(secondaryTextColor.opacity(0.7))
                                
                                Text("\(filteredEvents.count) events in \(selectedTimeRange.label.lowercased())")
                                    .font(.caption)
                                    .foregroundColor(secondaryTextColor.opacity(0.7))
                                
                                Spacer()
                                
                                Text("Last updated: now")
                                    .font(.caption)
                                    .foregroundColor(secondaryTextColor.opacity(0.7))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(cardBackgroundColor.opacity(0.5))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
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
    let primaryTextColor: Color
    let secondaryTextColor: Color
    let cardBackgroundColor: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
                .symbolEffect(.bounce, value: value)
            
            Text(value)
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundColor(primaryTextColor)
                .contentTransition(.numericText())
            
            Text(label)
                .font(.caption)
                .foregroundColor(secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(cardBackgroundColor)
        .cornerRadius(16)
        .animation(.easeInOut(duration: 0.3), value: value)
    }
}

// MARK: - Chart Card Component

struct ChartCard<Content: View>: View {
    let title: String
    let subtitle: String
    let primaryTextColor: Color
    let secondaryTextColor: Color
    let cardBackgroundColor: Color
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(primaryTextColor)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
            }
            
            content()
        }
        .padding(20)
        .background(cardBackgroundColor)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Proceed Rate Trend Chart

struct ProceedRateTrendChart: View {
    let events: [PauseEvent]
    let accentColor: Color
    let secondaryTextColor: Color
    
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
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Date", data.date, unit: .day),
                        y: .value("Stayed Blocked %", data.stayedBlockedRate * 100)
                    )
                    .foregroundStyle(.green.opacity(0.2))
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Date", data.date, unit: .day),
                        y: .value("Stayed Blocked %", data.stayedBlockedRate * 100)
                    )
                    .foregroundStyle(.green)
                }
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let intValue = value.as(Double.self) {
                            Text("\(Int(intValue))%")
                                .font(.caption2)
                                .foregroundStyle(secondaryTextColor)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(secondaryTextColor.opacity(0.2))
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel(format: .dateTime.month().day(), centered: true)
                        .font(.caption2)
                        .foregroundStyle(secondaryTextColor)
                }
            }
            .frame(height: 180)
        }
    }
}

// MARK: - Time of Day Heatmap

struct TimeOfDayHeatmap: View {
    let events: [PauseEvent]
    let accentColor: Color
    let secondaryTextColor: Color
    
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
                        ? accentColor.gradient
                        : Color.gray.opacity(0.3).gradient
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
                            .foregroundStyle(secondaryTextColor)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(secondaryTextColor.opacity(0.2))
            }
        }
        .chartXAxis {
            AxisMarks(values: [0, 6, 12, 18, 23]) { value in
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue):00")
                            .font(.caption2)
                            .foregroundStyle(secondaryTextColor)
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
    let accentColor: Color
    let primaryTextColor: Color
    let secondaryTextColor: Color
    
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
                .font(.subheadline)
                .foregroundColor(secondaryTextColor)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
        } else {
            VStack(spacing: 12) {
                ForEach(Array(topApps.enumerated()), id: \.element.id) { index, app in
                    HStack(spacing: 12) {
                        Text("#\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(secondaryTextColor)
                            .frame(width: 30, alignment: .leading)
                        
                        Text(app.name)
                            .font(.subheadline)
                            .foregroundColor(primaryTextColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("\(app.count)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(accentColor)
                    }
                    
                    if index < topApps.count - 1 {
                        Divider()
                            .background(secondaryTextColor.opacity(0.2))
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
    let primaryTextColor: Color
    let secondaryTextColor: Color
    let accentColor: Color
    
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
        VStack(spacing: 14) {
            ForEach(Array(insights.enumerated()), id: \.offset) { index, insight in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: insight.icon)
                        .font(.system(size: 18))
                        .foregroundColor(insight.type.color)
                        .frame(width: 24)
                    
                    Text(insight.text)
                        .font(.subheadline)
                        .foregroundColor(primaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 2)
                
                if index < insights.count - 1 {
                    Divider()
                        .background(secondaryTextColor.opacity(0.2))
                }
            }
        }
    }
}

// MARK: - Response Patterns View

struct ResponsePatternsView: View {
    let events: [PauseEvent]
    let primaryTextColor: Color
    let secondaryTextColor: Color
    
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
        VStack(spacing: 12) {
            ForEach(topAnswers) { data in
                HStack {
                    Text(data.answer)
                        .font(.subheadline)
                        .foregroundColor(primaryTextColor)
                    
                    Spacer()
                    
                    Text("\(data.count)×")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(secondaryTextColor)
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
