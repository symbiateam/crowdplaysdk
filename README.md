# CrowdPlaySDK

CrowdPlaySDK adds live calls and high-quality conversation capture to iOS apps.

## What the SDK handles

CrowdPlaySDK handles the infrastructure around the call:

* Joining and leaving calls
* Microphone and camera access
* Participant audio and video
* Mute, camera, and audio-output controls
* User consent before capture begins
* Per-participant data capture and synchronization
* Uploads, retries, and recovery
* Session lifecycle and common interruptions

Once a user consents and joins a call, capture and delivery happen
automatically.

## What you build

You build the actual product and user experience:

* Your app's screens, navigation, and design
* What users do in your app
* When and why a call happens
* The UI around the call
* Your own accounts, profiles, content, or other product features

For example, if you're building a tutoring app, **you build the tutoring
experience**. CrowdPlaySDK provides the call and capture infrastructure
underneath it.

Your integration is essentially:

**Your app → consent → join call → CrowdPlay handles the rest**

## Three kinds of calls

You pick one when you create your app on the dashboard, and you can change
it later:

* **Video + audio.** Face-to-face calls between people. Both are recorded.
* **Audio-only.** Voice calls between people, no camera anywhere in the app.
* **Voice AI.** Your users talk with a live AI voice instead of another
  person. Audio only, no camera.

## Getting started

Sign in at **https://dashboard.crowdplay.ai**, create your app, and press
**Copy agent prompt**. The prompt is pre-filled with your key and tailored
to the tool you build with, so paste it into your coding agent and it will
build the app. Your dashboard then tracks setup and shows your recordings.

**[GETTING_STARTED.md](GETTING_STARTED.md)** covers what the dashboard
cannot do for you: setting up your Mac and getting the app onto a real
iPhone. No programming experience assumed.

**Building in React Native?** Use the `crowdplaysdk` package on npm
instead. It drives this same engine, so recording quality is identical, and
it ships its own setup steps: https://www.npmjs.com/package/crowdplaysdk

## Integration

Requirements: iOS 17+, Swift 5.10+, a real device to test (the Simulator
has no camera or mic), and an **app key** from CrowdPlay.

> **One package, one import.** `import CrowdPlaySDK` also gives you the
> call-UI types (`SwiftUIVideoView`, `RemoteParticipant`, `Room`) for
> building a FaceTime-style screen. Never add or pin LiveKit or WebRTC
> yourself; the matching version ships inside.

**1. Add the package.** Xcode → File → Add Package Dependencies → this
repository URL → add **CrowdPlaySDK** to your app target.

**2. Declare permissions in Info.plist.**

```
NSMicrophoneUsageDescription = "Records your microphone during sessions."
NSCameraUsageDescription     = "Records your camera during sessions."
UIBackgroundModes            = [audio]
```

**3. Configure at launch and wire background uploads.**

```swift
import CrowdPlaySDK

var config = CrowdPlayConfiguration(
    serverURL: URL(string: "https://dashboard.crowdplay.ai")!,
    appKey: "<your app key>"
)
// config.audioOnly = true    // audio-only or Voice AI app: no camera at all
// config.otherAudio = .mix   // keep Apple Music / Spotify playing (0.4.0+)
CrowdPlay.configure(config)

// In your UIApplicationDelegate:
func application(_: UIApplication,
                 handleEventsForBackgroundURLSession _: String,
                 completionHandler: @escaping () -> Void) {
    CrowdPlay.handleBackgroundURLSessionEvents(completionHandler: completionHandler)
}
```

**4. Consent, then join.**

```swift
CrowdPlayConsentView { consent in
    Task {
        await engine.join(displayName: name, roomCode: room, consent: consent)
    }
}
```

`CallEngine` is an `ObservableObject`; one per app is typical:

```swift
@StateObject private var engine = CallEngine()

engine.phase                 // .idle / .connecting / .connected / .failed(String)
engine.isRecording           // recording starts automatically on join
engine.uploads               // per-session upload progress
engine.recordingStartError   // non-nil = NOT being captured; show it
engine.storageWarning        // non-nil = storage low: audio-only or stopped

await engine.toggleMute()
engine.toggleCamera()
await engine.leave()         // uploads begin automatically
```

