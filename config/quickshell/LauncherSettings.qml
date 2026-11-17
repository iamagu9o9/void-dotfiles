import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: win
    property bool isOpen: false

    readonly property var schema: [
        { sec: "Quick styles" },
        { special: "presets" },

        { sec: "Layout" },
        { title: "Style", desc: "A list with descriptions, or a grid of big icons.", key: "layoutMode", opts: [["List", "list"], ["Grid", "grid"]] },
        { title: "Columns", desc: "How many apps per row.", key: "gridCols", when: ["layoutMode", "grid"], opts: [["3", 3], ["4", 4], ["5", 5], ["6", 6]] },
        { title: "Where it appears", desc: "You can also drag the bar at the top of the launcher. Double-click that bar to reset.", key: "pos", opts: [["Center", "center"], ["Top", "top"], ["Bottom", "bottom"], ["Left", "left"], ["Right", "right"]] },
        { title: "Width", desc: "", key: "boxW", opts: [["Compact", 400], ["Normal", 520], ["Wide", 680], ["Huge", 820]] },
        { title: "Height", desc: "", key: "boxH", opts: [["Short", 380], ["Normal", 560], ["Tall", 700]] },

        { sec: "Look" },
        { title: "Corners", desc: "", key: "corner", opts: [["Square", 8], ["Soft", 16], ["Round", 26], ["Pill", 36]] },
        { title: "Transparency", desc: "Lower shows more of your wallpaper through the panel.", key: "bgOpacity", opts: [["70%", 0.7], ["85%", 0.85], ["95%", 0.95], ["100%", 1.0]] },
        { title: "Border", desc: "", key: "borderStyle", opts: [["Accent", "accent"], ["Thick", "thick"], ["Soft", "soft"], ["None", "none"]] },
        { title: "Highlight on the selected app", desc: "", key: "selStyle", opts: [["Fill", "fill"], ["Outline", "outline"], ["Side bar", "bar"]] },

        { sec: "Content" },
        { title: "Icon size", desc: "", key: "iconPx", opts: [["Small", 24], ["Medium", 32], ["Large", 44], ["Huge", 56]] },
        { title: "Text size", desc: "", key: "textPx", opts: [["Small", 11], ["Normal", 13], ["Large", 15]] },
        { title: "App descriptions", desc: "The grey line under each app name.", key: "showDesc", when: ["layoutMode", "list"], opts: [["Show", true], ["Hide", false]] },
        { title: "Key hints at the bottom", desc: "", key: "showHints", opts: [["Show", true], ["Hide", false]] },
        { title: "Search box text", desc: "", key: "placeholder", opts: [["Search", "Search"], ["Search apps…", "Search apps…"], ["Type to search", "Type to search"], ["Open something…", "Open something…"]] },

        { sec: "Behavior" },
        { title: "Order", desc: "Starred apps always come first.", key: "sortMode", opts: [["A to Z", "alpha"], ["Recently used", "recent"]] },
        { title: "Most apps shown", desc: "", key: "maxRows", opts: [["8", 8], ["15", 15], ["30", 30], ["All", 0]] },
        { title: "Opening animation", desc: "", key: "animStyle", opts: [["Pop", "pop"], ["Slide", "slide"], ["Fade", "fade"], ["None", "none"]] },
        { special: "actions" }
    ]

    function isOn(key, v) {
        const c = LConf[key]
        return typeof v === "number" ? Math.abs(c - v) < 0.001 : c === v
    }

    visible: isOpen || card.opacity > 0.01
    color: "transparent"
    implicitWidth: 700
    implicitHeight: 760
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "qs-menu"

    IpcHandler {
        target: "launcherset"
        function toggle(): void { win.isOpen = !win.isOpen }
        function open(): void { win.isOpen = true }
        function close(): void { win.isOpen = false }
    }
    HyprlandFocusGrab { windows: [win]; active: win.isOpen; onCleared: win.isOpen = false }
    onIsOpenChanged: { if (isOpen) keys.forceActiveFocus() }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 28
        color: Pal.a(Pal.bg, 0.95)
        border.width: 2
        border.color: Pal.a(Pal.accent, 0.6)
        opacity: win.isOpen ? 1 : 0
        scale: win.isOpen ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }

        Item { id: keys; anchors.fill: parent; Keys.onEscapePressed: win.isOpen = false }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 12

            Item {
                Layout.fillWidth: true
                implicitHeight: 30
                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uf104  Settings"
                    color: Pal.dim; font.family: Config.font; font.pixelSize: 13
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        onClicked: { win.isOpen = false; Quickshell.execDetached(["qs", "ipc", "call", "settings", "open"]) }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: "App launcher"
                    color: Pal.fg; font.family: Config.font; font.bold: true; font.pixelSize: 20
                }
                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uf00d"
                    color: Pal.dim; font.family: Config.font; font.pixelSize: 16
                    MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: win.isOpen = false }
                }
            }

            // ---------- live preview ----------
            Rectangle {
                id: stageBox
                Layout.fillWidth: true
                implicitHeight: 230
                radius: 18
                color: Pal.a(Pal.fg, 0.05)
                clip: true
                readonly property real s: Math.min((width - 24) / LConf.boxW, (height - 24) / LConf.boxH, 0.5)

                Rectangle {
                    anchors.centerIn: parent
                    width: LConf.boxW * stageBox.s
                    height: LConf.boxH * stageBox.s
                    Behavior on width { NumberAnimation { duration: 160 } }
                    Behavior on height { NumberAnimation { duration: 160 } }
                    radius: Math.min(LConf.corner * stageBox.s, Math.min(width, height) / 2)
                    color: Pal.a(Pal.bg, LConf.bgOpacity)
                    border.width: LConf.borderStyle === "none" ? 0 : (LConf.borderStyle === "thick" ? 3 : (LConf.borderStyle === "soft" ? 1 : 2))
                    border.color: LConf.borderStyle === "soft" ? Pal.a(Pal.fg, 0.14) : Pal.a(Pal.accent, 0.6)

                    Item {
                        anchors.fill: parent
                        anchors.margins: 14 * stageBox.s

                        Rectangle {
                            id: pvSearch
                            width: parent.width
                            height: 46 * stageBox.s
                            radius: height / 2
                            color: Pal.a(Pal.fg, 0.08)
                            border.width: 1
                            border.color: Pal.a(Pal.accent, 0.35)
                            Rectangle {
                                anchors.left: parent.left
                                anchors.leftMargin: 18 * stageBox.s
                                anchors.verticalCenter: parent.verticalCenter
                                width: 70 * stageBox.s
                                height: Math.max(3, 8 * stageBox.s)
                                radius: height / 2
                                color: Pal.a(Pal.fg, 0.3)
                            }
                        }

                        Item {
                            anchors.top: pvSearch.bottom
                            anchors.topMargin: 10 * stageBox.s
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            clip: true

                            Column {
                                visible: LConf.layoutMode === "list"
                                width: parent.width
                                spacing: 2 * stageBox.s
                                Repeater {
                                    model: 10
                                    Rectangle {
                                        required property int index
                                        width: parent.width
                                        height: LConf.rowH * stageBox.s
                                        radius: Math.min(14, LConf.corner / 2) * stageBox.s
                                        color: index === 0 ? (LConf.selStyle === "fill" ? Pal.a(Pal.accent, 0.24) : (LConf.selStyle === "bar" ? Pal.a(Pal.accent, 0.1) : "transparent")) : "transparent"
                                        border.width: (index === 0 && LConf.selStyle === "outline") ? Math.max(1, 2 * stageBox.s) : 0
                                        border.color: Pal.accent
                                        Rectangle {
                                            visible: index === 0 && LConf.selStyle === "bar"
                                            width: Math.max(2, 4 * stageBox.s)
                                            height: parent.height * 0.7
                                            radius: width / 2
                                            color: Pal.accent
                                            anchors.left: parent.left
                                            anchors.leftMargin: 4 * stageBox.s
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Rectangle {
                                            id: pIc
                                            anchors.left: parent.left
                                            anchors.leftMargin: 14 * stageBox.s
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: LConf.iconPx * stageBox.s
                                            height: width
                                            radius: width * 0.25
                                            color: Pal.a(Pal.accent, 0.35 + (index % 3) * 0.15)
                                        }
                                        Column {
                                            anchors.left: pIc.right
                                            anchors.leftMargin: 14 * stageBox.s
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 3 * stageBox.s
                                            Rectangle {
                                                width: (70 + (index % 4) * 18) * stageBox.s
                                                height: Math.max(3, LConf.textPx * 0.7 * stageBox.s)
                                                radius: height / 2
                                                color: Pal.a(Pal.fg, 0.7)
                                            }
                                            Rectangle {
                                                visible: LConf.showDesc
                                                width: 120 * stageBox.s
                                                height: Math.max(2, (LConf.textPx - 4) * 0.7 * stageBox.s)
                                                radius: height / 2
                                                color: Pal.a(Pal.fg, 0.3)
                                            }
                                        }
                                    }
                                }
                            }

                            Grid {
                                visible: LConf.layoutMode === "grid"
                                columns: LConf.gridCols
                                Repeater {
                                    model: 24
                                    Item {
                                        required property int index
                                        width: parent.width / LConf.gridCols
                                        height: LConf.cellH * stageBox.s
                                        Rectangle {
                                            anchors.fill: parent
                                            anchors.margins: 3 * stageBox.s
                                            radius: 16 * stageBox.s
                                            color: index === 0 ? (LConf.selStyle === "fill" ? Pal.a(Pal.accent, 0.24) : (LConf.selStyle === "bar" ? Pal.a(Pal.accent, 0.1) : "transparent")) : "transparent"
                                            border.width: (index === 0 && LConf.selStyle === "outline") ? Math.max(1, 2 * stageBox.s) : 0
                                            border.color: Pal.accent
                                            Column {
                                                anchors.centerIn: parent
                                                spacing: 6 * stageBox.s
                                                Rectangle {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    width: LConf.iconPx * stageBox.s
                                                    height: width
                                                    radius: width * 0.25
                                                    color: Pal.a(Pal.accent, 0.35 + (index % 3) * 0.15)
                                                }
                                                Rectangle {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    width: 40 * stageBox.s
                                                    height: Math.max(2, LConf.textPx * 0.6 * stageBox.s)
                                                    radius: height / 2
                                                    color: Pal.a(Pal.fg, 0.6)
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

            Flickable {
                id: fl
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: content.implicitHeight + 20
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: content
                    width: fl.width - 12
                    spacing: 14

                    Repeater {
                        model: win.schema

                        ColumnLayout {
                            id: item
                            required property var modelData
                            readonly property var d: modelData
                            readonly property bool useSeg: !!d.opts && d.opts.reduce((n, o) => n + String(o[0]).length, 0) < 42
                            visible: !d.when || LConf[d.when[0]] === d.when[1]
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                visible: !!item.d.sec
                                text: item.d.sec || ""
                                color: Pal.fg; font.family: Config.font; font.bold: true; font.pixelSize: 17
                                Layout.topMargin: 8
                            }

                            Flow {
                                visible: item.d.special === "presets"
                                Layout.fillWidth: true
                                spacing: 8
                                Repeater {
                                    model: item.d.special === "presets" ? [["Classic", "classic"], ["Spotlight", "spotlight"], ["App grid", "grid"], ["Sidebar", "sidebar"], ["Minimal", "minimal"]] : []
                                    Chip {
                                        required property var modelData
                                        label: modelData[0]
                                        onClicked: LConf.applyPreset(modelData[1])
                                    }
                                }
                            }

                            ColumnLayout {
                                visible: item.d.special === "actions"
                                Layout.fillWidth: true
                                spacing: 4
                                Text { text: "Position, favorites and history"; color: Pal.fg; font.family: Config.font; font.bold: true; font.pixelSize: 13; Layout.topMargin: 8 }
                                Text {
                                    text: "Right-click an app in the launcher to star it. Starred apps stay at the top."
                                    color: Pal.dim; font.family: Config.font; font.pixelSize: 11
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                                Flow {
                                    Layout.fillWidth: true
                                    Layout.topMargin: 4
                                    spacing: 8
                                    Chip { label: "Try the launcher"; onClicked: { win.isOpen = false; Quickshell.execDetached(["qs", "ipc", "call", "launcher", "open"]) } }
                                    Chip { label: "Reset position"; onClicked: LConf.setPos(-1, -1) }
                                    Chip { label: "Clear favorites"; onClicked: LConf.set("favs", []) }
                                    Chip { label: "Clear history"; onClicked: LConf.set("recent", []) }
                                    Chip { label: "Reset all options"; onClicked: LConf.applyPreset("classic") }
                                }
                            }

                            Text {
                                visible: !!item.d.title
                                text: item.d.title || ""
                                color: Pal.fg; font.family: Config.font; font.bold: true; font.pixelSize: 13
                            }
                            Text {
                                visible: !!item.d.desc
                                text: item.d.desc || ""
                                color: Pal.dim; font.family: Config.font; font.pixelSize: 11
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                            Item {
                                visible: !!item.d.opts
                                Layout.fillWidth: true
                                Layout.topMargin: 4
                                implicitHeight: item.useSeg ? seg.implicitHeight : optFlow.implicitHeight

                                Seg {
                                    id: seg
                                    visible: item.useSeg
                                    opts: item.d.opts || []
                                    isActive: function(v) { return win.isOn(item.d.key, v) }
                                    onPicked: (v) => LConf.set(item.d.key, v)
                                }
                                Flow {
                                    id: optFlow
                                    visible: !item.useSeg
                                    width: parent.width
                                    spacing: 8
                                    Repeater {
                                        model: item.useSeg ? [] : (item.d.opts || [])
                                        Chip {
                                            required property var modelData
                                            label: modelData[0]
                                            active: win.isOn(item.d.key, modelData[1])
                                            onClicked: LConf.set(item.d.key, modelData[1])
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
}
