// SPDX-FileCopyrightText: Die4Ever
// SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
// SPDX-License-Identifier: GPL-3.0-or-later
//
// Windows 2000 taskbar: Start, Minimize All, task buttons, sunken tray box, tray, clock.
// Based on the layout script of Die4Ever's Reactionary ME. Uses the Plasma 2000
// Start button and tray box when they are installed, stock widgets otherwise.

var known = knownWidgetTypes;
function have(id) { return known.indexOf(id) !== -1; }

var panel = new Panel;
panel.location = "bottom";
panel.height = 2 * gridUnit;
panel.floating = false;
panel.alignment = "center";

var start = panel.addWidget(have("io.github.inf_ee.plasma2000.start") ? "io.github.inf_ee.plasma2000.start" : "org.kde.plasma.kickoff");
start.currentConfigGroup = ["Shortcuts"];
start.writeConfig("global", "Alt+F1");
start.currentConfigGroup = ["General"];
start.writeConfig("menuLabel", "Start");
start.writeConfig("favoritesDisplay", "1");

// minimizes windows for real, so clicking a task button restores just that one
panel.addWidget(have("org.kde.plasma.minimizeall") ? "org.kde.plasma.minimizeall" : "org.kde.plasma.showdesktop");

var tasks = panel.addWidget("org.kde.plasma.taskmanager");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", ["preferred://browser", "preferred://filemanager", "applications:org.kde.konsole.desktop"]);
tasks.writeConfig("onlyGroupWhenFull", true);
tasks.writeConfig("groupedTaskVisualization", "2");
tasks.writeConfig("hideLauncherOnStart", "false");
tasks.writeConfig("taskHoverEffect", false);

// input method widget for languages that usually need one (list from Plasma's default layout)
var langIds = ["as", "bn", "bo", "brx", "doi", "gu", "hi", "ja", "kn", "ko", "kok", "ks", "lep", "mai",
               "ml", "mni", "mr", "ne", "or", "pa", "sa", "sat", "sd", "si", "ta", "te", "th", "ur",
               "vi", "zh_CN", "zh_TW"];
if (langIds.indexOf(languageId) !== -1) {
    panel.addWidget("org.kde.plasma.kimpanel");
}

if (have("io.github.inf_ee.plasma2000.trayframe")) {
    panel.addWidget("io.github.inf_ee.plasma2000.trayframe");
}
panel.addWidget("org.kde.plasma.systemtray");
var clock = panel.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", false);

// Windows 2000 desktop colour
for (var i = 0; i < screenCount; ++i) {
    var desk = desktopForScreen(i);
    desk.wallpaperPlugin = "org.kde.color";
    desk.currentConfigGroup = ["General"];
    desk.writeConfig("toolTips", "true");
    desk.writeConfig("previews", "false");
    desk.writeConfig("arrangement", "1");
    desk.currentConfigGroup = ["Wallpaper", "org.kde.color", "General"];
    desk.writeConfig("Color", "#3a6ea5");
}
