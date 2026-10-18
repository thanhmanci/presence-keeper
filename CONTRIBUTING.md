# Contributing

Thanks for helping out. PresenceKeeper aims to stay small, dependency-free, and light on memory and battery. Changes that keep it that way are the easiest to merge.

## Getting started

```bash
make build
open build/PresenceKeeper.app
```

To check that a face is being detected:

```bash
pmset -g assertions | grep PresenceKeeper
```

To measure memory and CPU:

```bash
ps -o rss=,%cpu= -p $(pgrep -x PresenceKeeper)
```

Each rebuild is ad-hoc signed, so macOS may ask for camera access again.

## Guidelines

- No third-party dependencies. Apple frameworks only.
- Prefer clear names over code comments.
- Report memory and CPU before and after any change that touches the capture or detection path.
- Keep pull requests focused on one change.

## Reporting bugs

Open an issue with your macOS version, Mac model, camera (built-in or external), and what you expected versus what happened.
