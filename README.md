# LivaKit — lossless conversation capture for iOS

LivaKit records **studio-grade, per-participant audio and video during live
video calls** and delivers it to Liva, time-aligned across participants:

- Local capture per participant: **48 kHz / 24-bit raw WAV** (echo
  cancellation, gain control and noise suppression OFF on the recorded path)
  plus **1080p30 HEVC** video — untouched by the network.
- The live call itself runs over LiveKit/WebRTC at deliberately low quality;
  the recording never goes through the call.
- Continuous clock sync places every participant's recording on a shared
  timeline with millisecond accuracy — participants can join whenever.
- Consent is **enforced in code**: recording cannot start without a
  `ConsentRecord`, and every session manifest carries the exact consent text
  the participant saw, hashed and timestamped.
- Uploads to Liva S3 are automatic and resilient: presigned, retried with
  backoff, resumed after crashes/reboots, buffered offline. Audio and
  manifests upload on any network; video waits for WiFi by default.
- Interruptions (calls, Siri, route changes, reconnects, airplane mode) are
  survived and logged with timestamps, never papered over.

## Never programmed before? Start here instead

**[GETTING_STARTED.md](GETTING_STARTED.md)** walks you from a blank Mac to
a working recording app on your iPhone — installing the tools, creating
your Liva account and key, and having an AI assistant build the entire app
for you. No programming experience assumed.

## Have an app already? Paste this to your AI agent

You don't need to read the rest of this page. Copy the block below into your
coding agent (Claude Code, Codex, Cursor, Replit, …), fill in the two
blanks, and it will do the whole integration:

```
Integrate the LivaKit SDK into my iOS app so every video-call session is
recorded and delivered to Liva.

- Package: add the LivaKit Swift package from https://github.com/symbiateam/crowdplaysdk.
  LivaKit is the ONLY package to add and `import LivaKit` the only import —
  it re-exports everything it needs (including LiveKit). Never add, pin, or
  import LiveKit or WebRTC yourself.
- My Liva app key: <APP KEY from the Liva dashboard>
- Follow the checklist in the package's llms.txt exactly: Info.plist
  permissions, LivaKit.configure at launch, the background-upload hook, the
  consent screen before joining (required — join() will not compile without
  a ConsentRecord), and a join/leave UI.
- Finish by running `await LivaKit.doctor()` and fixing anything it flags,
  then tell me to test on a real iPhone (the Simulator has no camera/mic).
```

## Integration (4 steps)

Requirements: iOS 17+, Swift 5.10+, a real device to test (camera/mic do not
exist in the Simulator), and an **app key** from Liva.

> **One package, one import.** LivaKit re-exports its internals: `import
> LivaKit` also gives you the call-UI types (`SwiftUIVideoView`,
> `RemoteParticipant`, `Room`) for building a FaceTime-style screen. Never
> add or pin LiveKit/WebRTC yourself — the right version ships inside
> LivaKit, matched to the capture engine.

### 1. Add the package

Xcode → File → Add Package Dependencies → this repository URL → add
**LivaKit** to your app target. (Or in `Package.swift` /
`project.yml`, depending on your setup.)

### 2. Declare permissions in Info.plist

```
NSMicrophoneUsageDescription = "Records your microphone during sessions."
NSCameraUsageDescription     = "Records your camera during sessions."
UIBackgroundModes            = [audio]
```

### 3. Configure at launch, wire background uploads

```swift
import LivaKit

// App/scene init — one call is the whole lifecycle hook:
LivaKit.configure(LivaConfiguration(
    serverURL: URL(string: "https://dashboard.crowdplay.ai")!,
    appKey: "<your app key>"
))

// In your UIApplicationDelegate:
func application(_: UIApplication,
                 handleEventsForBackgroundURLSession _: String,
                 completionHandler: @escaping () -> Void) {
    LivaKit.handleBackgroundURLSessionEvents(completionHandler: completionHandler)
}
```

