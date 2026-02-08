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
    
    private var isUnlockEnabled: Bool {
        let phraseMatches = confirmationText.trimmingCharacters(in: .whitespaces).lowercased() == requiredPhrase.lowercased()
        let hasSignature = !signatureLines.isEmpty
        return phraseMatches && hasSignature
    }
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.Colors.background(for: colorScheme).ignoresSafeArea()
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.xxxl) {
                        Spacer().frame(height: AppTheme.Spacing.xxl)
                        
                        // MARK: - Header
                        headerSection
                        
                        // MARK: - Main Statement
                        mainStatementSection
                        
                        // MARK: - Reality Check
                        realityCheckSection
                        
                        Spacer().frame(height: AppTheme.Spacing.lg)
                        
                        // MARK: - Confirmation Input
                        confirmationSection
                            .id("confirmationSection")
                        
                        // MARK: - Actions
                        actionsSection
                        
                        Spacer().frame(height: AppTheme.Spacing.xxxl)
                    }
                    .padding(.horizontal, AppTheme.Spacing.xxl)
                }
                .onChange(of: focusedField) { _, newValue in
                    if newValue != nil {
                        withAnimation(AppTheme.Animation.standard) {
                            proxy.scrollTo("confirmationSection", anchor: .center)
                        }
                    }
                }
            }
            .opacity(showView ? 1 : 0)
        }
        .onAppear {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            withAnimation(AppTheme.Animation.slow) {
                showView = true
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "lock.circle")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.Colors.warning)
                .imageScale(.large)
            
            Text("Time limit reached")
                .font(AppTheme.Typography.title(weight: .semibold))
                .foregroundColor(AppTheme.Colors.textPrimary(for: colorScheme))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Main Statement Section
    
    private var mainStatementSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            if let minutes = minutesSpent, minutes > 0 {
                Text("You've spent \(minutes) minutes today")
                    .font(AppTheme.Typography.body(weight: .medium))
                    .foregroundColor(AppTheme.Colors.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
            } else {
                Text("Your daily limit has been reached")
                    .font(AppTheme.Typography.body(weight: .medium))
                    .foregroundColor(AppTheme.Colors.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
            }
            
            if let appName = appName {
                Text("on \(appName)")
                    .font(AppTheme.Typography.caption())
                    .foregroundColor(AppTheme.Colors.textMuted(for: colorScheme))
            }
        }
        .padding(.vertical, AppTheme.Spacing.md)
    }
    
    // MARK: - Reality Check Section
    
    private var realityCheckSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            ThemeDivider()
            
            Text("Take a moment to consider why you set this limit")
                .font(AppTheme.Typography.body(weight: .medium))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xl)
            
            ThemeDivider()
        }
    }
    
    // MARK: - Confirmation Section
    
    private var confirmationSection: some View {
        VStack(spacing: AppTheme.Spacing.xxl) {
            // Phrase confirmation
            VStack(spacing: AppTheme.Spacing.md) {
                Text("To unlock, type:")
                    .font(AppTheme.Typography.caption(weight: .medium))
                    .foregroundColor(AppTheme.Colors.textMuted(for: colorScheme))
                
                Text(requiredPhrase)
                    .font(AppTheme.Typography.body(weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.xl)
                
                TextField("", text: $confirmationText, axis: .vertical)
                    .font(AppTheme.Typography.body(weight: .medium))
                    .foregroundColor(AppTheme.Colors.textPrimary(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .lineLimit(2...4)
                    .autocapitalization(.sentences)
                    .disableAutocorrection(true)
                    .focused($focusedField, equals: .confirmation)
                    .padding(.vertical, AppTheme.Spacing.lg)
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                            .fill(AppTheme.Colors.surface(for: colorScheme))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                                    .stroke(
                                        confirmationText.trimmingCharacters(in: .whitespaces).lowercased() == requiredPhrase.lowercased() 
                                            ? AppTheme.Colors.accent 
                                            : AppTheme.Colors.border(for: colorScheme),
                                        lineWidth: 1.5
                                    )
                            )
                    )
            }
            
            // Signature canvas
            VStack(spacing: AppTheme.Spacing.md) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Rectangle()
                        .fill(AppTheme.Colors.divider(for: colorScheme))
                        .frame(height: 1)
                    
                    Text("AND")
                        .font(AppTheme.Typography.label(weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textMuted(for: colorScheme))
                    
                    Rectangle()
                        .fill(AppTheme.Colors.divider(for: colorScheme))
                        .frame(height: 1)
                }
                .padding(.horizontal, 40)
                
                Text("Sign your name with your finger:")
                    .font(AppTheme.Typography.caption(weight: .medium))
                    .foregroundColor(AppTheme.Colors.textMuted(for: colorScheme))
                
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
                                with: .color(AppTheme.Colors.textMuted(for: colorScheme).opacity(0.3)),
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
                                    with: .color(AppTheme.Colors.textPrimary(for: colorScheme)),
                                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
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
                                    with: .color(AppTheme.Colors.textPrimary(for: colorScheme)),
                                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                                )
                            }
                        }
                        .frame(height: 120)
                        
                        // Placeholder text
                        if signatureLines.isEmpty && currentLine.isEmpty {
                            VStack {
                                Spacer()
                                Text("Sign here")
                                    .font(AppTheme.Typography.body())
                                    .italic()
                                    .foregroundColor(AppTheme.Colors.textMuted(for: colorScheme).opacity(0.5))
                                    .offset(y: -35)
                                Spacer()
                            }
                        }
                    }
                    .background(AppTheme.Colors.surface(for: colorScheme))
                    .cornerRadius(AppTheme.CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                            .stroke(
                                !signatureLines.isEmpty ? AppTheme.Colors.accent : AppTheme.Colors.border(for: colorScheme),
                                lineWidth: 1.5
                            )
                    )
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
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
                            withAnimation(AppTheme.Animation.quick) {
                                signatureLines = []
                                currentLine = []
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(AppTheme.Colors.textMuted(for: colorScheme))
                                .padding(AppTheme.Spacing.sm)
                        }
                    }
                }
                
                Text("By signing, you acknowledge this is an intentional choice")
                    .font(AppTheme.Typography.caption())
                    .foregroundColor(AppTheme.Colors.textMuted(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // STAY BLOCKED (Primary action)
            Button {
                logUnlockEvent(didProceed: false)
                onStayBlocked()
            } label: {
                Text("Stay Blocked")
                    .font(AppTheme.Typography.body(weight: .medium))
                    .themePrimaryButton(colorScheme: colorScheme)
            }
            
            // UNLOCK (Requires typing phrase and signature)
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                logUnlockEvent(didProceed: true)
                onUnlock()
            } label: {
                Text("Unlock apps")
                    .font(AppTheme.Typography.body(weight: .medium))
                    .foregroundColor(isUnlockEnabled ? AppTheme.Colors.destructive : AppTheme.Colors.textMuted(for: colorScheme))
                    .themeOutlineButton(color: isUnlockEnabled ? AppTheme.Colors.destructive : AppTheme.Colors.textMuted(for: colorScheme))
            }
            .disabled(!isUnlockEnabled)
            .opacity(isUnlockEnabled ? 1.0 : 0.5)
            
            Text("All unlock events are logged")
                .font(AppTheme.Typography.caption())
                .foregroundColor(AppTheme.Colors.textMuted(for: colorScheme))
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
