//
//  BrutalBlockModalView.swift
//  AtomicApp
//
//  Construction zone warning modal - safety yellow, high contrast, unmissable
//

import SwiftUI
import SwiftData

struct BrutalBlockModalView: View {
    // Context inputs
    let appName: String?
    let minutesSpent: Int?
    let onUnlock: () -> Void
    let onStayBlocked: () -> Void
    
    // Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    // State
    @State private var confirmationText: String = ""
    @State private var showView = false
    @State private var sessionStartTime = Date()
    @State private var selectedQuote: String = ""
    
    // Required phrase to unlock (friction)
    private let requiredPhrase = "GET BACK TO WORK"
    
    // CONSTRUCTION ZONE COLOR SYSTEM (Dark Mode Compatible)
    // PRIMARY: HIGHLIGHTER YELLOW (bright, vivid)
    private let safetyYellow = Color(red: 1.0, green: 0.929, blue: 0.161) // #FFED29
    // DARK MODE: Darker golden yellow for reduced eye strain
    private let safetyYellowDark = Color(red: 0.702, green: 0.631, blue: 0.106) // #B3A11B
    
    // Background: bright yellow in light mode, darker golden in dark mode
    private var bgColor: Color {
        colorScheme == .dark ? safetyYellowDark : safetyYellow
    }
    
    // DANGER: Hazard Red (only for "bad" unlock action)
    private let hazardRed = Color(red: 0.757, green: 0.071, blue: 0.122) // #C1121F
    
    // Text colors (adaptive)
    private var textOnYellow: Color {
        // Always use dark text on bright yellow for readability
        Color(red: 0.043, green: 0.043, blue: 0.043) // #0B0B0B
    }
    
    private var textPrimary: Color {
        textOnYellow
    }
    
    private var textSecondary: Color {
        Color.black.opacity(colorScheme == .dark ? 0.75 : 0.65)
    }
    
    private var textDeemphasized: Color {
        Color.black.opacity(colorScheme == .dark ? 0.55 : 0.45)
    }
    
    private var dividerColor: Color {
        Color.black.opacity(colorScheme == .dark ? 0.75 : 0.6)
    }
    
    private var fieldBackground: Color {
        Color.black.opacity(colorScheme == .dark ? 0.85 : 0.8)
    }
    
    private var primaryButtonBackground: Color {
        Color.black
    }
    
    private var primaryButtonText: Color {
        safetyYellow
    }
    
    private var dangerButtonText: Color {
        Color.white
    }
    
    private var disabledButtonBackground: Color {
        Color.black.opacity(colorScheme == .dark ? 0.35 : 0.25)
    }
    
    // Rotating quotes
    private let quotes = [
        "NO ONE IS COMING TO SAVE YOU.",
        "YOU DON'T GET BETTER BY DOING WHAT'S EASY.",
        "EVERYONE WANTS TO BE SUCCESSFUL. FEW ARE WILLING TO DO WHAT IT TAKES."
    ]
    
    private var isUnlockEnabled: Bool {
        confirmationText.uppercased().trimmingCharacters(in: .whitespaces) == requiredPhrase
    }
    
