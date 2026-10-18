# PresenceKeeper

Keep your Mac awake while you are sitting in front of it. Let it lock normally when you walk away.

macOS only knows you are "active" when you touch the keyboard or trackpad. If you sit still while reading, watching, or waiting for a long build or an AI response, the screen dims, sleeps, and locks. PresenceKeeper uses the built-in camera to check whether a face is in front of the Mac and, if so, tells macOS you are still there.

It never locks anything itself. When nobody is in front of the camera it does nothing, and your existing Lock Screen and Energy settings apply exactly as before.

## How it works

- Every 20 seconds it turns the camera on for about 1.5 seconds and grabs one frame.
- Core Image face detection runs on that frame, on-device. No frame is stored or sent anywhere.
- If a face is found it calls `IOPMAssertionDeclareUserActivity`, which resets the system idle timer the same way a key press would.
- While the display is asleep the camera is not used at all.

Measured on an Apple Silicon MacBook Pro: about 85 MB of memory and near 0% CPU between checks.

## Requirements

- macOS 13 or later
- A built-in or external camera
- Xcode Command Line Tools (`xcode-select --install`)

## Install

```bash
git clone https://github.com/<your-account>/presence-keeper.git
cd presence-keeper
make install
```

macOS asks for camera access on first launch. Click **Allow**.

`make install` builds the app into `~/Applications/PresenceKeeper.app` and registers a LaunchAgent so it starts at login.

## Uninstall

```bash
make uninstall
```

## Limitations

- It detects *a* face, not *your* face. If someone else sits down, the Mac stays awake.
- Very dark rooms, looking far down, or sitting outside the camera frame can be missed. A miss only means macOS locks on its normal schedule.
- The green camera light blinks briefly on every check.
- The idle-timer reset happens every 20 seconds, so a screen saver set to start sooner than that can still kick in.

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md). Good first areas:

- A menu bar icon with pause / resume
- Configurable check interval without rebuilding
- Pausing automatically on battery below a threshold
- Optional "only my face" mode
- A signed and notarized release build
- Homebrew cask

## License

[MIT](LICENSE)
