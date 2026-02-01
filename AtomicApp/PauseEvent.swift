//
//  PauseEvent.swift
//  AtomicApp
//
//  SwiftData model for pause event logging
//

import Foundation
import SwiftData

@Model
final class PauseEvent: Identifiable {
    var id: UUID
    var createdAt: Date
    var appIdentifier: String?
    var appName: String?
    var attemptCount: Int?
    
    var promptId: String?
    var promptCategory: String?
    var promptType: String?
    var promptQuestion: String
    var selectedAnswer: String
    var freeformReflection: String?
    
    var didProceed: Bool
    var unlockMethod: String // "hold" | "phrase" | "none"
    var unlockDurationMs: Int?
    
    var stageExitedAt: Date?
    var sessionDurationMs: Int?
    
    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        appIdentifier: String? = nil,
        appName: String? = nil,
        attemptCount: Int? = nil,
        promptId: String? = nil,
        promptCategory: String? = nil,
        promptType: String? = nil,
        promptQuestion: String,
        selectedAnswer: String,
        freeformReflection: String? = nil,
        didProceed: Bool = false,
        unlockMethod: String = "none",
        unlockDurationMs: Int? = nil,
        stageExitedAt: Date? = nil,
        sessionDurationMs: Int? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.appIdentifier = appIdentifier
        self.appName = appName
        self.attemptCount = attemptCount
        self.promptId = promptId
        self.promptCategory = promptCategory
        self.promptType = promptType
        self.promptQuestion = promptQuestion
        self.selectedAnswer = selectedAnswer
        self.freeformReflection = freeformReflection
        self.didProceed = didProceed
        self.unlockMethod = unlockMethod
        self.unlockDurationMs = unlockDurationMs
        self.stageExitedAt = stageExitedAt
        self.sessionDurationMs = sessionDurationMs
    }
}
