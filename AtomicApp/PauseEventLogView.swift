//
//  PauseEventLogView.swift
//  AtomicApp
//
//  Event log viewer with copy functionality
//

import SwiftUI
import SwiftData

struct PauseEventLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PauseEvent.createdAt, order: .reverse) private var events: [PauseEvent]
    
    @State private var showCopiedAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(events) { event in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(event.createdAt, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(event.createdAt, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if let appName = event.appName {
                                Text(appName)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            if let category = event.promptCategory {
                                HStack {
                                    Text("[\(category)]")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(Color.purple.opacity(0.1))
                                        .cornerRadius(3)
                                    
                                    Spacer()
                                }
                            }
                            
                            Text("Q: \(event.promptQuestion)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("A: \(event.selectedAnswer)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if let reflection = event.freeformReflection, !reflection.isEmpty {
                                Text("Reflection: \(reflection)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .italic()
                                    .padding(.top, 2)
                            }
                        }
                        
                        HStack {
                            if event.didProceed {
                                Label("Proceeded", systemImage: "checkmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            } else {
                                Label("Closed", systemImage: "xmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                            
                            Text("via \(event.unlockMethod)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Pause Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        copyAllEvents()
                        showCopiedAlert = true
                    } label: {
                        Label("Copy All", systemImage: "doc.on.doc")
                    }
                }
            }
            .alert("Copied!", isPresented: $showCopiedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("All \(events.count) events copied to clipboard")
            }
            .overlay {
                if events.isEmpty {
                    ContentUnavailableView(
                        "No Events Yet",
                        systemImage: "tray",
                        description: Text("Pause events will appear here")
                    )
                }
            }
        }
    }
    
    private func copyAllEvents() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        let text = events.map { event in
            var lines = [
                "[\(dateFormatter.string(from: event.createdAt))]",
                "App: \(event.appName ?? "Unknown")"
            ]
            
            if let count = event.attemptCount {
                lines.append("Attempts: \(count)")
            }
            
            if let category = event.promptCategory {
                lines.append("Category: \(category)")
            }
            if let promptId = event.promptId {
                lines.append("Prompt ID: \(promptId)")
            }
            lines.append("Q: \(event.promptQuestion)")
            lines.append("A: \(event.selectedAnswer)")
            
            if let reflection = event.freeformReflection, !reflection.isEmpty {
                lines.append("Reflection: \(reflection)")
            }
            
            lines.append("Result: \(event.didProceed ? "Proceeded" : "Closed") via \(event.unlockMethod)")
            
            if let duration = event.sessionDurationMs {
                lines.append("Duration: \(duration)ms")
            }
            
            return lines.joined(separator: "\n")
        }.joined(separator: "\n\n---\n\n")
        
        UIPasteboard.general.string = text
    }
}

#Preview {
    PauseEventLogView()
        .modelContainer(for: PauseEvent.self, inMemory: true)
}
