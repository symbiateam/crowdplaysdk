import CrowdPlaySDK
import SwiftUI

/// The throwaway sample proving the M6 gate: it depends ONLY on the CrowdPlay
/// package and records a verified session. This is also the shape of what a
/// builder's coding agent produces from the README — consent screen, join,
/// leave, nothing else. Everything hard (capture, sync, uploads, resilience)
/// is invisible.
@main
struct SampleApp: App {
    @StateObject private var engine = CallEngine()

    init() {
        // Paste your app key into SampleSecrets.swift (from the CrowdPlay
        // dashboard) before running.
        CrowdPlay.configure(CrowdPlayConfiguration(
            serverURL: URL(string: "https://dashboard.crowdplay.ai")!,
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
                CrowdPlayConsentView { consent = $0 }
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
                        let checks = await CrowdPlay.doctor()
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
        .task { CrowdPlay.warmUp() }
    }
}

struct InCallView: View {
    @ObservedObject var engine: CallEngine

    var body: some View {
        VStack(spacing: 24) {
            // The standard voice-AI visual: breathes while idle, rings while
            // you talk, pulses while the AI talks. Style it via
            // CrowdPlayVoiceStyle, or observe CrowdPlayVoiceMonitor and draw
            // your own.
            CrowdPlayVoiceView(engine: engine)
            // Live captions: each line as it is spoken (agent broadcasts
            // over the data channel). Speech-bubble / subtitle building block.
            if let caption = engine.latestCaption {
                Text("\(caption.role == "agent" ? "AI" : "You"): \(caption.text)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal)
                    .transition(.opacity)
                    .id(caption.id)
            }
            if engine.isRecording {
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    let snapshot = engine.recordingSnapshot()
                    let seconds = Int(snapshot?.seconds ?? 0)
                    VStack(spacing: 8) {
                        Label(String(format: "REC %d:%02d", seconds / 60, seconds % 60),
                              systemImage: "record.circle.fill")
                            .foregroundStyle(.red)
                            .font(.title3.monospacedDigit())
                        if snapshot?.inputSilent == true, !engine.isMicMuted {
                            Label("MIC IS SILENT — check your headset plug",
                                  systemImage: "mic.slash.circle.fill")
                                .foregroundStyle(.red)
                                .font(.caption.bold())
                        }
                        if snapshot?.audioStalled == true {
                            Label("AUDIO STALLED — recovering…",
                                  systemImage: "exclamationmark.arrow.circlepath")
                                .foregroundStyle(.red)
                                .font(.caption.bold())
                        }
                    }
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