That's the whole integration. Capture, sync, upload, retry and crash
recovery are invisible.

## Voice AI

If you picked **Voice AI**, a live AI voice joins the call as an ordinary
participant, greets your user, and holds a real spoken conversation. Users
can interrupt it and it responds with natural timing. Both sides are
recorded and transcribed like any other call.

**Your app writes no AI code.** No model API calls, no API keys, no speech
recognition, no text-to-speech. You choose the AI's voice and personality
on the dashboard and can change them any time; everything else runs on
CrowdPlay's servers.

The only thing your app draws is what the AI looks like on screen. It has
no camera, so never give it a video tile. The SDK ships an animated orb
that breathes when idle, ripples with your user's voice, and pulses when
the AI speaks:

```swift
CrowdPlayVoiceView(engine: engine)
```

Restyle it with `CrowdPlayVoiceStyle`, wrap your own artwork using
`.voiceReactive(monitor)`, or drive any visual you like from
`CrowdPlayVoiceMonitor`. Show live subtitles from `engine.latestCaption`,
and identify the AI participant with `participant.isVoiceAgent`.

You can also override the voice, personality and context for a single call,
which is how you give the AI memory of a particular user:

```swift
await engine.join(displayName: name, roomCode: room, consent: consent,
                  agent: CrowdPlayAgentOptions(
                      voice: "Aoede",
                      context: "Their name is Sam. Last time you discussed Kyoto."))
```

See `llms.txt` for the full menu of visuals and options.

## Verifying your integration

```swift
let checks = await CrowdPlay.doctor()
```

Doctor verifies configuration, Info.plist strings, permissions, free disk,
backend reachability and your app key. Every failing check names its own
fix. Then record a one-minute session on a real device and confirm the
upload finishes.

## Checking your sessions

Your app key also lists the sessions it recorded, over plain HTTPS: no AWS
account, no SDK required.

```bash
curl -H "x-liva-key: $APP_KEY" https://dashboard.crowdplay.ai/sessions
```

Each row carries the session id, its state (`uploading`, `ok`, `partial`
or `failed`), the participants, participant minutes and any quality
warnings. You only see sessions recorded with your key, and the dashboard
shows the same list. Use it to confirm that sessions upload and render.

The recordings themselves stay in CrowdPlay's storage. There is no
download endpoint for builders: `GET /sessions/<sessionId>/files` answers
403 to an app key, and the dashboard does not offer downloads either.

## Things to know

- **Don't force-quit the app** after a session: iOS pauses background
  transfers until next launch. They resume automatically and nothing is
  lost.
- With video, a session uses about 6.8 GB per participant-hour on the phone
  (1080p HEVC at 14 Mbps plus 24-bit audio); audio-only is about 0.5 GB.
  Files are deleted as each one uploads. Video waits for WiFi, so on
  cellular it stays on the phone until then. The SDK never fills the phone:
  under 2 GB free the recording continues audio-only, under 500 MB it
  stops, and the call itself always continues. This happens silently:
  the SDK shows nothing on screen. `engine.storageWarning` says when it
  happens, if you want to ask the user to free up space.
  `doctor()` also reports free disk against `requiredFreeDiskBytes`
  (8 GiB by default).
- Participants should wear **wired or closed-back headphones**. A
  loudspeaker pipes the far end into the local mic and contaminates the
  track; the SDK surfaces this live via `engine.crossTalkRisk`.
- **Slow join or glitchy first seconds is bad radio, not a bug.** Congested
  2.4 GHz WiFi and Bluetooth headphones share an antenna. Capture
  self-heals and the rest of the session is fine. Xcode's debugger causes
  the same symptoms, so launch from the home screen when judging quality.

`llms.txt` carries the full reference, including capture formats, the
complete event and warning list, and the voice-AI options. It is written
for coding agents.

## Example

`Examples/CrowdPlaySample` is a complete integration in ~150 lines: consent
screen → join form → REC indicator → leave, plus a doctor button. Build it
with `xcodegen generate && open CrowdPlaySample.xcodeproj`.
