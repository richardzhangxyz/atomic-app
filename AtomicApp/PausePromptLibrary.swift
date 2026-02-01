//
//  PausePromptLibrary.swift
//  AtomicApp
//
//  Hard-coded prompt library for pause modal
//

import Foundation

enum PromptCategory: String, Codable {
    case motivation, emotion, avoidance, intention, nervousSystem, outcome
}

struct PausePrompt: Identifiable, Codable, Equatable {
    let id: String
    let category: PromptCategory
    let question: String
    let options: [String]
}

struct PausePromptLibrary {
    static let prompts: [PausePrompt] = [
        PausePrompt(
            id: "change",
            category: .motivation,
            question: "What are you actually trying to change right now?",
            options: ["My mood", "My energy", "My focus", "Nothing — just passing time"]
        ),
        PausePrompt(
            id: "preFeeling",
            category: .emotion,
            question: "What feeling came just before you opened this?",
            options: ["Restlessness", "Stress", "Boredom", "Curiosity"]
        ),
        PausePrompt(
            id: "avoidance",
            category: .avoidance,
            question: "What are you avoiding, if anything?",
            options: ["A task", "A thought", "A feeling", "Nothing"]
        ),
        PausePrompt(
            id: "intentionality",
            category: .intention,
            question: "How intentional was this action?",
            options: ["Fully intentional", "Half-automatic", "Mostly automatic", "Completely automatic"]
        ),
        PausePrompt(
            id: "state",
            category: .nervousSystem,
            question: "What state are you in right now?",
            options: ["Calm", "Wired", "Tired", "Scattered"]
        ),
        PausePrompt(
            id: "afterEffect",
            category: .outcome,
            question: "What usually happens when you open this?",
            options: ["I lose track of time", "I feel worse after", "I feel about the same", "It helps"]
        )
    ]
    
    static func randomPrompt() -> PausePrompt {
        prompts.randomElement()!
    }
}
