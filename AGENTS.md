# SUPER DESKTOP plugin: Focus timer

This folder is a SUPER DESKTOP plugin (QML). SUPER DESKTOP reloads it on
screen every time a file here is saved.

Before changing anything, read `.claude/skills/super-desktop-plugin/SKILL.md`
and follow its loop:

1. edit the QML or plugin.json;
2. `super-desktop plugin check focus-timer --json` and fix every error and warning;
3. `super-desktop plugin snapshot focus-timer --out /tmp/focus-timer.png --json` (add
   `--surface <id>` for each surface), then open the PNG and look at it;
4. `super-desktop plugin logs focus-timer` for runtime errors.

Keep the plugin id `focus-timer` (it must equal the folder name). You may change
the slots, add surfaces and files, and rewrite the starting QML entirely.

## What it does

A timer in the top bar (`Toolbar.qml`, surface `main`). Left click opens the
`start` popup (`StartPopup.qml`: 5, 15, 25 min or a custom length such as
`40`, `7.5` or `1:30`, an optional label, Start or Enter; a running timer is
shown on top with Stop). Right click opens the `history` popup
(`HistoryPopup.qml`: finished timers, newest first; click one to remove it).

Saved values, described at the top of `timer.js`: `current` (the running
timer), `alert` (finished, not clicked yet), `history`, `lastMinutes`. The
top-bar item keeps running while SUPER DESKTOP is hidden, so it notices the
end: it appends to `history`, sets `alert`, notifies and plays the
freedesktop alarm sound (only when the timer ended in the last 5 minutes),
then flashes while SUPER DESKTOP is on screen until clicked. `timer.js` also
picks text colors that stay readable in every Omarchy theme.

Needs SUPER DESKTOP 1.6.0 or newer (the `popup` slot and `tooltip`).
