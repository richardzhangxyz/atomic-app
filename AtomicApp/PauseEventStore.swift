//
//  PauseEventStore.swift
//  AtomicApp
//
//  Persistence layer for pause events
//

import Foundation
import SwiftData

@MainActor
class PauseEventStore {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func save(_ event: PauseEvent) {
        modelContext.insert(event)
        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to save PauseEvent: \(error)")
        }
    }
    
    func fetchEvents(since date: Date) -> [PauseEvent] {
        let descriptor = FetchDescriptor<PauseEvent>(
            predicate: #Predicate { event in
                event.createdAt >= date
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("❌ Failed to fetch events: \(error)")
            return []
        }
    }
    
    func fetchAllEvents() -> [PauseEvent] {
        let descriptor = FetchDescriptor<PauseEvent>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("❌ Failed to fetch all events: \(error)")
            return []
        }
    }
}
