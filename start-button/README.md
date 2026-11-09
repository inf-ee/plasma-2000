# Win2000 Start button

Plasma's Kickoff draws its panel button flat (icon + text, no frame), and no
Plasma style can change that. This folder builds **Start Menu (Plasma 2000)**
(`io.github.inf_ee.plasma2000.start`): an unmodified copy of Kickoff for your Plasma
version, except that the panel button is a raised Win2000-style button with a
16px icon and bold "Start", drawn sunken while the menu is open. The menu
itself is stock Kickoff.

The built-in Kickoff is not touched.

## Files

- `build.sh`: downloads Kickoff's QML for the installed Plasma version from
  invent.kde.org (the release tag, e.g. `v6.6.6`, or else the `Plasma/6.6`
  branch), applies `patch_main.py`, installs to
  `~/.local/share/plasma/plasmoids/io.github.inf_ee.plasma2000.start/`.
  Needs `curl`, `python3` and a network connection.
- `patch_main.py`: the only changes (button bevel, icon size, bold label). Each
  edit must match upstream exactly once, and the names the new code uses must
  still exist, so if KDE changes the file the build stops with an error instead
  of producing something broken.
- `use.sh`: swaps the panel's Kickoff for this widget, keeping its id, position,
  settings and favourites (restarts plasmashell for a moment).
  `./use.sh --revert` swaps back to stock Kickoff. Refuses to swap in a widget
  that isn't built yet.
- `uninstall.sh`: swaps back to stock Kickoff and removes the widget.

## After a Plasma upgrade

    start-button/build.sh

then log out and in (or `systemctl --user restart plasma-plasmashell`).
If `build.sh` stops at `patch_main.py`, upstream changed the button code; run
`./use.sh --revert` until the patch is updated.

## Notes

- The button colours follow the colour scheme's button background, with
  white / darker shades for the 3D edges, so it matches when switching from the
  WinME to a Win2000 scheme.
- The label comes from the widget's settings (right-click → Configure → Text label).
- Bugs in this copy belong to Plasma 2000, not KDE: its "Report a bug" link
  points to this project.
- Translations aren't loaded for the copy (it has a different id), so menu text
  is English.
