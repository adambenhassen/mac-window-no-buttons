# mac-window-no-buttons

Hides the native close, minimise and zoom buttons on every Vivaldi window on macOS.
For iTerm2, see [iTerm2](#iterm2).

## How it works

- `NoButtons.m` builds `libNoWindowButtons.dylib`. On load it hides each window's
  standard buttons and pins `-setHidden:` to `YES` on their classes, so AppKit and
  Chromium cannot show them again.
- Vivaldi's main executable has no header room for a new load command. `proxy_dylib.py`
  instead points its only dependency, `libSystem.B.dylib`, at the dylib, which
  re-exports libSystem.
- `patch.sh` re-signs the bundle ad hoc without hardened runtime, so library validation
  no longer rejects the unsigned dylib. The framework and helpers keep Vivaldi's signature.
- `vivaldi-css/no-button-space.css` removes the gap Vivaldi reserves for the buttons and
  the flexible spacer after the new-tab button, so tabs use both ends. Select the `vivaldi-css` folder in Settings → Appearance → Custom UI Modifications.

## Use

```sh
./install.sh      # Vivaldi must be quit; run again after every Vivaldi update
./uninstall.sh    # restores the original app
```

## Side effects

- macOS asks once for keychain access to "Vivaldi Safe Storage". Choose Always Allow,
  or saved passwords and cookies do not decrypt.
- Passkeys stored in Vivaldi's team keychain groups stop working (restricted
  entitlements are dropped).
- Camera, microphone and other privacy prompts appear again.
- Updates replace the patched app.

## iTerm2

iTerm2 needs no patch; its built-in settings remove the buttons.

1. Settings → Profiles → Window → Style: **No Title Bar** (for every profile).
   The window has no close, minimise or zoom buttons.
2. Settings → Advanced → **Tabs: Default tab bar height** = `38`. No Title Bar windows
   use this height; 38 matches the Minimal theme's compact tab bar.

Both apply to new windows only. These windows have no title bar to drag by.
