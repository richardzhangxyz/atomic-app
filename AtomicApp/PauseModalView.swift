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
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(appName: String? = nil, attemptCount: Int? = nil, onProceed: @escaping () -> Void, onClose: @escaping () -> Void) {
        self.appName = appName
        self.attemptCount = attemptCount
        self.onProceed = onProceed
        self.onClose = onClose
    }
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.Colors.background(for: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Main content
                VStack(spacing: AppTheme.Spacing.xxxl) {
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
                .padding(AppTheme.Spacing.xxxl)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Spacer()
            }
            .opacity(showView ? 1 : 0)
        }
        .onAppear {
            if selectedPrompt == nil {
                selectedPrompt = PausePromptLibrary.randomPrompt()
            }
            
            withAnimation(AppTheme.Animation.slow) {
                showView = true
            }
        }
    }
    
    // MARK: - Context Header
    
    private var contextHeader: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Text("Quick pause")
                .font(AppTheme.Typography.title(weight: .semibold))
                .foregroundColor(AppTheme.Colors.textPrimary(for: colorScheme))
            
            if let appName = appName, let count = attemptCount, count > 1 {
                Text("You've opened \(appName) \(count) times recently")
                    .font(AppTheme.Typography.body())
                    .foregroundColor(AppTheme.Colors.textSecondary(for: colorScheme))
            }
            
            // Emoji mood indicators - only show in prompt stage
            if stage == .prompt {
                VStack(spacing: AppTheme.Spacing.md) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(EmojiMood.allCases, id: \.self) { mood in
                            emojiButton(mood)
                        }
                    }
                    
                    if let selected = selectedEmoji {
                        Text(selected.description)
                            .font(AppTheme.Typography.body())
                            .foregroundColor(AppTheme.Colors.textSecondary(for: colorScheme))
                            .transition(.opacity)
                    }
                }
                .padding(.top, AppTheme.Spacing.sm)
            }
        }
    }
    
    private func emojiButton(_ mood: EmojiMood) -> some View {
        Button {
            withAnimation(AppTheme.Animation.quick) {
                selectedEmoji = mood
            }
        } label: {
            VStack(spacing: 4) {
                Text(mood.rawValue)
                    .font(.title)
                    .scaleEffect(selectedEmoji == mood ? 1.15 : 1.0)
            }
            .padding(AppTheme.Spacing.sm)
            .background(
                Circle()
                    .fill(selectedEmoji == mood ? AppTheme.Colors.accent.opacity(0.15) : Color.clear)
            )
        }
        .animation(AppTheme.Animation.spring, value: selectedEmoji)
    }
    
    // MARK: - Prompt Section
    
    private var promptSection: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            if let prompt = selectedPrompt {
                Text(prompt.question)
                    .font(AppTheme.Typography.headline(weight: .medium))
                    .foregroundColor(AppTheme.Colors.textPrimary(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                VStack(spacing: AppTheme.Spacing.md) {
                    ForEach(prompt.options, id: \.self) { option in
                        Button {
                            selectedAnswer = option
                            withAnimation(AppTheme.Animation.standard) {
                                stage = .microReflection
                            }
                        } label: {
                            Text(option)
                                .font(AppTheme.Typography.body())
                                .foregroundColor(AppTheme.Colors.textPrimary(for: colorScheme))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppTheme.Spacing.lg)
                                .themeCard(colorScheme: colorScheme)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Micro Reflection
    
    private var microReflectionSection: some View {
        VStack(spacing: AppTheme.Spacing.xxl) {
            VStack(spacing: AppTheme.Spacing.sm) {
                Text("Do you still want to open this?")
                    .font(AppTheme.Typography.headline(weight: .medium))
                    .foregroundColor(AppTheme.Colors.textPrimary(for: colorScheme))
                
                Text("Intentional or automatic?")
                    .font(AppTheme.Typography.body())
                    .foregroundColor(AppTheme.Colors.textSecondary(for: colorScheme))
            }
            .multilineTextAlignment(.center)
            
            // Freeform text field
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("What's on your mind right now?")
                    .font(AppTheme.Typography.body())
                    .foregroundColor(AppTheme.Colors.textPrimary(for: colorScheme))
                
                ZStack(alignment: .topLeading) {
                    if freeformText.isEmpty {
                        Text("Type your thoughts here...")
                            .foregroundColor(AppTheme.Colors.textMuted(for: colorScheme))
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.md)
                    }
                    
                    TextEditor(text: $freeformText)
                        .frame(minHeight: 100)
                        .scrollContentBackground(.hidden)
                        .foregroundColor(AppTheme.Colors.textPrimary(for: colorScheme))
                        .padding(AppTheme.Spacing.sm)
                        .background(AppTheme.Colors.surface(for: colorScheme))
                        .cornerRadius(AppTheme.CornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                                .stroke(AppTheme.Colors.border(for: colorScheme), lineWidth: 1)
                        )
                }
            }
            
            VStack(spacing: AppTheme.Spacing.md) {
                Button {
                    withAnimation(AppTheme.Animation.standard) {
                        unlockStartTime = Date()
                        stage = .unlock
                    }
                } label: {
                    Text("Proceed intentionally")
                        .font(AppTheme.Typography.body(weight: .medium))
                        .themePrimaryButton(isEnabled: !freeformText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, colorScheme: colorScheme)
                }
                .disabled(freeformText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                
                Button {
                    saveEvent(didProceed: false, unlockMethod: "none")
                    onClose()
                } label: {
                    Text("Close app")
                        .font(AppTheme.Typography.body())
                        .themeSecondaryButton(colorScheme: colorScheme)
                }
            }
        }
    }
    
    // MARK: - Unlock Section
    
    private var unlockSection: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            if let savedPhrase = savedSignaturePhrase, !savedPhrase.isEmpty {
                phraseUnlock
            } else {
                holdToConfirmUnlock
            }
        }
    }
    
    private var phraseUnlock: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Text("Type your phrase to proceed")
                .font(AppTheme.Typography.body())
                .foregroundColor(AppTheme.Colors.textSecondary(for: colorScheme))
            
            TextField("Your signature phrase", text: $signaturePhrase)
                .font(AppTheme.Typography.body())
                .foregroundColor(AppTheme.Colors.textPrimary(for: colorScheme))
                .padding(AppTheme.Spacing.lg)
                .background(AppTheme.Colors.surface(for: colorScheme))
                .cornerRadius(AppTheme.CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                        .stroke(AppTheme.Colors.border(for: colorScheme), lineWidth: 1)
                )
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
                    .font(AppTheme.Typography.body(weight: .medium))
                    .themePrimaryButton(isEnabled: !signaturePhrase.isEmpty, colorScheme: colorScheme)
            }
            .disabled(signaturePhrase.isEmpty)
        }
    }
    
    private var holdToConfirmUnlock: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Text("Hold to proceed")
                .font(AppTheme.Typography.body())
                .foregroundColor(AppTheme.Colors.textSecondary(for: colorScheme))
            
            ZStack {
                Circle()
                    .stroke(AppTheme.Colors.surface(for: colorScheme), lineWidth: 6)
                
                Circle()
                    .trim(from: 0, to: holdProgress)
                    .stroke(
                        AppTheme.Colors.accent,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(AppTheme.Animation.spring, value: holdProgress)
                
                Text("I'm choosing this\non purpose")
                    .font(AppTheme.Typography.body(weight: .medium))
                    .foregroundColor(AppTheme.Colors.textPrimary(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .scaleEffect(isHolding ? 1.05 : 1.0)
                    .animation(AppTheme.Animation.spring, value: isHolding)
            }
            .frame(width: 200, height: 200)
            .contentShape(Circle())
            .scaleEffect(isHolding ? 1.05 : 1.0)
            .animation(AppTheme.Animation.spring, value: isHolding)
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
