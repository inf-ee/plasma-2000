# Test checklist

Run on a fresh virtual machine per distribution family (Kubuntu or KDE neon,
Fedora KDE, Arch or EndeavourOS, openSUSE Tumbleweed), with disk encryption,
at 100% and 150% scaling, and once with two monitors.

1. `sh lib/detect.sh` and `sh lib/branding.sh`: family, paths, name and logo look right.
2. Install SE98C and ModernXP from the KDE Store, then `./install.sh --layout`:
   - taskbar: Start (raised, sunken while open), Minimize All, task buttons, sunken tray box, clock
   - no blue strip under Start or Minimize All while active
   - title bars grey with blue gradient; colours, icons, cursors applied
3. Win+D minimizes all; clicking one task button restores only that window.
4. Lock (Meta+L): "Unlock Computer", distro name + logo, wrong password box, unlock works.
5. Log out / Restart from the Start menu: "Shut Down <name>" dialog, 30 s auto-action.
6. `sudo ./sddm/install.sh`, log out: "Log On to <name>", wrong password box, Shutdown... dialog.
7. `sudo ./plymouth/install.sh`, reboot: boot screen with name + logo, disk password
   dialog with the keys icon, progress bar; shutdown/restart labels; both monitors.
8. After login: "Loading / Applying your personal settings..." splash.
9. `./uninstall.sh` and both sudo uninstallers: colour scheme, panel style, global theme,
   title bars, wallpaper, login and boot screen are what they were before step 2;
   Win+D, clock date and task button highlight are Plasma's defaults.
10. Offline: `./install.sh` still installs everything except the Start button.
