# Getting started with CrowdPlay — no programming experience needed

This guide takes you from **nothing** to **a working iPhone app that
records studio-quality video calls**, using an AI coding assistant to do
all the programming for you. Budget about an hour the first time; most of
it is waiting for downloads.

You do not need to know how to code. You DO need to follow the steps in
order and copy-paste carefully.

## What you need

| Thing | Why | Cost |
|---|---|---|
| A Mac (Apple laptop or desktop) | iPhone apps can only be built on a Mac | — |
| An iPhone (iPhone 15 or newer recommended) + its charging cable | Recording needs a real camera and microphone; the on-screen simulator has neither | — |
| An Apple ID (the account you use for the App Store) | Signs the app so your iPhone will run it | Free |
| An AI coding assistant | Writes and fixes all the code | Claude Code, Cursor, and others have free tiers or trials |
| A CrowdPlay account and app key | Connects your app to CrowdPlay and lets you download your recordings | Free |

## Step 1 — Install Xcode (Apple's app-building tool)

1. On your Mac, open the **App Store** (the blue "A" icon).
2. Search for **Xcode** and click **Get**, then **Install**. It is a big
   download (many gigabytes) — start it now and continue with the steps
   below while it downloads.
3. When it finishes, open Xcode once. It will ask to "install additional
   components" — click **Install** and let it finish.
4. If Xcode asks you to select "platform support", make sure **iOS** is
   checked.

## Step 2 — Get an AI coding assistant

Any capable coding agent works (Claude Code, Cursor, Codex, …). If you
don't have one, here is the Claude Code route:

1. Open the **Terminal** app on your Mac (press ⌘+Space, type
   `terminal`, press Enter). A white or black text window opens — this is
   just a place to type commands.
2. Go to https://claude.com/claude-code in your browser and follow the
   install instructions for Mac (one copy-paste into that Terminal
   window).
3. When it's installed, type `claude` in the Terminal and press Enter.
   Sign in when it asks. You now have an AI assistant that can create
   files and build apps on your Mac.

## Step 3 — Create your CrowdPlay account and get your app key

1. In your browser, go to **https://dashboard.crowdplay.ai**
2. Click **Create account**, enter your email and a password.
3. Click **Generate key**. Type your project's name and, in "What are you
   building?", a one-line description of your app idea (for example: *a
   tutoring app where students and tutors meet over video*).
4. A key that looks like `liva_pk_yourname_abc123…` is created and copied
   for you. Don't worry about losing it — you can view and copy your keys
   in the dashboard any time (up to 5 keys per account).
5. Best shortcut: press **Copy agent prompt** next to your key — it gives
   you the entire Step 4 instruction below with your key and your app
   idea already filled in.

This dashboard is also where your recordings will appear later.

## Step 4 — Tell the AI to build your app

Copy the entire block below, paste it into your AI assistant, and replace
the two `<...>` parts before sending:

```
I'm building this app: <YOUR APP IDEA — e.g., a tutoring app where
students and tutors meet over video. If you just want to try things
out, write: a simple video-call app>

Build it as a complete native iOS app (SwiftUI, iOS 17+) and walk me
through everything — assume I have never used Xcode. For the video-call
feature, use the CrowdPlaySDK Swift package from:
https://github.com/symbiateam/crowdplaysdk

What the app is about — read carefully:
- The app's name, screens, and flows are about MY IDEA above. The SDK
  records calls in the background for CrowdPlay; recording is NOT the
  app's purpose and must not be presented as it. It appears in the UI
  in exactly three places: the SDK's consent screen before joining a
  call, a small REC indicator during the call, and join/leave.
- Keep the SDK integration minimal: consent screen → join/leave → call
  screen with everyone's video and mute/camera/leave buttons. Do NOT
  build upload screens, diagnostics screens, or SDK settings. Uploads
  happen automatically in the background.

- Create a new Xcode project for me (tell me every click), or generate
  the project yourself if you have tools for that.
- CrowdPlaySDK is the ONLY package to add and `import CrowdPlaySDK` the
  only import. Never add LiveKit or WebRTC yourself.
- My CrowdPlay app key is: <PASTE YOUR liva_pk_… KEY HERE>
- Follow the CrowdPlaySDK package's llms.txt exactly (permissions,
  CrowdPlay.configure at launch, the background-upload hook, consent
  before joining).
- When the code is done, run `await CrowdPlay.doctor()` as a development
  check (not an app screen) and fix anything actionable. Then give me
  exact step-by-step instructions (every click) to run the app on my
  physical iPhone, including the free Apple signing setup and iPhone
  Developer Mode.
- My iPhone model and iOS version are: <e.g. iPhone 15, iOS 18>
```

The AI will now create the project and code. Answer its questions; if
anything errors, paste the full error message back to the AI — fixing
errors is its job.

## Step 5 — Put the app on your iPhone

The AI will guide you, but this is what to expect (so nothing surprises
you):

1. **Plug your iPhone into the Mac** with its cable. Tap **Trust** on the
   phone if asked, and enter your phone passcode.
2. **Signing**: in Xcode, the project's *Signing & Capabilities* tab needs
   a "Team". Click the dropdown, choose **Add an Account…**, and sign in
   with your Apple ID. Then select your name ("Personal Team"). This is
   free.
3. **Developer Mode** (first time only): the phone will refuse to run the
   app until you enable Settings → Privacy & Security → **Developer
   Mode** → on, then restart the phone.
4. In Xcode, select your iPhone in the device menu at the top, and press
   the **▶ (Run)** button.
5. First launch may show **"Untrusted Developer"** on the phone: go to
   Settings → General → VPN & Device Management → tap your Apple ID →
   **Trust**. Run again from Xcode.
6. The app will ask for **microphone and camera permission** — tap Allow
   (recording is impossible without them).

## Step 6 — Your first recorded call

1. Open the app on your iPhone. Type your name and any room code (for
   example `test1`), accept the consent screen, and join.
2. Talk for a minute or two. You'll see a recording indicator. (For a
   two-person test: install the app on a second iPhone the same way, join
   with the SAME room code.)
3. Tap **Leave**. Keep the app open — you'll see upload progress. Wait
   for it to finish (WiFi recommended; video waits for WiFi by default).
4. Go to **https://dashboard.crowdplay.ai**, sign in, and your session
   appears in the list. Click it to download the studio-quality audio
   (one WAV file per speaker, perfectly time-aligned) and video files.

## Tips for good recordings

- **Wear wired headphones** (or any headphones). On loudspeaker, the
  other person's voice leaks into your microphone and contaminates your
  track — the app warns you live when this is happening.
- **Keep the app open and the screen on** during the call. Locking the
  phone suspends recording.
- **Don't force-quit the app** after a call — uploads finish in the
  background, but force-quitting pauses them until you next open the app
  (nothing is lost).
- Slow join or a rough first few seconds usually means a **bad WiFi /
  Bluetooth environment**, not a broken app. Move closer to the router
  or use wired headphones; the recording stabilizes by itself.
- Each hour of recording uses roughly **2 GB of phone storage** until
  the upload completes. The app refuses to start below 8 GB free.

## When something goes wrong

1. Copy the exact error text (or screenshot) and paste it to your AI
   assistant. Say what step you were on.
2. Ask the AI to run `await CrowdPlay.doctor()` — it checks the whole
   setup and every failing check says how to fix itself.
3. Recording/upload questions the AI can't answer: contact CrowdPlay with
   your room code — every session's diagnostics are on our side too.
