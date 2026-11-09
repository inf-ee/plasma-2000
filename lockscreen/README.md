# Windows 2000 lock screen for KDE Plasma 6

"Unlock Computer" dialog on the Win2000 desktop blue: banner, "This computer is
in use and has been locked", user name, password, OK / Cancel / Options >>
(Sleep / Hibernate / Switch User / Keyboard), a "Unlock Computer" warning box for wrong
passwords, and a small keyboard layout indicator in the bottom right corner.

It only replaces the **lock screen**; the login screen is in `../sddm/`.

## Install

    ./install.sh

This creates `~/.local/share/plasma/shells/org.kde.plasma.desktop/`, a copy of
the desktop shell where everything links to the system files except
`contents/lockscreen/` (copied from `qml/`). Plasma looks in `~/.local/share`
first. The shell is read at login, so log out and back in once.

## Test

`./install.sh` prints the preview command for your distribution, for example
`/usr/lib/x86_64-linux-gnu/libexec/kscreenlocker_greet --testing` (Debian, Ubuntu)
or `/usr/libexec/kscreenlocker_greet --testing` (Fedora, Arch, openSUSE).
It opens full screen; type your password or kill it. Then lock for real with
Meta+L and try a wrong password, then the right one.

## Uninstall

    ./uninstall.sh

## If something goes wrong

- If the QML fails to load, Plasma falls back to a basic built-in lock screen,
  so a broken theme can't lock you out.
- Stuck anyway: Ctrl+Alt+F3, log in, run `loginctl unlock-session`.
- Edits not showing up: `rm -rf ~/.cache/kscreenlocker_greet/qmlcache`

## Files (`qml/`)

| File | Purpose |
|---|---|
| `LockScreenUi.qml` | Main screen and all unlock logic (adapted from Plasma's stock file) |
| `Classic.qml` | Win2000 palette and font (singleton) |
| `ClassicWindow.qml`, `ClassicButton.qml`, `ClassicLabel.qml`, `ClassicTextField.qml`, `Bevel.qml`, `Banner.qml` | Win2000 widgets, shared with the login and logout themes |
| `SysIcon.qml` | Shows the icons the installer copies from SE98C into `icons/` |
| `branding.js` | Distribution name and logo, written by the installer |
| `LockScreen.qml`, `LockOsd.qml`, `PasswordSync.qml`, `config.*` | Unchanged stock files (`config.*` is the settings page in System Settings; its clock and media control options have no effect on this lock screen) |
| `tahoma.ttf`, `tahomabd.ttf`, `COPYING.LIB-tahoma` | Wine's Tahoma clone, LGPL |

## Maintenance

After a big Plasma upgrade, compare
`/usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen/LockScreenUi.qml`
with the authentication parts of `qml/LockScreenUi.qml` (the
`Connections { target: authenticator }` block, `submit()`, the password field).

Not included vs. stock: media controls, battery indicator. The on-screen keyboard
(Options >> → Keyboard) uses KWin's virtual keyboard, so it is only offered on Wayland
with a virtual keyboard selected in System Settings → Keyboard → Virtual Keyboard; on X11
there is none, so a touch-only device needs a keyboard to unlock.
