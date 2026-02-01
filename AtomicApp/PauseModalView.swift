//
//  PauseModalView.swift
//  AtomicApp
//
//  Blocking pause modal with calm reflection flow
//

import SwiftUI
import SwiftData

struct PauseModalView: View {
    // Context inputs
    let appName: String?
    let attemptCount: Int?
    let onProceed: () -> Void
    let onClose: () -> Void
    
    // Environment
    @Environment(\.modelContext) private var modelContext
    
    // State machine
    enum Stage {
        case prompt
        case microReflection
        case unlock
    }
    
    @State private var stage: Stage = .prompt
    @State private var selectedPrompt: PausePrompt? = nil
    @State private var selectedAnswer: String?
    @State private var selectedEmoji: EmojiMood?
    @State private var freeformText: String = ""
    @State private var signaturePhrase: String = ""
    @State private var holdProgress: Double = 0.0
    @State private var isHolding: Bool = false
    @State private var unlockStartTime: Date?
    @State private var sessionStartTime = Date()
    @State private var showView = false
    
    enum EmojiMood: String, CaseIterable {
        case calm = "😌"
        case concerned = "🤔"
        case neutral = "😶"
        case stressed = "😓"
        case sad = "😔"
        case frustrated = "😤"
        
        var description: String {
            switch self {
            case .calm: return "Calm"
            case .concerned: return "Thoughtful"
            case .neutral: return "Neutral"
            case .stressed: return "Stressed"
            case .sad: return "Down"
            case .frustrated: return "Agitated"
            }
        }
    }
    
    // Constants
    private let holdDuration: Double = 2.5
    private let savedSignaturePhrase: String? = UserDefaults.standard.string(forKey: "userSignaturePhrase")
    
