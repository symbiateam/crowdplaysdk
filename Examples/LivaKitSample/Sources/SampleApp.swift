import LivaKit
import SwiftUI

/// The throwaway sample proving the M6 gate: it depends ONLY on the LivaKit
/// package and records a verified session. This is also the shape of what a
/// builder's coding agent produces from the README — consent screen, join,
/// leave, nothing else. Everything hard (capture, sync, uploads, resilience)
/// is invisible.
@main
struct SampleApp: App {
    @StateObject private var engine = CallEngine()

    init() {
        // Paste your app key into SampleSecrets.swift (from the Liva
        // dashboard) before running.
        LivaKit.configure(LivaConfiguration(
            serverURL: URL(string: "https://qk3grprk2reflvyhihftoncoje0pavjk.lambda-url.us-east-1.on.aws")!,
            appKey: SampleSecrets.appKey
        ))
    }

    var body: some Scene {
        WindowGroup {
            RootView(engine: engine)
        }
    }
}

struct RootView: View {
    @ObservedObject var engine: CallEngine
    @State private var consent: ConsentRecord?
    @State private var name = ""
    @State private var room = ""
    @State private var doctorReport = ""

    var body: some View {
        switch engine.phase {
        case .connected:
            InCallView(engine: engine)
        default:
            if let consent {
                joinForm(consent: consent)
            } else {
                // The SDK's drop-in consent screen. Recording cannot start
                // without the record it produces — join() won't compile
                // without one.
                LivaConsentView { consent = $0 }
            }
        }
    }

    private func joinForm(consent: ConsentRecord) -> some View {
        Form {
            Section("Join") {
                TextField("Your name", text: $name)
                TextField("Room code", text: $room)
                    .textInputAutocapitalization(.never)
                Button(engine.phase == .connecting ? "Connecting…" : "Join") {
                    Task {
                        await engine.join(displayName: name, roomCode: room,
                                          consent: consent)
                    }
                }
                .disabled(name.isEmpty || room.isEmpty || engine.phase == .connecting)
                if case let .failed(message) = engine.phase {
                    Text(message).foregroundStyle(.red).font(.caption)
                }
            }
            Section("Uploads") {
                if engine.uploads.isEmpty {
                    Text("Nothing pending").foregroundStyle(.secondary)
                }
                ForEach(engine.uploads) { p in
                    HStack {
                        Text(p.sessionId).font(.caption).lineLimit(1)
                        Spacer()
                        Text(p.isComplete ? "done" : String(format: "%.0f%%", p.fraction * 100))
                            .font(.caption.monospacedDigit())
                    }
                }
            }
            Section("Integration doctor") {
                Button("Run doctor") {
                    Task {
                        let checks = await LivaKit.doctor()
                        doctorReport = checks
                            .map { "\($0.passed ? "✓" : "✗") \($0.id): \($0.detail)" }
                            .joined(separator: "\n")
                    }
                }
                if !doctorReport.isEmpty {
                    Text(doctorReport).font(.caption.monospaced())
                }
            }
        }
        .task { LivaKit.warmUp() }
    }
}

struct InCallView: View {
    @ObservedObject var engine: CallEngine

    var body: some View {
        VStack(spacing: 24) {
            if engine.isRecording {
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    let seconds = Int(engine.recordingSnapshot()?.seconds ?? 0)
                    Label(String(format: "REC %d:%02d", seconds / 60, seconds % 60),
                          systemImage: "record.circle.fill")
                        .foregroundStyle(.red)
                        .font(.title3.monospacedDigit())
                }
            } else if let error = engine.recordingStartError {
                Text("NOT RECORDING — \(error)").foregroundStyle(.red)
            }
            if let summary = engine.lastRecordingSummary {
                Text(summary).font(.caption2).foregroundStyle(.secondary)
            }
            Button("Leave") {
                Task { await engine.leave() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }
}
