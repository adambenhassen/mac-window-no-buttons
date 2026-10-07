# mac-window-no-buttons

Hides the native close, minimise and zoom buttons on every window of Vivaldi and
Visual Studio Code on macOS.
For iTerm2, see [iTerm2](#iterm2).

## How it works

- `NoButtons.m` builds `libNoWindowButtons.dylib`. On load it hides each window's
  standard buttons and pins `-setHidden:` to `YES` on their classes, so AppKit and
  Chromium cannot show them again.
- The apps' main executables have no header room for a new load command. `proxy_dylib.py`
  instead points their `libSystem.B.dylib` dependency at `@loader_path/libNoWindowButtons.dylib`,
  which re-exports libSystem.
- `patch.sh` re-signs the bundle ad hoc without hardened runtime, so library validation
  no longer rejects the unsigned dylib. Frameworks and helpers keep the vendor's signature.
- `vivaldi-css/no-button-space.css` removes the gap Vivaldi reserves for the buttons and
  the flexible spacer after the new-tab button, so tabs use both ends. Select the `vivaldi-css` folder in Settings → Appearance → Custom UI Modifications.

## Use

```sh
./install.sh                                        # Vivaldi (default)
./install.sh "/Applications/Visual Studio Code.app"
./uninstall.sh [app]                                # restores the original app
```

Quit the app first. Run `install.sh` again after every update of the app.

## Side effects

- macOS asks once for keychain access to "Vivaldi Safe Storage". Choose Always Allow,
  or saved passwords and cookies do not decrypt.
- Passkeys stored in Vivaldi's team keychain groups stop working (restricted
  entitlements are dropped).
- Camera, microphone and other privacy prompts appear again.
- Updates replace the patched app.
- VS Code's updater rejects updates for the re-signed app. To update: `uninstall.sh`,
  update VS Code, `install.sh`. VS Code asks once for "Code Safe Storage" keychain access.

## iTerm2

iTerm2 needs no patch; its built-in settings remove the buttons.

1. Settings → Profiles → Window → Style: **No Title Bar** (for every profile).
   The window has no close, minimise or zoom buttons.
2. Settings → Advanced → **Tabs: Default tab bar height** = `38`. No Title Bar windows
   use this height; 38 matches the Minimal theme's compact tab bar.

Both apply to new windows only. These windows have no title bar to drag by.
