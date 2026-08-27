# Getting started: your Mac, your iPhone, your first recorded call

The CrowdPlay dashboard already writes your code prompt and tracks your
setup. What it cannot do is set up your Mac or put the app on your phone.
That is what this guide covers.

You do not need to know how to code. Budget about an hour the first time,
most of it waiting for Xcode to download.

| You need | Why |
|---|---|
| A Mac | iPhone apps can only be built on a Mac |
| An iPhone (15 or newer recommended) + cable | Recording needs a real camera and mic; the Simulator has neither |
| An Apple ID | Signs the app so your iPhone will run it (free) |
| An AI coding assistant | Writes the app for you (Claude Code, Cursor, Codex, Rork, and others all work) |

## 1. Install Xcode

Open the **App Store** on your Mac, search **Xcode**, click **Get**. It is
many gigabytes, so start it now and read on while it downloads. Open it
once when it finishes and click **Install** if it asks for additional
components.

Skip this step for now if you are building in a cloud app builder like
Rork. You will still need Xcode before your app can run on a real iPhone.

## 2. Get your app key and prompt

Sign in at **https://dashboard.crowdplay.ai**, create your app, and press
**Copy agent prompt**. The prompt is tailored to the tool you said you are
using, and your key looks like `liva_pk_yourname_abc123…`. Your dashboard
also grows a setup checklist that turns green on its own as you progress.

Paste that prompt into your AI assistant and let it build. Everything from
here is about getting the result onto your phone.

## 3. React Native only: create the iOS project

Swift builders can skip this. CrowdPlay is a native module, so it needs a
real `ios/` folder and cannot run in Expo Go:

```bash
npx expo prebuild -p ios          # only if you started from a managed Expo app
npm install crowdplaysdk
cd ios && pod install
gem install xcodeproj --user-install          # one time
ruby node_modules/crowdplaysdk/ios/wire.rb <YourProjectName>
```

## 4. Put the app on your iPhone

1. Plug the iPhone into the Mac with its cable. Unlock it and tap **Trust**
   if asked.
2. On the iPhone: **Settings → Privacy & Security → Developer Mode**, turn
   it on, and let the phone restart.
3. In Xcode, pick your iPhone in the device menu at the top, then press the
   **Run** button (the triangle).
4. First run only, if Xcode complains about signing: **Signing &
   Capabilities → Team**, add your Apple ID, and let it sign automatically.
   A free Apple ID is enough.
5. First launch only, if the app will not open: on the iPhone, **Settings →
   General → VPN & Device Management**, tap your Apple ID, tap **Trust**,
   then run again.
6. Allow **microphone and camera** when the app asks. Recording is
   impossible without them.

## 5. Your first recorded call

Open the app from the home screen rather than from Xcode, accept the
consent screen, join with any room code, and talk for about a minute. For a
two-person test, install on a second iPhone the same way and join with the
same room code.

Tap **Leave** and keep the app open until uploading finishes. Then sign in
at **https://dashboard.crowdplay.ai**: your session appears with its
recording, and your checklist turns green. That is the end-to-end proof.

## Getting good recordings

- **Wear headphones**, wired if possible. On loudspeaker the other person's
  voice leaks into your mic and contaminates your track. The app warns you
  live when this happens.
- **Keep the app open and the screen on.** Locking the phone suspends
  recording.
- **Do not force-quit after a call.** Uploads finish in the background;
  force-quitting pauses them until you next open the app. Nothing is lost.
- **Launch from the home screen when judging quality.** Running under
  Xcode's debugger adds enough overhead to stutter the first few seconds.

## When something goes wrong

Paste the full error into your AI assistant; fixing build errors is its
job. Ask it to run `await CrowdPlay.doctor()`, which checks the whole setup
and tells each failing check how to fix itself.

For recording or upload questions it cannot answer, contact CrowdPlay with
your room code. Every session's diagnostics are on our side too.