    init(appName: String? = nil, attemptCount: Int? = nil, onProceed: @escaping () -> Void, onClose: @escaping () -> Void) {
        self.appName = appName
        self.attemptCount = attemptCount
        self.onProceed = onProceed
        self.onClose = onClose
    }
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Calming gradient background - adapts to dark mode
            LinearGradient(
                colors: colorScheme == .dark ? [
                    Color(red: 0.15, green: 0.14, blue: 0.20),  // Dark lavender
                    Color(red: 0.12, green: 0.15, blue: 0.20),  // Dark blue
                    Color(red: 0.16, green: 0.14, blue: 0.13)   // Dark warm
                ] : [
                    Color(red: 0.95, green: 0.94, blue: 0.98),  // Soft lavender
                    Color(red: 0.93, green: 0.95, blue: 0.98),  // Soft blue
                    Color(red: 0.96, green: 0.94, blue: 0.92)   // Warm beige
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Main content - fullscreen
                VStack(spacing: 32) {
                    contextHeader
                    
                    switch stage {
                    case .prompt:
                        promptSection
                    case .microReflection:
                        microReflectionSection
                    case .unlock:
                        unlockSection
                    }
                    
                    Spacer()
                }
                .padding(32)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Spacer()
            }
            .opacity(showView ? 1 : 0)
        }
        .onAppear {
            // Select prompt once per presentation
            if selectedPrompt == nil {
                selectedPrompt = PausePromptLibrary.randomPrompt()
            }
            
            withAnimation(.easeOut(duration: 0.4)) {
                showView = true
            }
        }
    }
    
    // MARK: - Context Header
    
    private var contextHeader: some View {
        VStack(spacing: 16) {
            Text("Quick pause.")
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: colorScheme == .dark ? [
                            Color(red: 0.7, green: 0.6, blue: 0.9),
                            Color(red: 0.6, green: 0.75, blue: 0.95)
                        ] : [
                            Color(red: 0.4, green: 0.3, blue: 0.6),
                            Color(red: 0.3, green: 0.5, blue: 0.7)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            if let appName = appName, let count = attemptCount, count > 1 {
                Text("You've opened \(appName) \(count) times recently.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            // Emoji mood indicators - only show in prompt stage
            if stage == .prompt {
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        ForEach(EmojiMood.allCases, id: \.self) { mood in
                            emojiButton(mood)
                        }
                    }
                    
                    if let selected = selectedEmoji {
                        Text(selected.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .transition(.opacity)
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    private func emojiButton(_ mood: EmojiMood) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedEmoji = mood
            }
        } label: {
            VStack(spacing: 4) {
                Text(mood.rawValue)
                    .font(.title)
                    .scaleEffect(selectedEmoji == mood ? 1.15 : 1.0)
                    .shadow(
                        color: selectedEmoji == mood ? Color(red: 0.5, green: 0.4, blue: 0.7).opacity(0.6) : .clear,
                        radius: 12
                    )
            }
            .padding(8)
            .background(
                Circle()
                    .fill(selectedEmoji == mood ? (colorScheme == .dark ? Color(red: 0.6, green: 0.5, blue: 0.8).opacity(0.3) : Color(red: 0.6, green: 0.5, blue: 0.8).opacity(0.15)) : Color.clear)
            )
        }
        .animation(.spring(response: 0.3), value: selectedEmoji)
    }
    
    // MARK: - Prompt Section
    
    private var promptSection: some View {
        VStack(spacing: 20) {
            if let prompt = selectedPrompt {
                Text(prompt.question)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                VStack(spacing: 12) {
                    ForEach(prompt.options, id: \.self) { option in
                        Button {
                            selectedAnswer = option
                            withAnimation(.easeInOut(duration: 0.3)) {
                                stage = .microReflection
                            }
                        } label: {
                            Text(option)
                                .font(.body)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? Color(white: 0.2).opacity(0.7) : Color.white.opacity(0.7))
                                        .shadow(color: Color(red: 0.5, green: 0.4, blue: 0.7).opacity(0.1), radius: 4, y: 2)
                                )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Micro Reflection
    
    private var microReflectionSection: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Do you still want to open this?")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Intentional or automatic?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
            
            // Freeform text field - cleaner design
            VStack(alignment: .leading, spacing: 10) {
                Text("What's on your mind right now?")
                    .font(.body)
                    .foregroundColor(.primary)
                
                ZStack(alignment: .topLeading) {
                    if freeformText.isEmpty {
                        Text("Type your thoughts here...")
                            .foregroundColor(.secondary.opacity(0.5))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                    }
                    
                    TextEditor(text: $freeformText)
                        .frame(minHeight: 100)
                        .scrollContentBackground(.hidden)
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(colorScheme == .dark ? Color(white: 0.2).opacity(0.7) : Color.white.opacity(0.7))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(red: 0.5, green: 0.4, blue: 0.7).opacity(0.2), lineWidth: 1)
                        )
                }
            }
            
            VStack(spacing: 12) {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        unlockStartTime = Date()
                        stage = .unlock
                    }
                } label: {
                    Text("Proceed intentionally")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Group {
                                if freeformText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.5))
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.5, green: 0.4, blue: 0.7),
                                                    Color(red: 0.4, green: 0.5, blue: 0.75)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                }
                            }
                        )
                }
                .disabled(freeformText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                
                Button {
                    saveEvent(didProceed: false, unlockMethod: "none")
                    onClose()
                } label: {
                    Text("Close app")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color(white: 0.2).opacity(0.5) : Color.white.opacity(0.5))
                        )
                }
            }
        }
    }
    
    // MARK: - Unlock Section
    
    private var unlockSection: some View {
        VStack(spacing: 20) {
            if let savedPhrase = savedSignaturePhrase, !savedPhrase.isEmpty {
                phraseUnlock
            } else {
                holdToConfirmUnlock
            }
        }
    }
    
    private var phraseUnlock: some View {
        VStack(spacing: 16) {
            Text("Type your phrase to proceed.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextField("Your signature phrase", text: $signaturePhrase)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            Button {
                if signaturePhrase.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ==
                    savedSignaturePhrase?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
                    let duration = unlockStartTime.map { Int(Date().timeIntervalSince($0) * 1000) }
                    saveEvent(didProceed: true, unlockMethod: "phrase", unlockDuration: duration)
                    onProceed()
                }
            } label: {
                Text("Submit")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Group {
                            if signaturePhrase.isEmpty {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.5))
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.5, green: 0.4, blue: 0.7),
                                                Color(red: 0.4, green: 0.5, blue: 0.75)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                        }
                    )
            }
            .disabled(signaturePhrase.isEmpty)
        }
    }
    
    private var holdToConfirmUnlock: some View {
        VStack(spacing: 16) {
            Text("Hold to proceed")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: holdProgress)
                    .stroke(
                        LinearGradient(
                            colors: colorScheme == .dark ? [
                                Color(red: 0.7, green: 0.6, blue: 0.9),
                                Color(red: 0.6, green: 0.75, blue: 0.95)
                            ] : [
                                Color(red: 0.5, green: 0.4, blue: 0.7),
                                Color(red: 0.4, green: 0.5, blue: 0.75)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: holdProgress)
                
                Text("I'm choosing this\non purpose.")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .scaleEffect(isHolding ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHolding)
            }
            .frame(width: 200, height: 200)
            .contentShape(Circle())
            .scaleEffect(isHolding ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHolding)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isHolding {
                            isHolding = true
                            startHolding()
                        }
                    }
                    .onEnded { _ in
                        isHolding = false
                        holdProgress = 0
                    }
            )
        }
    }
    
    // MARK: - Hold Logic
    
    private func startHolding() {
        let startTime = Date()
        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            guard isHolding else {
                timer.invalidate()
                return
            }
            
            let elapsed = Date().timeIntervalSince(startTime)
            let rawProgress = elapsed / holdDuration
            
            // Add subtle organic variation to make it feel less mechanical
            let variation = sin(elapsed * 3.0) * 0.015
            holdProgress = min(rawProgress + variation, 1.0)
            
            if rawProgress >= 1.0 {
                timer.invalidate()
                // Add haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                let duration = unlockStartTime.map { Int(Date().timeIntervalSince($0) * 1000) }
                saveEvent(didProceed: true, unlockMethod: "hold", unlockDuration: duration)
                onProceed()
            }
        }
    }
    
    // MARK: - Event Logging
    
    private func saveEvent(didProceed: Bool, unlockMethod: String, unlockDuration: Int? = nil) {
        guard let answer = selectedAnswer, let prompt = selectedPrompt else { return }
        
        let freeformReflection = freeformText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : freeformText
        let emojiMood = selectedEmoji?.description
        
        // Combine emoji mood with freeform text if both exist
        let finalReflection: String?
        if let emoji = emojiMood, let text = freeformReflection {
            finalReflection = "Mood: \(emoji)\n\(text)"
        } else if let emoji = emojiMood {
            finalReflection = "Mood: \(emoji)"
        } else {
            finalReflection = freeformReflection
        }
        
        let event = PauseEvent(
            appIdentifier: nil, // TODO: get from ScreenTime context if available
            appName: appName,
            attemptCount: attemptCount,
            promptId: prompt.id,
            promptCategory: prompt.category.rawValue,
            promptType: "",
            promptQuestion: prompt.question,
            selectedAnswer: answer,
            freeformReflection: finalReflection,
            didProceed: didProceed,
            unlockMethod: unlockMethod,
            unlockDurationMs: unlockDuration,
            stageExitedAt: Date(),
            sessionDurationMs: Int(Date().timeIntervalSince(sessionStartTime) * 1000)
        )
        
        let store = PauseEventStore(modelContext: modelContext)
        store.save(event)
        
        print("✅ Saved PauseEvent: \(didProceed ? "proceeded" : "closed"), method: \(unlockMethod)")
    }
}

// MARK: - Preview

#Preview {
    PauseModalView(
        appName: "Instagram",
        attemptCount: 3,
        onProceed: { print("Proceeded") },
        onClose: { print("Closed") }
    )
    .modelContainer(for: PauseEvent.self, inMemory: true)
}
