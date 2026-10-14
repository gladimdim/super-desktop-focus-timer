import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "timer.js" as T

// The right-click popup: finished timers, newest first (label, length, when
// it finished). Clicking one removes it.
Rectangle {
    id: root
    color: sd.theme.background

    readonly property color textSoft: T.soft(sd.theme, 0.3)
    readonly property color textHint: T.soft(sd.theme, 0.45)
    readonly property color accentText: T.readable(sd.theme, ["accent", "blue", "cyan"], 4.5)
    readonly property color dangerText: T.readable(sd.theme, ["red", "orange", "magenta"], 4.5)

    readonly property var entries: T.history(sd.values).sort(function(a, b) { return b.finishedAt - a.finishedAt })
    readonly property real totalMinutes: entries.reduce(function(s, e) { return s + (Number(e.minutes) || 0) }, 0)

    function remove(id) {
        sd.setValue("history", T.history(sd.values).filter(function(e) { return e.id !== id }))
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.topMargin: 4
            Text {
                Layout.fillWidth: true
                text: root.entries.length === 0 ? "Finished timers" : "Finished timers · click to remove"
                color: root.textHint
                font.family: sd.theme.fontFamily
                font.pixelSize: 11
                elide: Text.ElideRight
            }
            Text {
                visible: root.entries.length > 0
                text: T.lengthText(root.totalMinutes)
                color: root.accentText
                font.family: sd.theme.fontFamily
                font.pixelSize: 11
            }
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            model: root.entries
            ScrollBar.vertical: ScrollBar {}

            // Empty state (children of a ListView live in its content item:
            // placed by hand).
            ColumnLayout {
                visible: root.entries.length === 0
                x: (listView.width - width) / 2
                y: (listView.height - height) / 2
                spacing: 8
                TimerIcon {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 32; Layout.preferredHeight: 32
                    color: root.textHint
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No finished timers yet.\nClick the timer to start one."
                    horizontalAlignment: Text.AlignHCenter
                    color: root.textSoft
                    font.family: sd.theme.fontFamily
                    font.pixelSize: 12
                }
            }

            delegate: Rectangle {
                id: row
                required property var modelData
                width: listView.width
                height: content.implicitHeight + 12
                radius: 8
                color: rowArea.containsMouse ? Qt.alpha(root.dangerText, 0.18) : "transparent"

                RowLayout {
                    id: content
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    TimerIcon {
                        Layout.preferredWidth: 14
                        Layout.preferredHeight: 14
                        Layout.alignment: Qt.AlignTop
                        Layout.topMargin: 2
                        color: root.accentText
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            Layout.fillWidth: true
                            text: row.modelData.label || "Focus timer"
                            color: row.modelData.label ? sd.theme.foreground : root.textSoft
                            font.family: sd.theme.fontFamily
                            font.pixelSize: 13
                            font.italic: !row.modelData.label
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: T.lengthText(row.modelData.minutes) + " · finished " + T.whenText(row.modelData.finishedAt)
                            color: root.textSoft
                            font.family: sd.theme.fontFamily
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }
                    Text {
                        text: "✕"
                        opacity: rowArea.containsMouse ? 1 : 0
                        color: root.dangerText
                        font.pixelSize: 13
                    }
                }
                MouseArea {
                    id: rowArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.remove(row.modelData.id)
                }
            }
        }
    }
}
