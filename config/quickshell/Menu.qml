import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: win

    property string mode: ""
    property string query: ""
    property var items: []
    property int sel: 0
    property string pendingSsid: ""
    property string wifiRaw: ""
    property string savedRaw: ""
    property string btRaw: ""

    readonly property bool isOpen: mode !== ""
    readonly property bool horizontal: mode === "power"
    readonly property bool typing: mode !== "power"
    readonly property int shown: Math.min(items.length, 8)

    visible: isOpen || card.opacity > 0.01
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "qs-menu"
    anchors { top: true; bottom: true; left: true; right: true }

    IpcHandler {
        target: "menu"
        function open(m: string): void { win.mode = m }
        function toggle(m: string): void { win.mode = (win.mode === m) ? "" : m }
        function close(): void { win.mode = "" }
    }

    HyprlandFocusGrab {
        windows: [win]
        active: win.isOpen
        onCleared: win.mode = ""
    }

    Process {
        id: wifiScan
        command: ["bash", "-c", "nmcli -t --escape no -f IN-USE,SIGNAL,SECURITY,SSID device wifi list"]
        stdout: StdioCollector { onStreamFinished: { win.wifiRaw = text; win.rebuild() } }
    }
    Process {
        id: savedScan
        command: ["bash", "-c", "nmcli -t -f NAME connection show"]
        stdout: StdioCollector { onStreamFinished: { win.savedRaw = text; win.rebuild() } }
    }
    Process {
        id: btScan
        command: ["bash", "-c", "bluetoothctl devices | while read -r _ mac name; do c=no; bluetoothctl info \"$mac\" | grep -q 'Connected: yes' && c=yes; echo \"$mac|$c|$name\"; done"]
        stdout: StdioCollector { onStreamFinished: { win.btRaw = text; win.rebuild() } }
    }

    readonly property string shotPrep: 'd="$HOME/Pictures/Screenshots"; mkdir -p "$d"; f="$d/$(date +%F_%H-%M-%S).png"; '

    function rank(label, q) {
        return label.toLowerCase().indexOf(q) === 0 ? 0 : 1
    }

    function rebuild() {
        const q = query.toLowerCase()
        const out = []

        if (mode === "apps") {
            const apps = DesktopEntries.applications.values
            for (let i = 0; i < apps.length; i++) {
                const a = apps[i]
                if (a.noDisplay) continue
                if (q !== "" && a.name.toLowerCase().indexOf(q) < 0) continue
                out.push({
                    label: a.name,
                    sub: a.comment || a.genericName || "",
                    img: Quickshell.iconPath(a.icon, true),
                    glyph: "\uf135",
                    run: () => a.execute()
                })
            }
            out.sort((x, y) => rank(x.label, q) - rank(y.label, q) || x.label.localeCompare(y.label))
        }
        else if (mode === "windows") {
            const tl = ToplevelManager.toplevels.values
            for (let i = 0; i < tl.length; i++) {
                const t = tl[i]
                const hay = ((t.title || "") + " " + (t.appId || "")).toLowerCase()
                if (q !== "" && hay.indexOf(q) < 0) continue
                out.push({
                    label: t.title || t.appId,
                    sub: t.appId,
                    glyph: "\uf2d0",
                    run: () => t.activate()
                })
            }
        }
        else if (mode === "tools") {
            const tools = [
                { label: "Screenshot area", sub: "Saved and copied", glyph: "\uf125",
                  cmd: "sleep 0.35; " + shotPrep + 'grim -g "$(slurp)" "$f" && wl-copy < "$f" && notify-send "Screenshot saved" "$f"' },
                { label: "Screenshot full screen", sub: "Saved and copied", glyph: "\uf108",
                  cmd: "sleep 0.5; " + shotPrep + 'grim "$f" && wl-copy < "$f" && notify-send "Screenshot saved" "$f"' },
                { label: "Color picker", sub: "Copies the color", glyph: "\uf1fb",
                  cmd: 'c=$(hyprpicker -a) && notify-send "Color copied" "$c"' },
                { label: "Record screen", sub: "Run again to stop", glyph: "\uf03d",
                  cmd: 'if pgrep -x wf-recorder >/dev/null; then pkill -INT wf-recorder; notify-send "Recording saved" "$HOME/Videos"; else mkdir -p "$HOME/Videos"; notify-send "Recording started" "Tools running"; wf-recorder -g "$(slurp)" -f "$HOME/Videos/rec_$(date +%F_%H-%M-%S).mp4"; fi' },
                { label: "Text from screen", sub: "OCR to clipboard", glyph: "\uf031",
                  cmd: 'sleep 0.35; grim -g "$(slurp)" - | tesseract - - 2>/dev/null | wl-copy && notify-send "Text copied" "from the selected area"' }
            ]
            for (const t of tools) {
                if (q !== "" && t.label.toLowerCase().indexOf(q) < 0) continue
                out.push({ label: t.label, sub: t.sub, glyph: t.glyph, run: () => Sys.run(t.cmd) })
            }
        }
        else if (mode === "power") {
            out.push({ label: "Lock", glyph: "\uf023", run: () => Sys.run(Config.lockCmd) })
            out.push({ label: "Logout", glyph: "\uf08b", run: () => Sys.run("loginctl terminate-user $USER") })
            out.push({ label: "Sleep", glyph: "\uf186", run: () => Sys.run("systemctl suspend") })
            out.push({ label: "Reboot", glyph: "\uf021", run: () => Sys.run("systemctl reboot") })
            out.push({ label: "Power off", glyph: "\uf011", run: () => Sys.run("systemctl poweroff") })
        }
        else if (mode === "wifi") {
            const saved = savedRaw.split("\n")
            const list = []
            const seen = {}
            for (const line of wifiRaw.split("\n")) {
                if (!line) continue
                const p = line.split(":")
                const ssid = p.slice(3).join(":")
                if (!ssid || seen[ssid]) continue
                seen[ssid] = true
                list.push({ ssid: ssid, sig: parseInt(p[1]) || 0, sec: p[2], inuse: p[0] === "*" })
            }
            list.sort((a, b) => (b.inuse ? 1 : 0) - (a.inuse ? 1 : 0) || b.sig - a.sig)
            for (const n of list) {
                if (q !== "" && n.ssid.toLowerCase().indexOf(q) < 0) continue
                const secured = n.sec !== "" && n.sec !== "--"
                out.push({
                    label: n.ssid,
                    sub: (n.inuse ? "Connected • " : "") + n.sig + "%" + (secured ? " • secured" : " • open"),
                    glyph: "\uf1eb",
                    run: () => {
                        if (n.inuse) {
                            Quickshell.execDetached(["nmcli", "connection", "down", "id", n.ssid])
                        } else if (saved.indexOf(n.ssid) >= 0) {
                            Quickshell.execDetached(["bash", "-c", 'nmcli connection up id "$1" && notify-send Wi-Fi "Connected to $1" || notify-send Wi-Fi "Could not connect to $1"', "_", n.ssid])
                        } else if (!secured) {
                            Quickshell.execDetached(["bash", "-c", 'nmcli device wifi connect "$1" && notify-send Wi-Fi "Connected to $1" || notify-send Wi-Fi "Could not connect to $1"', "_", n.ssid])
                        } else {
                            win.pendingSsid = n.ssid
                            win.mode = "wifi-pass"
                        }
                    }
                })
            }
            out.push({ label: Sys.wifiOn ? "Turn Wi-Fi off" : "Turn Wi-Fi on", glyph: "\uf011",
                        run: () => Sys.run("nmcli radio wifi " + (Sys.wifiOn ? "off" : "on")) })
            out.push({ label: "Advanced settings", glyph: "\uf013", run: () => Sys.run("kitty -e nmtui") })
        }
        else if (mode === "bluetooth") {
            for (const line of btRaw.split("\n")) {
                if (!line) continue
                const p = line.split("|")
                const mac = p[0]
                const on = p[1] === "yes"
                const name = p.slice(2).join("|")
                if (q !== "" && name.toLowerCase().indexOf(q) < 0) continue
                out.push({
                    label: name,
                    sub: on ? "Connected" : "Not connected",
                    glyph: "\uf293",
                    run: () => Quickshell.execDetached(["bluetoothctl", on ? "disconnect" : "connect", mac])
                })
            }
            out.push({ label: Sys.btOn ? "Turn Bluetooth off" : "Turn Bluetooth on", glyph: "\uf011",
                       run: () => Sys.run(Sys.btOn ? "bluetoothctl power off" : "rfkill unblock bluetooth; bluetoothctl power on") })
            out.push({ label: "Pair new device", glyph: "\uf067", run: () => Sys.run("blueman-manager") })
        }

        if (mode === "settings") {
            const mk = (label, sub, glyph, fn) => {
                if (q === "" || label.toLowerCase().indexOf(q) >= 0)
                    out.push({ label: label, sub: sub, glyph: glyph, run: fn })
            }
            const setPos = (pos) => () => Quickshell.execDetached(["bash", "-c", 'export PATH="$HOME/.local/bin:$PATH"; barpos "$1"', "_", pos])
            const setMode = (m) => () => Quickshell.execDetached(["bash", "-c",
                'export PATH="$HOME/.local/bin:$PATH"; setwall --mode "$1"', "_", m])
            const cur = Config.barPosition

            mk("Bar at the top",    cur === "top"    ? "Current" : "", "\uf062", setPos("top"))
            mk("Bar at the bottom", cur === "bottom" ? "Current" : "", "\uf063", setPos("bottom"))
            mk("Bar on the left",   cur === "left"   ? "Current" : "", "\uf060", setPos("left"))
            mk("Bar on the right",  cur === "right"  ? "Current" : "", "\uf061", setPos("right"))
            mk("Theme: wallpaper colors", Theme.mode === "wallpaper" ? "Current" : "Follows the wallpaper", "\uf1fc", setMode("wallpaper"))
            mk("Theme: dark monochrome",  Theme.mode === "dark"  ? "Current" : "Black and white", "\uf186", setMode("dark"))
            mk("Theme: light monochrome", Theme.mode === "light" ? "Current" : "White and black", "\uf185", setMode("light"))
            mk("Change wallpaper", "Open the wallpaper picker", "\uf03e",
               () => Quickshell.execDetached(["qs", "ipc", "call", "wallpapers", "toggle"]))
        }

        items = out
        if (sel >= out.length) sel = Math.max(0, out.length - 1)
    }

    function move(d) {
        if (items.length === 0) return
        sel = (sel + d + items.length) % items.length
    }

    function accept() {
        if (mode === "wifi-pass") {
            Quickshell.execDetached(["bash", "-c",
                'nmcli device wifi connect "$1" password "$2" && notify-send Wi-Fi "Connected to $1" || notify-send Wi-Fi "Could not connect to $1"',
                "_", pendingSsid, input.text])
            mode = ""
            return
        }
        const it = items[sel]
        if (!it) return
        mode = ""
        it.run()
    }

    onModeChanged: {
        query = ""
        input.text = ""
        sel = 0
        if (mode === "wifi") { savedScan.running = true; wifiScan.running = true }
        else if (mode === "bluetooth") { btScan.running = true }
        rebuild()
        if (mode !== "") focusTimer.restart()
    }

    Timer {
        id: focusTimer
        interval: 40
        onTriggered: { if (win.typing) input.forceActiveFocus(); else keys.forceActiveFocus() }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: win.mode = ""
    }

    Rectangle {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        y: 52
        width: win.horizontal ? 440 : 580
        height: mode === "wifi-pass" ? 72 : (win.horizontal ? 104 : 80 + Math.max(shown, 1) * 62)
        
        radius: win.horizontal ? 36 : 26
        color: Pal.a(Pal.bg, 0.95)
        border.width: 2
        border.color: Pal.a(Pal.accent, 0.6)
        opacity: win.isOpen ? 1 : 0
        scale: win.isOpen ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }

        Item {
            id: keys
            Keys.onLeftPressed: win.move(-1)
            Keys.onRightPressed: win.move(1)
            Keys.onReturnPressed: win.accept()
            Keys.onEnterPressed: win.accept()
            Keys.onEscapePressed: win.mode = ""
        }

        Rectangle {
            id: bar
            visible: win.typing
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 14
            height: 44
            radius: 22
            color: Pal.a(Pal.fg, 0.07)

            Text {
                id: glyph
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: win.mode === "wifi-pass" ? "\uf023" : "\uf002"
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
                selectByMouse: true
                echoMode: win.mode === "wifi-pass" ? TextInput.Password : TextInput.Normal
                onTextChanged: {
                    if (win.mode !== "wifi-pass") {
                        win.query = text
                        win.sel = 0
                        win.rebuild()
                    }
                }
                Keys.onUpPressed: win.move(-1)
                Keys.onDownPressed: win.move(1)
                Keys.onTabPressed: win.move(1)
                Keys.onReturnPressed: win.accept()
                Keys.onEnterPressed: win.accept()
                Keys.onEscapePressed: win.mode = ""

                Text {
                    visible: input.text === ""
                    text: win.mode === "wifi-pass" ? "Password for " + win.pendingSsid
                        : ({ apps: "Search apps...", windows: "Search windows...", tools: "Tools...", 
                             wifi: "Search networks...", bluetooth: "Search devices...", settings: "Settings..." })[win.mode] || ""
                    color: Pal.dim
                    font.family: Config.font
                    font.pixelSize: 15
                }
            }
        }

        ListView {
            id: list
            visible: !win.horizontal && win.mode !== "wifi-pass"
            anchors.top: bar.bottom
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.bottomMargin: 14
            clip: true
            spacing: 4
            model: win.items
            currentIndex: win.sel
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index
                width: list.width
                height: 58
                radius: 16
                color: index === win.sel ? Pal.a(Pal.accent, 0.3) : "transparent"
                border.width: index === win.sel ? 1 : 0
                border.color: Pal.accent
                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    Item {
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        Image {
                            id: img
                            anchors.fill: parent
                            source: row.modelData.img || ""
                            sourceSize.width: 60
                            sourceSize.height: 60
                            fillMode: Image.PreserveAspectFit
                            visible: img.status === Image.Ready
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: img.status !== Image.Ready
                            text: row.modelData.glyph || "\uf135"
                            color: Pal.accent
                            font.family: Config.font
                            font.pixelSize: 22
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            text: row.modelData.label
                            color: Pal.fg
                            font.family: Config.font
                            font.bold: true
                            font.pixelSize: 14
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        Text {
                            visible: !!row.modelData.sub
                            text: row.modelData.sub || ""
                            color: Pal.dim
                            font.family: Config.font
                            font.pixelSize: 10
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: win.sel = row.index
                    onClicked: { win.sel = row.index; win.accept() }
                }
            }
        }

        ListView {
            id: plist
            visible: win.horizontal
            anchors.fill: parent
            anchors.margins: 14
            orientation: ListView.Horizontal
            interactive: false
            model: win.items

            delegate: Item {
                id: pc
                required property var modelData
                required property int index
                width: plist.width / 5
                height: plist.height

                Rectangle {
                    anchors.centerIn: parent
                    width: 60
                    height: 60
                    radius: 30
                    color: pc.index === win.sel ? Pal.a(Pal.accent, 0.25) : "transparent"
                    scale: pc.index === win.sel ? 1.1 : 1.0
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                    Text {
                        anchors.centerIn: parent
                        text: pc.modelData.glyph
                        color: pc.index === win.sel ? Pal.accent : Pal.dim
                        font.family: Config.font
                        font.pixelSize: 26
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: win.sel = pc.index
                    onClicked: { win.sel = pc.index; win.accept() }
                }
            }
        }
    }
}
