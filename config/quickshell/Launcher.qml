import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: win
    property bool isOpen: false
    property string query: ""
    property int sel: 0
    readonly property bool grid: LConf.layoutMode === "grid"

    property bool dragging: false
    property real dragX: 0
    property real dragY: 0
    readonly property real sw: screen ? screen.width : 1920
    readonly property real sh: screen ? screen.height : 1080
    readonly property real gapT: 20 + (Config.barPosition === "top" ? Config.sideWidth + Config.sideMargin : 0)
    readonly property real gapB: 20 + (Config.barPosition === "bottom" ? Config.sideWidth + Config.sideMargin : 0)
    readonly property real gapL: 14 + (Config.barPosition === "left" ? Config.sideWidth + Config.sideMargin : 0)
    readonly property real gapR: 14 + (Config.barPosition === "right" ? Config.sideWidth + Config.sideMargin : 0)
    readonly property real autoX: LConf.pos === "left" ? gapL : (LConf.pos === "right" ? sw - LConf.boxW - gapR : (sw - LConf.boxW) / 2)
    readonly property real autoY: LConf.pos === "top" ? gapT : (LConf.pos === "bottom" ? sh - LConf.boxH - gapB : (sh - LConf.boxH) / 2)
    readonly property real curX: clampX(dragging ? dragX : (LConf.px >= 0 ? LConf.px : autoX))
    readonly property real curY: clampY(dragging ? dragY : (LConf.py >= 0 ? LConf.py : autoY))
    function clampX(v) { return Math.max(0, Math.min(sw - LConf.boxW, v)) }
    function clampY(v) { return Math.max(0, Math.min(sh - LConf.boxH, v)) }

    readonly property var results: {
        const all = DesktopEntries.applications.values
        const q = query.toLowerCase().trim()
        const fav = (e) => LConf.favs.indexOf(e.id) >= 0 ? 0 : 1
        const rec = (e) => { const i = LConf.recent.indexOf(e.id); return i < 0 ? 999 : i }
        const by = (a, b) => {
            const f = fav(a) - fav(b)
            if (f !== 0) return f
            if (LConf.sortMode === "recent") {
                const r = rec(a) - rec(b)
                if (r !== 0) return r
            }
            return a.name.localeCompare(b.name)
        }
        const first = []
        const rest = []
        for (let i = 0; i < all.length; i++) {
            const e = all[i]
            if (e.noDisplay) continue
            const n = e.name.toLowerCase()
            if (q === "" || n.indexOf(q) === 0) first.push(e)
            else if (n.indexOf(q) >= 0
                     || (e.genericName || "").toLowerCase().indexOf(q) >= 0
                     || (e.comment || "").toLowerCase().indexOf(q) >= 0) rest.push(e)
        }
        first.sort(by)
        rest.sort(by)
        let out = first.concat(rest)
        if (LConf.maxRows > 0) out = out.slice(0, LConf.maxRows)
        return out
    }

    visible: isOpen || card.shown > 0.01
    color: "transparent"
    implicitWidth: LConf.boxW
    implicitHeight: LConf.boxH
    anchors { top: true; left: true }
    margins { top: curY; left: curX }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "qs-menu"

    IpcHandler {
        target: "launcher"
        function toggle(): void { win.isOpen = !win.isOpen }
        function open(): void { win.isOpen = true }
        function close(): void { win.isOpen = false }
    }
    HyprlandFocusGrab { windows: [win]; active: win.isOpen; onCleared: win.isOpen = false }

    onIsOpenChanged: {
        if (isOpen) { query = ""; input.text = ""; sel = 0; focusTimer.restart() }
    }
    Timer { id: focusTimer; interval: 40; onTriggered: input.forceActiveFocus() }

    function move(d) {
        if (results.length === 0) return
        sel = Math.max(0, Math.min(results.length - 1, sel + d))
        if (grid) gridV.positionViewAtIndex(sel, GridView.Contain)
        else list.positionViewAtIndex(sel, ListView.Contain)
    }
    function run() {
        const e = results[sel]
        if (!e) return
        isOpen = false
        LConf.launched(e.id)
        e.execute()
    }
    function openSettings() {
        isOpen = false
        Quickshell.execDetached(["qs", "ipc", "call", "launcherset", "open"])
    }

    Rectangle {
        id: card
        anchors.fill: parent
        property real shown: win.isOpen ? 1 : 0
        Behavior on shown { NumberAnimation { duration: LConf.animStyle === "none" ? 0 : 260; easing.type: Easing.OutCubic } }
        radius: LConf.corner
        color: Pal.a(Pal.bg, LConf.bgOpacity)
        border.width: LConf.borderStyle === "none" ? 0 : (LConf.borderStyle === "thick" ? 4 : (LConf.borderStyle === "soft" ? 1 : 2))
        border.color: LConf.borderStyle === "soft" ? Pal.a(Pal.fg, 0.14) : Pal.a(Pal.accent, 0.6)
        opacity: shown
        scale: LConf.animStyle === "pop" ? 0.94 + 0.06 * shown : 1
        transform: Translate {
            y: LConf.animStyle === "slide" ? -30 * (1 - card.shown) : 0
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // ---- drag grip ----
            Item {
                Layout.fillWidth: true
                implicitHeight: 10
                Layout.topMargin: -4
                Rectangle {
                    anchors.centerIn: parent
                    width: 44
                    height: 4
                    radius: 2
                    color: (gripMa.containsMouse || win.dragging) ? Pal.accent : Pal.a(Pal.fg, 0.25)
                }
                MouseArea {
                    id: gripMa
                    anchors.fill: parent
                    anchors.margins: -5
                    hoverEnabled: true
                    cursorShape: Qt.SizeAllCursor
                    property real sx: 0
                    property real sy: 0
                    onPressed: (m) => {
                        win.dragX = win.curX
                        win.dragY = win.curY
                        sx = m.x
                        sy = m.y
                        win.dragging = true
                    }
                    onPositionChanged: (m) => {
                        if (!pressed) return
                        win.dragX = win.clampX(win.dragX + m.x - sx)
                        win.dragY = win.clampY(win.dragY + m.y - sy)
                    }
                    onReleased: {
                        LConf.setPos(win.dragX, win.dragY)
                        win.dragging = false
                    }
                    onDoubleClicked: LConf.setPos(-1, -1)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 46
                    radius: 23
                    color: Pal.a(Pal.fg, 0.08)
                    border.width: 1
                    border.color: Pal.a(Pal.accent, 0.35)

                    Text {
                        id: glyph
                        anchors.left: parent.left
                        anchors.leftMargin: 18
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\uf002"
                        color: Pal.accent
                        font.family: Config.font
                        font.pixelSize: 15
                    }
                    TextInput {
                        id: input
                        anchors.left: glyph.right
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 18
                        anchors.verticalCenter: parent.verticalCenter
                        color: Pal.fg
                        font.family: Config.font
                        font.pixelSize: Math.max(14, LConf.textPx + 2)
                        clip: true
                        onTextChanged: { win.query = text; win.sel = 0 }
                        Keys.onUpPressed: win.move(win.grid ? -LConf.gridCols : -1)
                        Keys.onDownPressed: win.move(win.grid ? LConf.gridCols : 1)
                        Keys.onLeftPressed: (e) => { if (win.grid) win.move(-1); else e.accepted = false }
                        Keys.onRightPressed: (e) => { if (win.grid) win.move(1); else e.accepted = false }
                        Keys.onReturnPressed: win.run()
                        Keys.onEnterPressed: win.run()
                        Keys.onEscapePressed: win.isOpen = false
                        Text {
                            visible: input.text === ""
                            text: LConf.placeholder
                            color: Pal.dim
                            font.family: Config.font
                            font.pixelSize: parent.font.pixelSize
                        }
                    }
                }

                Rectangle {
                    implicitWidth: 46
                    implicitHeight: 46
                    radius: 23
                    color: gma.containsMouse ? Pal.a(Pal.accent, 0.3) : Pal.a(Pal.fg, 0.08)
                    border.width: 1
                    border.color: Pal.a(Pal.fg, 0.12)
                    Text {
                        anchors.centerIn: parent
                        text: "\uf013"
                        color: Pal.fg
                        font.family: Config.font
                        font.pixelSize: 16
                    }
                    MouseArea { id: gma; anchors.fill: parent; hoverEnabled: true; onClicked: win.openSettings() }
                }
            }

            ListView {
                id: list
                visible: !win.grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 2
                model: win.grid ? [] : win.results
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool cur: index === win.sel
                    readonly property bool fav: LConf.favs.indexOf(modelData.id) >= 0
                    width: ListView.view.width
                    height: LConf.rowH
                    radius: Math.min(14, LConf.corner / 2)
                    color: cur ? (LConf.selStyle === "fill" ? Pal.a(Pal.accent, 0.24) : (LConf.selStyle === "bar" ? Pal.a(Pal.accent, 0.1) : "transparent")) : "transparent"
                    border.width: (cur && LConf.selStyle === "outline") ? 2 : 0
                    border.color: Pal.accent

                    Rectangle {
                        visible: row.cur && LConf.selStyle === "bar"
                        width: 4
                        height: parent.height - 18
                        radius: 2
                        color: Pal.accent
                        anchors.left: parent.left
                        anchors.leftMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Image {
                        id: ic
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        width: LConf.iconPx
                        height: LConf.iconPx
                        source: Quickshell.iconPath(row.modelData.icon, true)
                        sourceSize.width: 96
                        sourceSize.height: 96
                        fillMode: Image.PreserveAspectFit
                    }
                    Column {
                        anchors.left: ic.right
                        anchors.leftMargin: 14
                        anchors.right: parent.right
                        anchors.rightMargin: 34
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1
                        Text {
                            width: parent.width
                            text: row.modelData.name
                            elide: Text.ElideRight
                            color: Pal.fg
                            font.family: Config.font
                            font.pixelSize: LConf.textPx
                            font.bold: true
                        }
                        Text {
                            width: parent.width
                            visible: LConf.showDesc && text !== ""
                            text: row.modelData.comment || row.modelData.genericName || ""
                            elide: Text.ElideRight
                            color: Pal.dim
                            font.family: Config.font
                            font.pixelSize: Math.max(9, LConf.textPx - 3)
                        }
                    }
                    Text {
                        visible: row.fav
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\uf005"
                        color: Pal.accent
                        font.family: Config.font
                        font.pixelSize: 13
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onEntered: win.sel = row.index
                        onClicked: (m) => {
                            if (m.button === Qt.RightButton) LConf.toggleFav(row.modelData.id)
                            else { win.sel = row.index; win.run() }
                        }
                    }
                }
            }

            GridView {
                id: gridV
                visible: win.grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: Math.floor(width / LConf.gridCols)
                cellHeight: LConf.cellH
                model: win.grid ? win.results : []
                boundsBehavior: Flickable.StopAtBounds

                delegate: Item {
                    id: cell
                    required property var modelData
                    required property int index
                    readonly property bool cur: index === win.sel
                    readonly property bool fav: LConf.favs.indexOf(modelData.id) >= 0
                    width: GridView.view.cellWidth
                    height: GridView.view.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 3
                        radius: 16
                        color: cell.cur ? (LConf.selStyle === "fill" ? Pal.a(Pal.accent, 0.24) : (LConf.selStyle === "bar" ? Pal.a(Pal.accent, 0.1) : "transparent")) : "transparent"
                        border.width: (cell.cur && LConf.selStyle === "outline") ? 2 : 0
                        border.color: Pal.accent

                        Rectangle {
                            visible: cell.cur && LConf.selStyle === "bar"
                            width: parent.width - 28
                            height: 3
                            radius: 2
                            color: Pal.accent
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 5
                        }
                        Column {
                            anchors.centerIn: parent
                            width: parent.width - 8
                            spacing: 6
                            Image {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: LConf.iconPx
                                height: LConf.iconPx
                                source: Quickshell.iconPath(cell.modelData.icon, true)
                                sourceSize.width: 128
                                sourceSize.height: 128
                                fillMode: Image.PreserveAspectFit
                            }
                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: cell.modelData.name
                                elide: Text.ElideRight
                                color: Pal.fg
                                font.family: Config.font
                                font.pixelSize: LConf.textPx
                            }
                        }
                        Text {
                            visible: cell.fav
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 8
                            text: "\uf005"
                            color: Pal.accent
                            font.family: Config.font
                            font.pixelSize: 11
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onEntered: win.sel = cell.index
                        onClicked: (m) => {
                            if (m.button === Qt.RightButton) LConf.toggleFav(cell.modelData.id)
                            else { win.sel = cell.index; win.run() }
                        }
                    }
                }
            }

            Text {
                visible: win.results.length === 0
                Layout.alignment: Qt.AlignHCenter
                text: "Nothing found"
                color: Pal.dim
                font.family: Config.font
                font.pixelSize: 13
            }
            Text {
                visible: LConf.showHints
                Layout.alignment: Qt.AlignHCenter
                text: (win.grid ? "arrows choose    " : "↑ ↓ choose    ") + "Enter open    right-click \uf005 favorite    drag the bar to move    Esc close"
                color: Pal.a(Pal.dim, 0.8)
                font.family: Config.font
                font.pixelSize: 10
            }
        }
    }
}
