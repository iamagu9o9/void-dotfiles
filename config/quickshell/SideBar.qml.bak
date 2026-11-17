import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            readonly property string pos: ["top", "bottom", "left", "right"].indexOf(Config.barPosition) >= 0 ? Config.barPosition : "top"
            readonly property bool vertical: pos === "left" || pos === "right"
            readonly property bool isTop: pos === "top"
            readonly property bool isBottom: pos === "bottom"
            readonly property bool isLeft: pos === "left"
            readonly property bool isRight: pos === "right"

            anchors {
                top: isTop || vertical
                bottom: isBottom || vertical
                left: isLeft || !vertical
                right: isRight || !vertical
            }
            margins {
                top: Config.sideMargin
                bottom: Config.sideMargin
                left: Config.sideMargin
                right: Config.sideMargin
            }
            implicitWidth: vertical ? Config.sideWidth : 0
            implicitHeight: vertical ? 0 : Config.sideWidth
            color: "transparent"
            WlrLayershell.namespace: "qs-bar"

            SystemClock { id: clock; precision: SystemClock.Minutes }

            Rectangle {
                id: pill
                anchors.fill: parent
                radius: Config.sideWidth / 2
                color: Config.barStyle === "glass" ? Pal.a(Pal.bg, 0.55)
                     : Config.barStyle === "neutral" ? Pal.a(Pal.light ? "#f4f4f4" : "#101010", Config.islandOpacity)
                     : (Config.barStyle === "outline" || Config.barStyle === "gradient") ? "transparent"
                     : Pal.a(Pal.bg, Config.islandOpacity)
                gradient: Config.barStyle === "gradient" ? barGrad : null
                border.width: Config.barStyle === "outline" ? 2 : Config.border
                border.color: Config.barStyle === "glass" ? Pal.a(Pal.fg, 0.16)
                            : Config.barStyle === "outline" ? Pal.a(Pal.accent, 0.8)
                            : Pal.a(Pal.accent, 0.5)

                Gradient {
                    id: barGrad
                    orientation: win.vertical ? Gradient.Vertical : Gradient.Horizontal
                    GradientStop { position: 0.0; color: Pal.a(Qt.tint(Pal.bg, Pal.a(Pal.accent, 0.28)), Config.islandOpacity) }
                    GradientStop { position: 1.0; color: Pal.a(Pal.bg, Config.islandOpacity) }
                }

                property real shift: (win.isLeft || win.isTop) ? -24 : 24
                transform: Translate {
                    x: win.vertical ? pill.shift : 0
                    y: win.vertical ? 0 : pill.shift
                }
                NumberAnimation on opacity { from: 0; to: 1; duration: 600; easing.type: Easing.OutCubic }
                NumberAnimation on shift { to: 0; duration: 600; easing.type: Easing.OutCubic }

                GridLayout {
                    id: grid
                    anchors.fill: parent
                    anchors.margins: 8
                    flow: win.vertical ? GridLayout.LeftToRight : GridLayout.TopToBottom
                    columns: win.vertical ? 1 : -1
                    rows: win.vertical ? -1 : 1
                    rowSpacing: 4
                    columnSpacing: 4

                    // ---------- logo: launcher ----------
                    SideIcon {
                        icon: "\uf30a"
                        tint: Pal.accent
                        onClicked: Sys.run(Config.launcher)
                    }

                    // ---------- background apps (tray) ----------
                    Repeater {
                        model: SystemTray.items

                        Item {
                            id: ti
                            required property var modelData
                            Layout.alignment: Qt.AlignCenter
                            Layout.preferredWidth: Config.iconSize
                            Layout.preferredHeight: Config.iconSize
                            scale: tma.pressed ? 0.88 : (tma.containsMouse ? 1.1 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }

                            Image {
                                anchors.centerIn: parent
                                width: Config.trayIcon
                                height: Config.trayIcon
                                source: ti.modelData.icon
                                sourceSize.width: Config.trayIcon * 2
                                sourceSize.height: Config.trayIcon * 2
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }
                            MouseArea {
                                id: tma
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                onClicked: (m) => {
                                    const menu = () => {
                                        const pt = ti.mapToItem(null, 0, 0)
                                        let x = pt.x, y = pt.y
                                        if (win.isLeft) { x = Config.sideWidth }
                                        else if (win.isRight) { x = -220 }
                                        else if (win.isTop) { y = Config.sideWidth }
                                        else { y = -260 }
                                        ti.modelData.display(win, x, y)
                                    }
                                    if (m.button === Qt.LeftButton) {
                                        if (ti.modelData.onlyMenu && ti.modelData.hasMenu) menu()
                                            else ti.modelData.activate()
                                    } else if (m.button === Qt.MiddleButton) {
                                        ti.modelData.secondaryActivate()
                                    } else if (ti.modelData.hasMenu) {
                                        menu()
                                    }
                                }
                            }
                        }
                    }

                    // ---------- volume + mic rings ----------
                    Ring {
                        icon: Sys.muted ? "\uf026" : "\uf028"
                        value: Sys.muted ? 0 : Sys.vol
                        tint: Pal.c3
                        onClicked: Sys.run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
                        onScrolled: (d) => Sys.run("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%" + (d > 0 ? "+" : "-"))
                    }
                    Ring {
                        icon: "\uf130"
                        value: Sys.micMuted ? 0 : Sys.mic
                        tint: Pal.accent2
                        onClicked: Sys.run("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")
                        onScrolled: (d) => Sys.run("wpctl set-volume -l 1 @DEFAULT_AUDIO_SOURCE@ 5%" + (d > 0 ? "+" : "-"))
                    }

                    // ---------- wifi, bluetooth, wallpapers, tools, windows ----------
                    SideIcon {
                        icon: "\uf025"
                        tint: Pal.accent2
                        onClicked: Sys.run("qs ipc call menu toggle audio")
                    }
                    SideIcon {
                        icon: "\uf1eb"
                        tint: Sys.wifiOn ? Pal.fg : Pal.dim
                        onClicked: Sys.run(Config.wifiMenu)
                    }
                    SideIcon {
                        icon: "\uf293"
                        tint: Sys.btOn ? Pal.accent2 : Pal.dim
                        onClicked: Sys.run(Config.btMenu)
                    }
                    SideIcon {
                        icon: "\uf03e"
                        tint: Pal.accent
                        onClicked: Sys.run("qs ipc call wallpapers toggle")
                    }
                    SideIcon {
                        icon: "\uf125"
                        tint: Pal.accent
                        onClicked: Sys.run(Config.toolsCmd)
                    }
                    SideIcon {
                        icon: "\uf2d0"
                        onClicked: Sys.run(Config.windowCmd)
                    }

                    Item { Layout.fillWidth: !win.vertical; Layout.fillHeight: win.vertical }

                    // ---------- workspaces ----------
                    GridLayout {
                        Layout.alignment: Qt.AlignCenter
                        flow: win.vertical ? GridLayout.LeftToRight : GridLayout.TopToBottom
                        columns: win.vertical ? 1 : -1
                        rows: win.vertical ? -1 : 1
                        rowSpacing: 2
                        columnSpacing: 2

                        Repeater {
                            model: Config.workspaces
                            Rectangle {
                                required property int index
                                property int wsId: index + 1
                                property bool active: Hyprland.focusedWorkspace !== null
                                && Hyprland.focusedWorkspace.id === wsId
                                Layout.alignment: Qt.AlignCenter
                                implicitWidth: win.vertical ? Config.iconSize - 6 : (active ? 44 : 26)
                                implicitHeight: win.vertical ? (active ? 42 : 26) : Config.iconSize - 6
                                radius: 8
                                color: active ? Pal.fg : "transparent"
                                Behavior on implicitWidth { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                                Behavior on implicitHeight { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                                Behavior on color { ColorAnimation { duration: 250 } }
                                Text {
                                    anchors.centerIn: parent
                                    text: Config.wsLabels[parent.index] !== undefined ? Config.wsLabels[parent.index] : parent.wsId
                                    color: parent.active ? Pal.bg : Pal.a(Pal.fg, 0.6)
                                    font.family: Config.font
                                    font.pixelSize: Config.wsFont
                                    font.bold: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: Sys.ws(parent.wsId)
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: !win.vertical; Layout.fillHeight: win.vertical }

                    // ---------- theme mode: wallpaper colors / dark / light ----------
                    SideIcon {
                        icon: Theme.mode === "dark" ? "\uf186" : (Theme.mode === "light" ? "\uf185" : "\uf1fc")
                        tint: Pal.accent
                        lit: Theme.mode !== "wallpaper"
                        onClicked: Theme.cycle()
                        onScrolled: (d) => Sys.run("brightnessctl -e4 -n2 set 5%" + (d > 0 ? "+" : "-"))
                    }

                    // ---------- gauges ----------
                    Ring { icon: "\uf2db"; value: Sys.cpu;  tint: Pal.accent }
                    Ring { icon: "\uf1c0"; value: Sys.ram;  tint: Pal.accent2 }
                    Ring { icon: "\uf0a0"; value: Sys.disk; tint: Pal.c3 }
                    Ring {
                        icon: Sys.charging ? "\uf0e7" : "\uf240"
                        value: Sys.battery
                        tint: Sys.battery <= 15 && !Sys.charging ? "#ff6b5e" : Pal.c2
                    }

                    // ---------- keyboard, clock, power ----------
                    SideIcon {
                        icon: "\uf11c"
                        onClicked: Sys.run(Config.keyboardCmd)
                    }

                    ColumnLayout {
                        visible: win.vertical
                        Layout.alignment: Qt.AlignCenter
                        spacing: -2
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDateTime(clock.date, Config.use24h ? "HH" : "hh")
                            color: Pal.fg
                            font.family: Config.font
                            font.pixelSize: 13
                            font.bold: true
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Qt.formatDateTime(clock.date, "mm")
                            color: Pal.accent
                            font.family: Config.font
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }
                    Text {
                        visible: !win.vertical
                        Layout.alignment: Qt.AlignCenter
                        Layout.leftMargin: 4
                        Layout.rightMargin: 4
                        text: Qt.formatDateTime(clock.date, Config.use24h ? "HH:mm" : "hh:mm AP")
                        color: Pal.fg
                        font.family: Config.font
                        font.pixelSize: 14
                        font.bold: true
                    }

                    SideIcon {
                        icon: "\uf013"
                        tint: Pal.accent
                        onClicked: Sys.run("qs ipc call settings toggle")
                    }
                    SideIcon {
                        icon: "\uf011"
                        tint: "#ff6b5e"
                        onClicked: Sys.run(Config.powerCmd)
                    }
                }
            }
        }
    }
}