### 4. Consent, then join

```swift
// Show the SDK's drop-in consent screen (or your own UI that constructs
// ConsentRecord(givenAt:) — the manifest evidence is identical):
LivaConsentView { consent in
    Task {
        await engine.join(displayName: name, roomCode: room, consent: consent)
    }
}
```

`CallEngine` is an `ObservableObject` — one per app is typical:

```swift
@StateObject private var engine = CallEngine()

// State your UI can render:
engine.phase                 // .idle / .connecting / .connected / .failed(String)
engine.isRecording           // recording starts automatically on join
engine.recordingSnapshot()   // seconds recorded, segments, dropped samples, clipping
engine.uploads               // per-session upload progress (bars, byte counts)
engine.recordingStartError   // non-nil = the session is NOT being captured; show it

// Controls:
await engine.toggleMute()    // mutes the call AND writes silence to the recording
engine.toggleCamera()        // black frames on both paths, timeline stays continuous
await engine.leave()         // stops recording, uploads begin automatically
```

That's the whole integration. Recording starts when a participant joins and
ends when they leave; capture, sync, upload, retry and crash recovery are
invisible.

## Verifying your integration

```swift
let checks = await LivaKit.doctor()
```

Doctor verifies: SDK configured, Info.plist permission strings present,
mic/camera permission granted, free disk, Liva backend reachable, app key
authenticates. Every failing check names its own fix.

Then record a 1-minute test session on a real device and confirm the upload
card reaches "done" — the session renders server-side within seconds of the
last participant finishing.

## Accessing your recordings

Your app key is also your data-access credential — plain HTTPS, no AWS
account, no SDK required (use it from your backend, a script, or curl):

```bash
BASE=https://dashboard.crowdplay.ai

# Your app's sessions, newest first, with render state:
curl -H "x-liva-key: $APP_KEY" $BASE/sessions

# Every file a session produced, each with a 1-hour download URL:
curl -H "x-liva-key: $APP_KEY" $BASE/sessions/<sessionId>/files
# -> [{"path":"deliverable/speaker-sam.wav","bytes":30498737,"url":"https://…"}, …]
```

`deliverable/` holds what you actually use: `speaker-<name>.wav` per person
(48 kHz/24-bit, drift-corrected — play them together with NO offset),
`conversation.wav` (everyone mixed), `conversation_stereo.wav` (two-person
sessions), and `qc.json` (the quality verdict). `raw/` is the untouched
per-device capture, kept so everything stays reproducible. You can only
list and download sessions recorded with your own key.

## Things to know

- **Don't force-quit the app** after a session: iOS pauses background
  transfers until next launch (they resume automatically — nothing is lost).
- Sessions are ~2 GB per participant-hour, dominated by video. The SDK
  refuses to join below 8 GB free disk (configurable).
- Participants should wear **wired or closed-back headphones**; a loudspeaker
  pipes the far end's voice into the local mic and contaminates the track.
  The SDK surfaces this live (`engine.crossTalkRisk`).
- `LivaConfiguration` exposes the tuning knobs (cellular video, delete-after-
  upload, disk floor); the defaults are the configuration proven on hardware.
- **Slow join + glitchy first seconds = bad radio, not a bug.** On a poor
  network (especially congested 2.4 GHz WiFi with Bluetooth headphones —
  they share the antenna), the call takes longer to connect and iOS's audio
  I/O can stutter while the Bluetooth link settles, chopping the first
  seconds of the recording. The capture self-heals once the link stabilizes
  and the rest of the session is unaffected. If you see this: move to a
  better network, prefer wired headphones, and when testing, launch the app
  from the home screen — running under Xcode's debugger adds enough overhead
  to cause the same symptoms on first launch.

## Example

`../Examples/LivaKitSample` is a complete integration in ~130 lines: consent
screen → join form → REC indicator → leave, plus a doctor button. Build it
with `xcodegen generate && open LivaKitSample.xcodeproj`.
