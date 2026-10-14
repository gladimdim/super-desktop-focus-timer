import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "timer.js" as T

// The popup under the button: pick a length (5, 15, 25 min or your own) and
// an optional label, then Start (or Enter). While a timer runs it is shown
// at the top with a Stop button; starting another replaces it.
Rectangle {
    id: root
    color: sd.theme.background

    readonly property color textHint: T.soft(sd.theme, 0.45)
    readonly property color accentText: T.readable(sd.theme, ["accent", "blue", "cyan"], 4.5)
    readonly property color dangerText: T.readable(sd.theme, ["red", "orange", "magenta"], 4.5)

    readonly property var current: T.obj(sd.values.current)
    readonly property bool running: current !== null && current.endsAt > now

    property real now: Date.now()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = Date.now() }

    // The chosen preset (0 when the custom field is used).
    property real preset: {
        var last = Number(sd.value("lastMinutes", 25))
        return [5, 15, 25].indexOf(last) >= 0 ? last : 25
    }
    readonly property real customMinutes: T.parseMinutes(customField.text)
    readonly property bool usingCustom: customField.text.trim().length > 0
    readonly property real minutes: usingCustom ? customMinutes : preset
    property string error: ""

    function start() {
        if (isNaN(root.minutes) || root.minutes <= 0) {
            root.error = "Minutes: a number above 0, up to 1440 (or h:mm)."
            customField.forceActiveFocus()
            return
        }
        var now = Date.now()
        sd.setValue("current", {
            label: labelField.text.trim(),
            minutes: root.minutes,
            startedAt: now,
            endsAt: now + Math.round(root.minutes * 60000)
        })
        sd.setValue("lastMinutes", root.minutes)
        if (sd.values.alert) sd.setValue("alert", null)
        sd.call("popup.close", { surface: sd.surfaceId })
    }

    function stop() {
        sd.setValue("current", null)
    }

    Component.onCompleted: labelField.forceActiveFocus()

    component Caption: Text {
        color: root.textHint
        font.family: sd.theme.fontFamily
        font.pixelSize: 11
        font.letterSpacing: 0.5
    }
    component Preset: Button {
        id: btn
        property real value: 0
        readonly property bool chosen: !root.usingCustom && root.preset === value
        text: value + " min"
        Layout.fillWidth: true
        padding: 6
        font.family: sd.theme.fontFamily
        font.pixelSize: 13
        font.bold: chosen
        onClicked: { root.preset = value; customField.text = ""; root.error = "" }
        background: Rectangle {
            radius: 8
            color: btn.chosen ? sd.theme.accent
                 : btn.hovered ? Qt.alpha(sd.theme.accent, 0.25) : sd.theme.surface
            border.color: btn.chosen ? sd.theme.accent : Qt.alpha(sd.theme.foreground, 0.2)
        }
        contentItem: Text {
            text: btn.text
            font: btn.font
            color: btn.chosen ? T.onColor(sd.theme, sd.theme.accent) : sd.theme.foreground
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        // The running timer, with Stop.
        Rectangle {
            visible: root.running
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            radius: 8
            color: Qt.alpha(root.accentText, 0.12)
            border.color: Qt.alpha(root.accentText, 0.4)
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 6
                spacing: 8
                TimerIcon {
                    Layout.preferredWidth: 16; Layout.preferredHeight: 16
                    color: root.accentText
                }
                Text {
                    Layout.fillWidth: true
                    text: root.current
                        ? T.clock((root.current.endsAt - root.now) / 1000) + " left"
                          + (root.current.label ? " · " + root.current.label : "")
                        : ""
                    color: sd.theme.foreground
                    font.family: sd.theme.fontFamily
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }
                Button {
                    text: "Stop"
                    font.family: sd.theme.fontFamily
                    onClicked: root.stop()
                }
            }
        }

        Text {
            text: root.running ? "Start another (replaces it)" : "Start a focus timer"
            color: sd.theme.foreground
            font.family: sd.theme.fontFamily
            font.pixelSize: 15
            font.bold: true
        }

        Caption { text: "LENGTH" }
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Preset { value: 5 }
            Preset { value: 15 }
            Preset { value: 25 }
            TextField {
                id: customField
                Layout.preferredWidth: 92
                placeholderText: "Custom"
                placeholderTextColor: root.textHint
                font.family: sd.theme.fontFamily
                horizontalAlignment: TextInput.AlignHCenter
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                onTextEdited: root.error = ""
                onAccepted: root.start()
            }
        }

        Caption { text: "LABEL (OPTIONAL)"; Layout.topMargin: 2 }
        TextField {
            id: labelField
            Layout.fillWidth: true
            placeholderText: "Write the report, deep work…"
            placeholderTextColor: root.textHint
            font.family: sd.theme.fontFamily
            maximumLength: 120
            onAccepted: root.start()
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                Layout.fillWidth: true
                text: root.error.length > 0 ? root.error
                    : isNaN(root.minutes) ? ""
                    : "Ends at " + T.timeText(new Date(root.now + root.minutes * 60000))
                color: root.error.length > 0 ? root.dangerText : root.textHint
                font.family: sd.theme.fontFamily
                font.pixelSize: 12
                wrapMode: Text.Wrap
            }
            Button {
                text: "Cancel"
                font.family: sd.theme.fontFamily
                onClicked: sd.call("popup.close", { surface: sd.surfaceId })
            }
            Button {
                id: startButton
                text: "Start " + (isNaN(root.minutes) ? "" : T.lengthText(root.minutes))
                font.family: sd.theme.fontFamily
                font.bold: true
                onClicked: root.start()
                background: Rectangle {
                    implicitWidth: 100; implicitHeight: 40
                    radius: 6
                    color: startButton.down ? Qt.darker(sd.theme.accent, 1.2)
                         : startButton.hovered ? Qt.lighter(sd.theme.accent, 1.15) : sd.theme.accent
                }
                contentItem: Text {
                    text: startButton.text
                    font: startButton.font
                    color: T.onColor(sd.theme, sd.theme.accent)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
