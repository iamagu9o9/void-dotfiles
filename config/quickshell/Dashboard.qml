import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: win
    property bool isOpen: false
    property string mStatus: ""
    property string mArtist: ""
    property string mTitle: ""
    property real mPosition: 0
    property real mLength: 0

    visible: isOpen || card.opacity > 0.01
    color: "transparent"
    implicitWidth: 560
    implicitHeight: col.implicitHeight + 48
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "qs-menu"

    IpcHandler {
        target: "dashboard"
        function toggle(): void { win.isOpen = !win.isOpen }
        function open(): void { win.isOpen = true }
        function close(): void { win.isOpen = false }
    }
    HyprlandFocusGrab { windows: [win]; active: win.isOpen; onCleared: win.isOpen = false }
    onIsOpenChanged: { if (isOpen) { Sys.refresh(); keys.forceActiveFocus(); media.running = true } }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Process {
        id: media
        command: ["bash", "-c", "playerctl metadata --format '{{status}}|{{artist}}|{{title}}|{{position}}|{{mpris:length}}' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split("|")
                win.mStatus = p[0] || ""
                win.mArtist = p[1] || ""
                win.mTitle = p.slice(2, -2).join("|") || p[2] || ""
                win.mPosition = parseFloat(p[p.length - 2]) || 0
                win.mLength = parseFloat(p[p.length - 1]) || 0
            }
        }
    }
    Timer { interval: 1500; running: win.isOpen; repeat: true; triggeredOnStart: true; onTriggered: media.running = true }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 32
        color: Pal.a(Pal.bg, 0.96)
        border.width: 1.5
        border.color: Pal.a(Pal.accent, 0.5)
        opacity: win.isOpen ? 1 : 0
        scale: win.isOpen ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }

        Item { id: keys; anchors.fill: parent; Keys.onEscapePressed: win.isOpen = false }

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            // ----- header -----
            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    spacing: 2
                    Text {
                        text: {
                            const hr = new Date().getHours();
                            const greet = hr < 12 ? "Good morning" : hr < 18 ? "Good afternoon" : "Good evening";
                            return greet + ", " + Quickshell.env("USER");
                        }
                        color: Pal.dim; font.family: Config.font; font.pixelSize: 13; font.bold: true
                    }
                    Text {
                        text: Qt.formatDateTime(clock.date, Config.clock24 ? "HH:mm" : "hh:mm AP")
                        color: Pal.fg; font.family: Config.font; font.pixelSize: 44; font.bold: true
                    }
                }
                Item { Layout.fillWidth: true }
                ColumnLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: 2
                    Text {
                        text: Qt.formatDateTime(clock.date, "dddd")
                        horizontalAlignment: Text.AlignRight
                        color: Pal.accent; font.family: Config.font; font.pixelSize: 15; font.bold: true
                        Layout.alignment: Qt.AlignRight
                    }
                    Text {
                        text: Qt.formatDateTime(clock.date, "d MMMM")
                        horizontalAlignment: Text.AlignRight
                        color: Pal.dim; font.family: Config.font; font.pixelSize: 13
                        Layout.alignment: Qt.AlignRight
                    }
                }
            }

            // ----- toggles -----
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                DTile {
                    Layout.fillWidth: true
                    icon: "\uf1eb"; label: "Wi-Fi"; active: Sys.wifiOn
                    onClicked: Sys.run("nmcli radio wifi " + (Sys.wifiOn ? "off" : "on"))
                }
                DTile {
                    Layout.fillWidth: true
                    icon: "\uf293"; label: "Bluetooth"; active: Sys.btOn
                    onClicked: Sys.run(Sys.btOn ? "bluetoothctl power off" : "rfkill unblock bluetooth; bluetoothctl power on")
                }
                DTile {
                    Layout.fillWidth: true
                    icon: "\uf026"; label: "Mute"; active: Sys.muted
                    onClicked: Sys.run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
                }
                DTile {
                    Layout.fillWidth: true
                    icon: "\uf186"; label: "Night"; active: Sys.night
                    onClicked: Sys.run(Sys.night ? "pkill hyprsunset" : Config.nightCmd)
                }
            }

            // ----- sliders -----
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                DSlide {
                    icon: "\uf028"; value: Sys.vol
                    onLive: (v) => Sys.vol = v
                    onCommit: (v) => Sys.run("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + v + "%")
                }
                DSlide {
                    icon: "\uf185"; value: Sys.bri
                    onLive: (v) => Sys.bri = v
                    onCommit: (v) => Sys.run("brightnessctl set " + Math.max(5, v) + "%")
                }
            }

            // ----- media card -----
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 80
                radius: 20
                color: Pal.a(Pal.fg, 0.05)
                border.width: 1
                border.color: Pal.a(Pal.fg, 0.1)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12
                    Text {
                        text: "\uf001"; color: Pal.accent; font.family: Config.font; font.pixelSize: 22
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            text: win.mTitle || "Nothing playing"
                            color: Pal.fg; font.family: Config.font; font.bold: true; font.pixelSize: 13
                            Layout.fillWidth: true; elide: Text.ElideRight
                        }
                        Text {
                            text: win.mArtist || "Enjoy the silence"
                            color: Pal.dim; font.family: Config.font; font.pixelSize: 11
                            Layout.fillWidth: true; elide: Text.ElideRight
                        }
                    }
                    RowLayout {
                        spacing: 4
                        SideIcon { icon: "\uf048"; onClicked: Sys.run("playerctl previous") }
                        SideIcon { icon: win.mStatus === "Playing" ? "\uf04c" : "\uf04b"; tint: Pal.accent; onClicked: Sys.run("playerctl play-pause") }
                        SideIcon { icon: "\uf051"; onClicked: Sys.run("playerctl next") }
                    }
                }
            }

            // ----- CLOCK SETTINGS CONTROLS PANEL -----
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 52
                radius: 16
                color: Pal.a(Pal.bg, 0.5)
                border.width: 1
                border.color: Pal.a(Pal.accent, 0.2)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16

                    Text {
                        text: "\uf017 Clock Style:"
                        color: Pal.dim; font.family: Config.font; font.pixelSize: 12; font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    // Toggle Analog vs Digital
                    SideIcon {
                        icon: Config.clockStyle === "analog" ? "\uf0ac" : "\uf017"
                        tint: Config.clockStyle === "analog" ? Pal.accent : Pal.fg
                        onClicked: Config.clockStyle = (Config.clockStyle === "analog" ? "digital" : "analog")
                    }
                    // Toggle 24h format
                    SideIcon {
                        icon: "\uf0ac" // 24h indicator icon substitute
                        tint: Config.clock24 ? Pal.accent2 : Pal.dim
                        onClicked: Config.clock24 = !Config.clock24
                    }
                    // Toggle Seconds
                    SideIcon {
                        icon: "\uf2f2"
                        tint: Config.clockSeconds ? Pal.c3 : Pal.dim
                        onClicked: Config.clockSeconds = !Config.clockSeconds
                    }
                }
            }

            // ----- gauges -----
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                    model: [
                        { g: "\uf2db", n: "CPU", v: Sys.cpu, t: 0 },
                        { g: "\uf1c0", n: "RAM", v: Sys.ram, t: 1 },
                        { g: "\uf0a0", n: "Disk", v: Sys.disk, t: 2 },
                        { g: "\uf240", n: "Batt", v: Sys.battery, t: 3 }
                    ]
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 70
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2
                            Ring {
                                Layout.preferredWidth: 46
                                Layout.preferredHeight: 46
                                Layout.alignment: Qt.AlignHCenter
                                icon: modelData.g
                                value: modelData.v
                                tint: modelData.t === 0 ? Pal.accent : (modelData.t === 1 ? Pal.accent2 : (modelData.t === 2 ? Pal.c3 : Pal.c2))
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.v + "%"
                                color: Pal.dim; font.family: Config.font; font.pixelSize: 10
                            }
                        }
                    }
                }
            }
        }
    }
}
