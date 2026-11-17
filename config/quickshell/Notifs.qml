import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: win
    visible: server.trackedNotifications.values.length > 0
    anchors { top: true; right: true }
    margins { top: Config.sideMargin + (Config.barPosition === "top" ? Config.sideWidth + Config.sideMargin : 0); right: Config.sideMargin + 4 + (Config.barPosition === "right" ? Config.sideWidth + Config.sideMargin : 0) }
    implicitWidth: 380
    implicitHeight: Math.max(1, col.implicitHeight)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-notif"

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        imageSupported: true
        actionsSupported: true
        onNotification: (n) => { n.tracked = true }
    }

    ColumnLayout {
        id: col
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 10

        Repeater {
            model: server.trackedNotifications

            Rectangle {
                id: card
                required property var modelData
                property bool leaving: false
                property bool byUser: false
                property real appear: 0
                readonly property bool critical: modelData.urgency === NotificationUrgency.Critical
                readonly property string iconSrc: {
                    const img = modelData.image
                    if (img) return img
                    const ic = modelData.appIcon
                    if (!ic) return ""
                    if (ic.startsWith("/")) return "file://" + ic
                    return Quickshell.iconPath(ic, true)
                }

                Layout.fillWidth: true
                implicitHeight: content.implicitHeight + 24
                radius: 22
                color: Pal.a(Pal.bg, 0.96)
                border.width: 1
                border.color: critical ? "#ff6b5e" : Pal.a(Pal.accent, 0.55)
                opacity: leaving ? 0 : appear
                transform: Translate { x: (1 - card.appear) * 40 }
                NumberAnimation on appear { from: 0; to: 1; duration: 320; easing.type: Easing.OutCubic }
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Timer {
                    interval: card.modelData.expireTimeout > 0 ? Math.min(card.modelData.expireTimeout * 1000, 15000) : 6000
                    running: !card.critical && !card.leaving && !ma.containsMouse
                    onTriggered: card.leaving = true
                }
                Timer {
                    id: gone
                    interval: 260
                    onTriggered: card.byUser ? card.modelData.dismiss() : card.modelData.expire()
                }
                onLeavingChanged: if (leaving) gone.start()

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: { card.byUser = true; card.leaving = true }
                }

                RowLayout {
                    id: content
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 12
                    spacing: 12

                    Item {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        Layout.alignment: Qt.AlignTop
                        Image {
                            id: pic
                            anchors.fill: parent
                            source: card.iconSrc
                            sourceSize.width: 88
                            sourceSize.height: 88
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: pic.status !== Image.Ready
                            text: "\uf0f3"
                            color: Pal.accent
                            font.family: Config.font
                            font.pixelSize: 24
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: card.modelData.appName
                                color: Pal.dim
                                font.family: Config.font
                                font.pixelSize: 10
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Text {
                                text: "\uf00d"
                                color: Pal.dim
                                font.family: Config.font
                                font.pixelSize: 12
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -8
                                    onClicked: { card.byUser = true; card.leaving = true }
                                }
                            }
                        }
                        Text {
                            text: card.modelData.summary
                            color: Pal.fg
                            font.family: Config.font
                            font.bold: true
                            font.pixelSize: 13
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                        Text {
                            visible: text !== ""
                            text: card.modelData.body
                            color: Pal.a(Pal.fg, 0.75)
                            font.family: Config.font
                            font.pixelSize: 12
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 4
                            spacing: 6
                            Repeater {
                                model: card.modelData.actions
                                Rectangle {
                                    required property var modelData
                                    implicitWidth: lbl.implicitWidth + 24
                                    implicitHeight: 28
                                    radius: 14
                                    color: abtn.containsMouse ? Pal.a(Pal.accent, 0.4) : Pal.a(Pal.accent, 0.2)
                                    Text {
                                        id: lbl
                                        anchors.centerIn: parent
                                        text: parent.modelData.text
                                        color: Pal.fg
                                        font.family: Config.font
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                    MouseArea {
                                        id: abtn
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: { parent.modelData.invoke(); card.byUser = true; card.leaving = true }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
