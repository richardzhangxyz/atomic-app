//
//  PauseAnalytics.swift
//  AtomicApp
//
//  Analytics and aggregation for pause events
//

import Foundation

struct PauseAnalyticsAggregates {
    let totalEvents: Int
    let proceedRate: Double
    let topAnswers: [(promptType: String, answer: String, count: Int)]
    let topApps: [(appName: String, count: Int)]
    let timeOfDayDistribution: [String: Int]
}

@MainActor
class PauseAnalytics {
    private let store: PauseEventStore
    
    init(store: PauseEventStore) {
        self.store = store
    }
    
    func basicAggregates(days: Int = 7) -> PauseAnalyticsAggregates {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let events = store.fetchEvents(since: cutoffDate)
        
        let totalEvents = events.count
        let proceedCount = events.filter { $0.didProceed }.count
        let proceedRate = totalEvents > 0 ? Double(proceedCount) / Double(totalEvents) : 0.0
        
        // Top answers by prompt category
        var answerCounts: [String: [String: Int]] = [:]
        for event in events {
            let category = event.promptCategory ?? "unknown"
            var promptAnswers = answerCounts[category] ?? [:]
            promptAnswers[event.selectedAnswer, default: 0] += 1
            answerCounts[category] = promptAnswers
        }
        
        let topAnswers = answerCounts.flatMap { promptCategory, answers in
            answers.map { (promptType: promptCategory, answer: $0.key, count: $0.value) }
        }
        .sorted { $0.count > $1.count }
        .prefix(5)
        .map { $0 }
        
        // Top blocked apps
        var appCounts: [String: Int] = [:]
        for event in events {
            if let appName = event.appName {
                appCounts[appName, default: 0] += 1
            }
        }
        
        let topApps = appCounts.map { (appName: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(5)
            .map { $0 }
        
        // Time of day distribution
        let timeOfDayDistribution = Dictionary(grouping: events) { event -> String in
            let hour = Calendar.current.component(.hour, from: event.createdAt)
            switch hour {
            case 6..<12: return "Morning"
            case 12..<17: return "Afternoon"
            case 17..<22: return "Evening"
            default: return "Night"
            }
        }.mapValues { $0.count }
        
        return PauseAnalyticsAggregates(
            totalEvents: totalEvents,
            proceedRate: proceedRate,
            topAnswers: topAnswers,
            topApps: topApps,
            timeOfDayDistribution: timeOfDayDistribution
        )
    }
    
    func proceedRate(days: Int) -> Double {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let events = store.fetchEvents(since: cutoffDate)
        
        guard !events.isEmpty else { return 0.0 }
        
        let proceedCount = events.filter { $0.didProceed }.count
        return Double(proceedCount) / Double(events.count)
    }
}
