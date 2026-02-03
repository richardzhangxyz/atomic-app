//
//  BrutalBlockModalView.swift
//  AtomicApp
//
//  Intentional unlock modal - requires deliberate choice to bypass limits
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
    @State private var signatureLines: [[CGPoint]] = []
    @State private var currentLine: [CGPoint] = []
    @State private var showView = false
    @State private var sessionStartTime = Date()
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case confirmation
    }
    
    // Required phrase to unlock (intentional friction)
    private let requiredPhrase = "I am making an intentional choice"
    
    // COLOR SYSTEM (Dark Mode Compatible)
    // PRIMARY: Vivid gold
    private let safetyYellow = Color(red: 1.0, green: 0.85, blue: 0.0) // #FFD900
    // DARK MODE: Darker for reduced eye strain
    private let safetyYellowDark = Color(red: 0.1, green: 0.1, blue: 0.1) // Dark gray
    
    // Background: bright yellow in light mode, darker golden in dark mode
    private var bgColor: Color {
        colorScheme == .dark ? safetyYellowDark : safetyYellow
    }
    
    // DANGER: Hazard Red (only for "bad" unlock action)
    private let hazardRed = Color(red: 0.757, green: 0.071, blue: 0.122) // #C1121F
    
    // Text colors (adaptive)
    private var textPrimary: Color {
        colorScheme == .dark 
            ? Color(red: 1.0, green: 0.929, blue: 0.161) // Bright yellow
            : Color.black
    }
    
    private var textSecondary: Color {
        colorScheme == .dark
            ? Color(red: 0.9, green: 0.836, blue: 0.145)
            : Color(red: 0.15, green: 0.15, blue: 0.15)
    }
    
    private var textDeemphasized: Color {
        colorScheme == .dark
            ? textSecondary.opacity(0.6)
            : Color.black.opacity(0.5)
    }
    
    private var dividerColor: Color {
        textSecondary.opacity(0.3)
    }
    
    private var fieldBackground: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.1)
            : Color.white.opacity(0.4)
    }
    
    private var primaryButtonBackground: Color {
        colorScheme == .dark
            ? Color(red: 1.0, green: 0.929, blue: 0.161)
            : Color.black
    }
    
    private var primaryButtonText: Color {
        colorScheme == .dark
            ? Color.black
            : Color(red: 1.0, green: 0.85, blue: 0.0)
    }
    
    private var dangerButtonText: Color {
        Color.white
    }
    
    private var disabledButtonBackground: Color {
        textSecondary.opacity(0.2)
    }
    
    private var isUnlockEnabled: Bool {
        let phraseMatches = confirmationText.trimmingCharacters(in: .whitespaces).lowercased() == requiredPhrase.lowercased()
        let hasSignature = !signatureLines.isEmpty
        return phraseMatches && hasSignature
    }
    
    var body: some View {
        ZStack {
            // Background
            bgColor.ignoresSafeArea()
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 32) {
                        Spacer().frame(height: 40)
                        
                        // MARK: - Header
                        headerSection
                        
                        // MARK: - Main Statement
                        mainStatementSection
                        
                        // MARK: - Reality Check
                        realityCheckSection
                        
                        Spacer().frame(height: 20)
                        
                        // MARK: - Confirmation Input
                        confirmationSection
                            .id("confirmationSection")
                        
                        // MARK: - Actions
                        actionsSection
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 24)
                }
                .onChange(of: focusedField) { _, newValue in
                    if newValue != nil {
                        withAnimation {
                            proxy.scrollTo("confirmationSection", anchor: .center)
                        }
                    }
                }
            }
            .opacity(showView ? 1 : 0)
        }
        .onAppear {
            // Light haptic on appear
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            withAnimation(.easeOut(duration: 0.3)) {
                showView = true
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(Color(red: 0.757, green: 0.071, blue: 0.122))
            
            Text("TIME LIMIT REACHED")
                .font(.system(size: 28, weight: .bold, design: .default))
                .foregroundColor(textPrimary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Main Statement Section
    
    private var mainStatementSection: some View {
        VStack(spacing: 12) {
            if let minutes = minutesSpent, minutes > 0 {
                Text("You've spent \(minutes) minutes today")
                    .font(.system(size: 16, weight: .medium, design: .default))
                    .foregroundColor(textSecondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Your daily limit has been reached")
                    .font(.system(size: 16, weight: .medium, design: .default))
                    .foregroundColor(textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let appName = appName {
                Text("on \(appName)")
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(textDeemphasized)
            }
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - Reality Check Section
    
    private var realityCheckSection: some View {
        VStack(spacing: 16) {
            Rectangle()
                .fill(dividerColor)
                .frame(height: 1)
            
            Text("Take a moment to consider why you set this limit")
                .font(.system(size: 15, weight: .medium, design: .default))
                .foregroundColor(textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Rectangle()
                .fill(dividerColor)
                .frame(height: 1)
        }
    }
    
    // MARK: - Confirmation Section
    
    private var confirmationSection: some View {
        VStack(spacing: 24) {
            // Phrase confirmation
            VStack(spacing: 12) {
                Text("To unlock, type:")
                    .font(.system(size: 13, weight: .medium, design: .default))
                    .foregroundColor(textDeemphasized)
                
                Text(requiredPhrase)
                    .font(.system(size: 15, weight: .semibold, design: .default))
                    .foregroundColor(textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                TextField("", text: $confirmationText, axis: .vertical)
                    .font(.system(size: 15, weight: .medium, design: .default))
                    .foregroundColor(textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2...4)
                    .autocapitalization(.sentences)
                    .disableAutocorrection(true)
                    .focused($focusedField, equals: .confirmation)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(fieldBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        confirmationText.trimmingCharacters(in: .whitespaces).lowercased() == requiredPhrase.lowercased() ? textPrimary : textDeemphasized,
                                        lineWidth: 2
                                    )
                            )
                    )
            }
            
            // Signature canvas
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(dividerColor)
                        .frame(height: 1)
                    
                    Text("AND")
                        .font(.system(size: 11, weight: .semibold, design: .default))
                        .foregroundColor(textDeemphasized)
                    
                    Rectangle()
                        .fill(dividerColor)
                        .frame(height: 1)
                }
                .padding(.horizontal, 40)
                
                Text("Sign your name with your finger:")
                    .font(.system(size: 13, weight: .medium, design: .default))
                    .foregroundColor(textDeemphasized)
                
                // Signature pad
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        Canvas { context, size in
                            // Draw signature baseline
                            var baselinePath = Path()
                            let baselineY = size.height - 30
                            baselinePath.move(to: CGPoint(x: 20, y: baselineY))
                            baselinePath.addLine(to: CGPoint(x: size.width - 20, y: baselineY))
                            context.stroke(
                                baselinePath,
                                with: .color(textDeemphasized.opacity(0.3)),
                                style: StrokeStyle(lineWidth: 1, dash: [5, 5])
                            )
                            
                            // Draw signature strokes
                            for line in signatureLines {
                                var path = Path()
                                guard let firstPoint = line.first else { continue }
                                path.move(to: firstPoint)
                                for point in line.dropFirst() {
                                    path.addLine(to: point)
                                }
                                context.stroke(
                                    path,
                                    with: .color(textPrimary),
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                                )
                            }
                            
                            // Draw current line being drawn
                            if !currentLine.isEmpty {
                                var path = Path()
                                path.move(to: currentLine[0])
                                for point in currentLine.dropFirst() {
                                    path.addLine(to: point)
                                }
                                context.stroke(
                                    path,
                                    with: .color(textPrimary),
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                                )
                            }
                        }
                        .frame(height: 120)
                        
                        // Placeholder text
                        if signatureLines.isEmpty && currentLine.isEmpty {
                            VStack {
                                Spacer()
                                Text("Sign here")
                                    .font(.system(size: 14, weight: .regular, design: .default))
                                    .italic()
                                    .foregroundColor(textDeemphasized.opacity(0.5))
                                    .offset(y: -35)
                                Spacer()
                            }
                        }
                    }
                    .background(fieldBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(!signatureLines.isEmpty ? textPrimary : textDeemphasized, lineWidth: 2)
                    )
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                // Light haptic on first touch of new stroke
                                if currentLine.isEmpty {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                }
                                currentLine.append(value.location)
                            }
                            .onEnded { _ in
                                if !currentLine.isEmpty {
                                    signatureLines.append(currentLine)
                                    currentLine = []
                                }
                            }
                    )
                    
                    // Clear button
                    if !signatureLines.isEmpty {
                        Button {
                            withAnimation(.easeOut(duration: 0.2)) {
                                signatureLines = []
                                currentLine = []
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(textDeemphasized)
                                .padding(8)
                        }
                    }
                }
                
                Text("By signing, you acknowledge this is an intentional choice")
                    .font(.system(size: 11, weight: .regular, design: .default))
                    .foregroundColor(textDeemphasized)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 16) {
            // STAY BLOCKED (Primary action)
            Button {
                logUnlockEvent(didProceed: false)
                onStayBlocked()
            } label: {
                Text("Stay Blocked")
                    .font(.system(size: 16, weight: .bold, design: .default))
                    .foregroundColor(primaryButtonText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(primaryButtonBackground)
                    )
            }
            
            // UNLOCK (Requires typing phrase)
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                logUnlockEvent(didProceed: true)
                onUnlock()
            } label: {
                Text("Unlock")
                    .font(.system(size: 16, weight: .bold, design: .default))
                    .foregroundColor(isUnlockEnabled ? dangerButtonText : textDeemphasized)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isUnlockEnabled ? hazardRed : disabledButtonBackground)
                    )
            }
            .disabled(!isUnlockEnabled)
            
            Text("All unlock events are logged")
                .font(.system(size: 12, weight: .regular, design: .default))
                .foregroundColor(textDeemphasized)
        }
    }
    
    // MARK: - Logging
    
    private func logUnlockEvent(didProceed: Bool) {
        let reflection: String? = {
            if didProceed {
                let strokeCount = signatureLines.count
                let pointCount = signatureLines.flatMap { $0 }.count
                return "Typed: '\(confirmationText)' | Handwritten signature provided (\(strokeCount) strokes, \(pointCount) points)"
            }
            return nil
        }()
        
        let event = PauseEvent(
            appIdentifier: nil,
            appName: appName,
            attemptCount: nil,
            promptId: "intentional_block",
            promptCategory: "discipline",
            promptType: "intentional",
            promptQuestion: "Time limit reached. Consider why you set this limit.",
            selectedAnswer: didProceed ? "UNLOCKED" : "STAYED_BLOCKED",
            freeformReflection: reflection,
            didProceed: didProceed,
            unlockMethod: didProceed ? "handwritten_signature" : "none",
            unlockDurationMs: nil,
            stageExitedAt: Date(),
            sessionDurationMs: Int(Date().timeIntervalSince(sessionStartTime) * 1000)
        )
        
        let store = PauseEventStore(modelContext: modelContext)
        store.save(event)
        
        if didProceed {
            print("📊 Unlock logged - Handwritten signature provided (\(signatureLines.count) strokes)")
        } else {
            print("📊 Stayed blocked")
        }
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
