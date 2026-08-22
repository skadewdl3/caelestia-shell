<h1 align="center">Caelestia Shell — patched fork</h1>

<div align="center">

[Upstream shell](https://github.com/caelestia-dots/shell) · [Caelestia dots](https://github.com/caelestia-dots/caelestia) · [Fork releases](https://github.com/skadewdl3/caelestia-shell/releases)

</div>

This is an unofficial fork of [Caelestia Shell](https://github.com/caelestia-dots/shell) with a small set of extra tools and behaviour changes layered on top. Install the official Caelestia dots first, then use the scripts in this repository to switch only the shell to this checkout. That leaves the official installation available as a known-good backup and keeps the CLI, Hyprland integration, themes, configuration tools, and other Caelestia goodies in place.

For standard installation, configuration, shortcuts, IPC, wallpaper, and troubleshooting documentation, use the [upstream Caelestia Shell README](https://github.com/caelestia-dots/shell#readme). This README only covers what this fork changes.

## What's added

- **Clipboard manager** — search text and image history from the launcher with `>clip`, see image previews, pin frequently used entries with <kbd>Ctrl</kbd>+<kbd>P</kbd>, and remove entries with <kbd>Shift</kbd>+<kbd>Delete</kbd>. Selecting an entry copies it back to the clipboard.
- **Emoji picker** — search emoji and glyph descriptions with `>emoji`. Selecting a result copies it and frequently used entries are promoted automatically.
- **Dedicated shortcuts** — the `clipboard` and `emoji` Caelestia global shortcuts open their respective launcher modes directly.
- **Integrated screenshot editor** — screenshots open in a themed Swappy editing interface instead of dropping directly into an external window.
- **greetd greeter** — an optional, isolated Caelestia login screen with Cage and UWSM integration.
- **Safer themed icons** — launcher icons are loaded synchronously to avoid unreliable themed application icons.
- **Simpler recording access** — the recording card opens the recordings directory directly.
- **Upstream release rebases** — the fork is automatically rebased onto new upstream releases; see [MAINTAINING.md](MAINTAINING.md) for the maintainer workflow.

The launcher prefix defaults to `>`. If you changed `launcher.actionPrefix`, use that value instead.

The full dots do not bind the fork's new shortcuts automatically. Add bindings like these to your Hyprland configuration if you want direct access:

```ini
bind = SUPER, V, global, caelestia:clipboard
bind = SUPER, period, global, caelestia:emoji
```

## Install the official Caelestia setup first

Follow the [official Caelestia installation instructions](https://github.com/caelestia-dots/caelestia#installation) and make sure the stock shell starts successfully before switching to this fork. In particular, these commands must work:

```sh
caelestia shell -d
qs --version
```

Starting from a working official installation is intentional: `switch.sh` reuses its Caelestia CLI and runtime integration, saves its shell configuration, and gives `unswitch.sh` something known-good to restore if this fork breaks.

## Switch to this fork

Install the local build tools and fork-specific runtime dependencies first:

- `git`
- `cmake`
- `ninja`
- `cliphist`
- `wl-clipboard`
- `swappy`

On Arch Linux, they can be installed with:

```sh
sudo pacman -S --needed git cmake ninja cliphist wl-clipboard swappy
```

Clone this repository somewhere outside `~/.config/quickshell/caelestia`. The following location keeps source checkouts separate from active configuration:

```sh
mkdir -p ~/.local/src
git clone https://github.com/skadewdl3/caelestia-shell.git ~/.local/src/caelestia-shell
cd ~/.local/src/caelestia-shell
./switch.sh
```

> [!IMPORTANT]
> Do not clone the fork directly over `~/.config/quickshell/caelestia`. That path is managed by the switch scripts so the official configuration can be backed up and restored safely.

`switch.sh`:

1. builds the fork's native plugin under `build/local`;
2. saves the current Caelestia Quickshell configuration under `${XDG_STATE_HOME:-$HOME/.local/state}/caelestia-shell-switch`;
3. links this checkout at `${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/caelestia`;
4. installs a user-local `caelestia` wrapper in `${XDG_BIN_HOME:-$HOME/.local/bin}` while preserving any existing file there; and
5. restarts the shell using the fork.

The script refuses to overwrite an existing backup or a launcher it does not own. It does not uninstall or modify the system Caelestia package.

Make sure `~/.local/bin` appears before `/usr/bin` in `PATH` so future `caelestia` commands and login autostarts use the wrapper:

```sh
command -v caelestia
```

After switching, this should normally print `$HOME/.local/bin/caelestia`.

## Update the fork

Upstream release updates rewrite the fork's patch-stack history, so a normal `git pull` may eventually report that `main` has diverged. Fetch the latest tested revision directly and rerun the switch script:

```sh
cd ~/.local/src/caelestia-shell
git fetch origin
git switch --detach origin/main
./switch.sh
```

Detached mode is intentional here: it follows the current fork without resetting or deleting your local branches. Git will refuse to switch if doing so would overwrite uncommitted changes. Because upstream updates are rebased into this fork, put personal work on a separate branch if you want to carry additional patches.

## Restore the official shell

Run the rollback script from the same checkout:

```sh
cd ~/.local/src/caelestia-shell
./unswitch.sh
```

This stops the fork, restores the saved official Quickshell configuration and user-local launcher, and starts the system Caelestia shell again. The downloaded repository and local build cache remain in place, so switching back later is quick.

`unswitch.sh` also refuses to replace the active configuration or launcher if they no longer match the files created by `switch.sh`. Resolve those changes manually instead of deleting the saved state directory.

## Optional greetd greeter

This fork also ships a separate Caelestia greeter for [`greetd`](https://sr.ht/~kennylevinsen/greetd/). It is a dedicated Quickshell entry point and does not start the authenticated desktop shell or load user-session services before login.

> [!IMPORTANT]
> `switch.sh` does not install or configure the greeter. A display manager is system-level configuration: keep access to another VT and a working recovery path while setting it up.

The default CMake build includes the greeter. On Nix, use the `with-greeter` or `with-cli-and-greeter` package output. In addition to the normal Caelestia dependencies, the greeter needs:

- `greetd`;
- [Cage](https://github.com/cage-kiosk/cage);
- [UWSM](https://github.com/Vladimir-csp/uwsm); and
- a Quickshell build with `Quickshell.Services.Greetd`.

To build and install only the greeter from this checkout with CMake:

```sh
cmake -S . -B build/greeter -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DENABLE_MODULES=greeter
cmake --build build/greeter
sudo cmake --install build/greeter
```

After installing it:

1. Copy `/usr/share/caelestia-greeter/config.example` to `/etc/caelestia-greeter/config` and set `CAELESTIA_GREETER_USER` to the account that greetd should authenticate.
2. Review `/usr/share/caelestia-greeter/greetd-config.toml` and merge the relevant values into `/etc/greetd/config.toml`. Do not overwrite an existing display-manager configuration without reviewing it.
3. Create the isolated runtime directories:

   ```sh
   sudo systemd-tmpfiles --create caelestia-greeter.conf
   ```

4. Confirm that another VT is usable, then enable `greetd.service` according to your distribution's instructions.

The greeter uses the packaged wallpaper by default. Set `CAELESTIA_GREETER_BACKGROUND` in `/etc/caelestia-greeter/config` to a different system-readable image. It starts `hyprland.desktop` through UWSM by default; set `CAELESTIA_GREETER_SESSION_DESKTOP` to select another installed desktop entry.

Preview the greeter safely from the source checkout before changing the display manager:

```sh
cd ~/.local/src/caelestia-shell
CAELESTIA_GREETER_USER="$USER" qs -p ./greeter.qml
```

## Support and credits

Caelestia Shell is created and maintained by the [Caelestia project](https://github.com/caelestia-dots). Please support the upstream project and use its documentation for standard shell behaviour.

Report problems caused by the clipboard manager, emoji picker, greeter, screenshot editor, switch scripts, or other fork patches in [this fork's issue tracker](https://github.com/skadewdl3/caelestia-shell/issues). Reproduce an issue with the official shell before reporting it upstream.

This project remains licensed under [GPL-3.0](LICENSE).