    var body: some View {
        ZStack {
            // Near-black background
            bgColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    Spacer().frame(height: 40)
                    
                    // MARK: - Header
                    headerSection
                    
                    // MARK: - Main Statement
                    mainStatementSection
                    
                    // MARK: - Reality Check
                    realityCheckSection
                    
                    // MARK: - Quote
                    quoteSection
                    
                    Spacer().frame(height: 20)
                    
                    // MARK: - Confirmation Input
                    confirmationSection
                    
                    // MARK: - Actions
                    actionsSection
                    
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 24)
            }
            .opacity(showView ? 1 : 0)
        }
        .onAppear {
            // Select random quote
            selectedQuote = quotes.randomElement() ?? quotes[0]
            
            // Heavy haptic on appear
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
            
            withAnimation(.easeOut(duration: 0.3)) {
                showView = true
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("STOP SCROLLING.")
                .font(.system(size: 32, weight: .black, design: .default))
                .tracking(2)
                .foregroundColor(textPrimary)
            
            Text("YOU DIDN'T OPEN THIS APP BY ACCIDENT.")
                .font(.system(size: 14, weight: .semibold, design: .default))
                .tracking(1)
                .foregroundColor(textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Main Statement Section
    
    private var mainStatementSection: some View {
        VStack(spacing: 16) {
            Text("THIS IS YOU AVOIDING YOUR LIFE.")
                .font(.system(size: 24, weight: .heavy, design: .default))
                .tracking(1)
                .foregroundColor(textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            Text("PUT THE PHONE DOWN. GET BACK TO WORK.")
                .font(.system(size: 16, weight: .bold, design: .default))
                .tracking(0.5)
                .foregroundColor(textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Reality Check Section
    
    private var realityCheckSection: some View {
        VStack(spacing: 8) {
            Rectangle()
                .fill(dividerColor)
                .frame(height: 2)
            
            if let minutes = minutesSpent, minutes > 0 {
                Text("YOU'VE BEEN HERE FOR \(minutes) MINUTES.")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .tracking(0.5)
                    .foregroundColor(textPrimary)
                
                Text("THAT'S \(minutes) MINUTES YOU DON'T GET BACK.")
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundColor(textSecondary)
            } else {
                Text("YOU SAID YOU'D STOP DOING THIS.")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .tracking(0.5)
                    .foregroundColor(textPrimary)
                
                Text("THIS IS YOU BREAKING THAT PROMISE.")
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundColor(textSecondary)
            }
            
            Rectangle()
                .fill(dividerColor)
                .frame(height: 2)
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Quote Section
    
    private var quoteSection: some View {
        Text("\"\(selectedQuote)\"")
            .font(.system(size: 15, weight: .medium, design: .serif))
            .italic()
            .foregroundColor(textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    // MARK: - Confirmation Section
    
    private var confirmationSection: some View {
        VStack(spacing: 12) {
            Text("TYPE TO UNLOCK:")
                .font(.system(size: 11, weight: .bold, design: .default))
                .tracking(1.5)
                .foregroundColor(textDeemphasized)
            
            Text(requiredPhrase)
                .font(.system(size: 16, weight: .black, design: .monospaced))
                .tracking(2)
                .foregroundColor(textPrimary)
            
            TextField("", text: $confirmationText)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(textPrimary)
                .multilineTextAlignment(.center)
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)
                .padding(.vertical, 14)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(fieldBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isUnlockEnabled ? textPrimary : textDeemphasized, lineWidth: 2)
                        )
                )
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 16) {
            // STAY BLOCKED (Primary "good" action - SAFETY YELLOW)
            Button {
                // No haptic on stay blocked
                logUnlockEvent(didProceed: false)
                onStayBlocked()
            } label: {
                VStack(spacing: 6) {
                    Text("STAY BLOCKED — DO THE HARD THING")
                        .font(.system(size: 14, weight: .black, design: .default))
                        .tracking(0.5)
                        .foregroundColor(primaryButtonText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(primaryButtonBackground)
                )
            }
            
            Text("Good. Do the hard thing.")
                .font(.system(size: 11, weight: .medium, design: .default))
                .foregroundColor(textDeemphasized)
            
            // UNLOCK ANYWAY (Danger action - HAZARD RED)
            Button {
                // Sharp haptic on unlock
                let generator = UIImpactFeedbackGenerator(style: .rigid)
                generator.impactOccurred()
                
                // Log the event
                logUnlockEvent(didProceed: true)
                
                onUnlock()
            } label: {
                VStack(spacing: 6) {
                    Text("UNLOCK ANYWAY")
                        .font(.system(size: 14, weight: .black, design: .default))
                        .tracking(0.5)
                        .foregroundColor(isUnlockEnabled ? dangerButtonText : textDeemphasized)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isUnlockEnabled ? hazardRed : disabledButtonBackground)
                )
            }
            .disabled(!isUnlockEnabled)
            
            Text("This will be logged. You will see it later.")
                .font(.system(size: 11, weight: .medium, design: .default))
                .foregroundColor(textDeemphasized)
        }
    }
    
    // MARK: - Logging
    
    private func logUnlockEvent(didProceed: Bool) {
        let event = PauseEvent(
            appIdentifier: nil,
            appName: appName,
            attemptCount: nil,
            promptId: "brutal_block",
            promptCategory: "discipline",
            promptType: "brutal",
            promptQuestion: "STOP SCROLLING. THIS IS YOU AVOIDING YOUR LIFE.",
            selectedAnswer: didProceed ? "UNLOCKED" : "STAYED_BLOCKED",
            freeformReflection: didProceed ? "User typed confirmation: \(confirmationText)" : nil,
            didProceed: didProceed,
            unlockMethod: didProceed ? "brutal_confirmation" : "none",
            unlockDurationMs: nil,
            stageExitedAt: Date(),
            sessionDurationMs: Int(Date().timeIntervalSince(sessionStartTime) * 1000)
        )
        
        let store = PauseEventStore(modelContext: modelContext)
        store.save(event)
        
        print("🔴 BrutalBlock logged: \(didProceed ? "UNLOCKED" : "STAYED_BLOCKED")")
    }
}

// MARK: - Preview

#Preview {
    BrutalBlockModalView(
        appName: "Instagram",
        minutesSpent: 47,
        onUnlock: { print("Unlocked") },
        onStayBlocked: { print("Stayed blocked") }
    )
    .modelContainer(for: PauseEvent.self, inMemory: true)
}
