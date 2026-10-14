import QtQuick
import "timer.js" as T

// The top-bar button. Idle: a stopwatch and "Focus". Running: the time left
// and a thin progress line. Finished: it flashes until clicked.
// Left click: the start popup. Right click: the history popup.
// It also owns the clock: this surface keeps running while SUPER DESKTOP is
// hidden, so it is the one that notices a timer ending, saves it to the
// history, notifies and plays the sound.
Rectangle {
    id: root
    radius: height / 2

    readonly property var current: T.obj(sd.values.current)
    readonly property var alert: T.obj(sd.values.alert)
    readonly property bool running: current !== null && current.endsAt > 0
    readonly property bool alerting: alert !== null

    property real now: Date.now()
    readonly property real secsLeft: running ? Math.max(0, (current.endsAt - now) / 1000) : 0
    readonly property real progress: running && current.minutes > 0
        ? Math.min(1, Math.max(0, 1 - secsLeft / (current.minutes * 60))) : 0

    // Whether SUPER DESKTOP is on screen: the flashing runs only then.
    property bool shown: true
    Connections {
        target: sd
        function onVisibleChanged(visible) { root.shown = visible }
    }

    readonly property color flashColor: {
        var names = ["red", "orange", "magenta", "accent"]
        for (var i = 0; i < names.length; i++) {
            var c = sd.theme[names[i]]
            if (c && T.contrast(c, sd.theme.background) >= 3) return c
        }
        return sd.theme.accent
    }
    readonly property color accentText: T.readable(sd.theme, ["accent", "blue", "cyan"], 3)
    property bool flashOn: true

    readonly property color fill: alerting ? (flashOn ? flashColor : Qt.alpha(sd.theme.surface, 0.9))
                                : area.containsMouse ? sd.theme.accent
                                : Qt.alpha(sd.theme.surface, 0.9)
    readonly property color ink: alerting ? (flashOn ? T.onColor(sd.theme, flashColor) : flashColor)
                               : area.containsMouse ? T.onColor(sd.theme, sd.theme.accent)
                               : running ? accentText
                               : sd.theme.foreground
    color: fill
    border.width: alerting ? 1 : 0
    border.color: flashColor

    Timer {
        interval: 1000; repeat: true; triggeredOnStart: true
        running: root.running
        onTriggered: {
            root.now = Date.now()
            if (root.current && root.current.endsAt <= root.now) root.finish()
        }
    }
    Timer {
        interval: 500; repeat: true
        running: root.alerting && root.shown
        onTriggered: root.flashOn = !root.flashOn
        onRunningChanged: root.flashOn = true
    }

    function finish() {
        if (!sd.connected) return          // check / snapshot: no side effects
        var c = root.current
        if (!c) return
        var entry = { id: T.newId(), label: c.label || "", minutes: c.minutes, finishedAt: c.endsAt }
        var hist = T.history(sd.values)
        hist.push(entry)
        while (hist.length > 200) hist.shift()
        sd.setValue("history", hist)
        sd.setValue("alert", { label: entry.label, minutes: entry.minutes, finishedAt: entry.finishedAt })
        sd.setValue("current", null)

        var title = "⏱ Timer finished"
        var body = (entry.label ? entry.label + " · " : "") + T.lengthText(entry.minutes)
        // Stays until dismissed; a click on it brings up the history.
        sd.call("notify", { title: title, body: body, urgency: "critical",
                            actions: [{ id: "default", label: "Show" }] }, function(result, err) {
            if (result && result.action === "default")
                sd.call("overlay.show", {}, function() { sd.call("popup.open", { surface: "history" }) })
        })
        // The sound only when it ended just now (not after hours with
        // SUPER DESKTOP closed).
        if (Date.now() - entry.finishedAt < 5 * 60000) root.ding()
    }

    // The desktop's alarm sound (else "complete"); SUPER DESKTOP picks the player.
    function ding() {
        sd.call("sound.play", { name: "alarm-clock-elapsed" }, function(result, err) {
            if (err) sd.call("sound.play", { name: "complete" })
        })
    }

    function acknowledge() { sd.setValue("alert", null) }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: Math.round(root.height * 0.15)
        TimerIcon {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(root.height * 0.5); height: width
            color: root.ink
        }
        Text {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            text: root.alerting ? "Done!" : root.running ? T.clock(root.secsLeft) : "Focus"
            color: root.ink
            font.family: sd.theme.fontFamily
            font.pixelSize: Math.max(10, root.height * 0.42)
            font.bold: root.running || root.alerting
            font.features: { "tnum": 1 }
        }
    }

    // How far the running timer has got.
    Rectangle {
        visible: root.running && !area.containsMouse
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.max(2, root.height * 0.1)
        x: root.radius * 0.6
        height: 2
        radius: 1
        width: (root.width - 2 * x) * root.progress
        color: root.accentText
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (root.alerting) {
                // A click stops the flashing; right click also shows the history.
                root.acknowledge()
                if (mouse.button === Qt.RightButton) sd.call("popup.open", { surface: "history" })
                return
            }
            sd.call("popup.toggle", { surface: mouse.button === Qt.RightButton ? "history" : "start" })
        }
    }
}
