import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: win

    property bool isOpen: false
    property string raw: ""
    property string query: ""
    property string current: ""
    property int sel: 0

    readonly property var all: {
        const out = []
        for (const line of raw.split("\n")) {
            if (!line) continue
            out.push({ path: line, name: line.split("/").pop() })
        }
        return out
    }
    readonly property var view: {
        const q = query.toLowerCase()
        return all.filter(f => q === "" || f.name.toLowerCase().indexOf(q) >= 0)
    }

    visible: isOpen || card.opacity > 0.01
    color: "transparent"
    implicitWidth: 880
    implicitHeight: 580
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "qs-menu"

    IpcHandler {
        target: "wallpapers"
        function toggle(): void { win.isOpen = !win.isOpen }
        function open(): void { win.isOpen = true }
        function close(): void { win.isOpen = false }
    }

    HyprlandFocusGrab { windows: [win]; active: win.isOpen; onCleared: win.isOpen = false }

    Process {
        id: scan
        command: ["bash", "-c",
            'find "$@" -maxdepth 3 -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \\) -not -path "*/Screenshots/*" 2>/dev/null | sort',
            "_"].concat(Config.wallDirs)
        stdout: StdioCollector { onStreamFinished: win.raw = text }
    }
    Process {
        id: cur
        command: ["bash", "-c", "cat \"$HOME/.cache/wal/wal\" 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: win.current = text.trim() }
    }

    onIsOpenChanged: {
        if (isOpen) {
            query = ""
            input.text = ""
            sel = 0
            scan.running = true
            cur.running = true
            focusTimer.restart()
        }
    }
    Timer { id: focusTimer; interval: 40; onTriggered: input.forceActiveFocus() }

    function move(d) {
        if (view.length === 0) return
        sel = Math.max(0, Math.min(view.length - 1, sel + d))
    }
    function apply() {
        const f = view[sel]
        if (!f) return
        isOpen = false
        Quickshell.execDetached(["bash", "-c",
            'export PATH="$HOME/.local/bin:$PATH"; setwall "$1"', "_", f.path])
    }
    function random() {
        isOpen = false
        Quickshell.execDetached(["bash", "-c", 'export PATH="$HOME/.local/bin:$PATH"; setwall --random'])
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 26
        color: Pal.a(Pal.bg, 0.95)
        border.width: 2
        border.color: Pal.a(Pal.accent, 0.6)
        opacity: win.isOpen ? 1 : 0
        scale: win.isOpen ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }

        RowLayout {
            id: top
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 14
            spacing: 10

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 44
                radius: 22
                color: Pal.a(Pal.fg, 0.07)

                Text {
                    id: glyph
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uf03e"
                    color: Pal.accent
                    font.family: Config.font
                    font.pixelSize: 15
                }
                TextInput {
                    id: input
                    anchors.left: glyph.right
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    color: Pal.fg
                    font.family: Config.font
                    font.pixelSize: 15
                    clip: true
                    onTextChanged: { win.query = text; win.sel = 0 }
                    Keys.onLeftPressed: win.move(-1)
                    Keys.onRightPressed: win.move(1)
                    Keys.onUpPressed: win.move(-4)
                    Keys.onDownPressed: win.move(4)
                    Keys.onReturnPressed: win.apply()
                    Keys.onEnterPressed: win.apply()
                    Keys.onEscapePressed: win.isOpen = false

                    Text {
                        visible: input.text === ""
                        text: "Search " + win.all.length + " wallpapers…"
                        color: Pal.dim
                        font.family: Config.font
                        font.pixelSize: 15
                    }
                }
            }
            Chip { label: "Random"; onClicked: win.random() }
        }

        GridView {
            id: grid
            anchors.top: top.bottom
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 14
            clip: true
            cellWidth: Math.floor(width / 4)
            cellHeight: 130
            model: win.view
            currentIndex: win.sel
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)

            delegate: Item {
                id: cell
                required property var modelData
                required property int index
                readonly property bool isCurrent: win.current !== "" && win.current === modelData.path
                width: grid.cellWidth
                height: grid.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: 16
                    color: Pal.a(Pal.fg, 0.06)
                    border.width: cell.index === win.sel ? 2 : (cell.isCurrent ? 2 : 0)
                    border.color: cell.index === win.sel ? Pal.accent : Pal.a(Pal.accent, 0.5)
                    scale: cell.index === win.sel ? 1.03 : 1.0
                    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }

                    Image {
                        anchors.fill: parent
                        anchors.margins: 3
                        source: "file://" + encodeURI(cell.modelData.path)
                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 360
                        sourceSize.height: 240
                    }
                    Rectangle {
                        visible: cell.isCurrent
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 8
                        width: curTxt.implicitWidth + 16
                        height: 20
                        radius: 10
                        color: Pal.accent
                        Text {
                            id: curTxt
                            anchors.centerIn: parent
                            text: "Current"
                            color: Pal.bg
                            font.family: Config.font
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 3
                        height: 22
                        radius: 12
                        color: Pal.a(Pal.bg, 0.8)
                        Text {
                            anchors.centerIn: parent
                            width: parent.width - 12
                            text: cell.modelData.name
                            color: Pal.fg
                            font.family: Config.font
                            font.pixelSize: 10
                            elide: Text.ElideMiddle
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: win.sel = cell.index
                    onClicked: { win.sel = cell.index; win.apply() }
                }
            }
        }

        Text {
            visible: win.view.length === 0
            anchors.centerIn: grid
            text: "No images found in " + Config.wallDirs.join(", ")
            color: Pal.dim
            font.family: Config.font
            font.pixelSize: 13
        }
    }
}
