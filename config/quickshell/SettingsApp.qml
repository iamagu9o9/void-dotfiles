import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: win
    property bool isOpen: false
    property bool busy: false
    property int page: 0
    property string wall: ""
    property var prefs: ({})
    property var vals: ({})
    property var pins: []
    readonly property string prefsPath: Quickshell.env("HOME") + "/.local/state/qstheme/settings.json"
    readonly property string bin: Quickshell.env("HOME") + "/.local/bin/dockpin"
    readonly property var modeDef: ({ kind: "theme", key: "mode", def: "wallpaper" })

    readonly property var pages: [
        { n: "Colors",    i: "\uf1fc", s: "Theme mode and accent color" },
        { n: "Apps",      i: "\uf009", s: "Which apps follow your wallpaper" },
        { n: "Bar",       i: "\uf0c9", s: "The main bar" },
        { n: "Dock",      i: "\uf108", s: "Position, size and pinned apps" },
        { n: "Clock",     i: "\uf017", s: "The clock on your desktop" },
        { n: "Wallpaper", i: "\uf03e", s: "Change it and everything recolors" },
        { n: "Launcher",  i: "\uf002", s: "The app menu" },
        { n: "Advanced",  i: "\uf1de", s: "Fine tuning for colors" }
    ]

    // kind: theme = file in ~/.config/qstheme then setwall | pref = live Config value | app = per-app switch | action
    readonly property var schema: [
        { page: 0, special: "mode" },
        { page: 0, title: "Accent color", desc: "Pick a fixed accent, or let the wallpaper choose it.", kind: "theme", key: "accent", def: "", opts: [["From wallpaper", ""], ["Red", "#e5484d"], ["Orange", "#f76b15"], ["Yellow", "#ffc53d"], ["Green", "#30a46c"], ["Teal", "#12a594"], ["Blue", "#3e63dd"], ["Purple", "#8e4ec6"], ["Pink", "#d6409f"]] },
        { page: 0, title: "How bold", desc: "Soft is calm and muted. Vivid is bright.", kind: "theme", key: "variant", def: "balanced", opts: [["Soft", "soft"], ["Balanced", "balanced"], ["Vivid", "vivid"]] },
        { page: 0, title: "Background tint", desc: "How much accent color leaks into backgrounds.", kind: "theme", key: "bgtint", def: "1.0", opts: [["None", "0"], ["Subtle", "0.6"], ["Normal", "1.0"], ["Strong", "1.6"]] },
        { page: 0, title: "Exact color", desc: "Click, then click any pixel on screen to use its color.", kind: "action", opts: [["Pick from screen", "pick"]] },

        { page: 1, title: "Firefox and Zen Browser", desc: "Needs the Pywalfox extension.", kind: "app", key: "firefox", opts: [["On", "on"], ["Off", "off"]] },
        { page: 1, title: "Discord", desc: "Writes the Vencord theme file.", kind: "app", key: "discord", opts: [["On", "on"], ["Off", "off"]] },
        { page: 1, title: "GTK apps", desc: "Files, Nautilus and most Linux apps.", kind: "app", key: "gtk", opts: [["On", "on"], ["Off", "off"]] },
        { page: 1, title: "Qt and KDE apps", desc: "Dolphin, VLC and similar.", kind: "app", key: "qt", opts: [["On", "on"], ["Off", "off"]] },
        { page: 1, title: "Terminals", desc: "Kitty and others.", kind: "app", key: "terminals", opts: [["On", "on"], ["Off", "off"]] },

        { page: 2, title: "Position", desc: "", kind: "pref", key: "barPosition", opts: [["Top", "top"], ["Bottom", "bottom"], ["Left", "left"], ["Right", "right"]] },
        { page: 2, title: "Look", desc: "Glass is see-through, Outline has only a border.", kind: "pref", key: "barStyle", opts: [["Tinted", "tinted"], ["Glass", "glass"], ["Neutral", "neutral"], ["Outline", "outline"], ["Gradient", "gradient"]] },
        { page: 2, title: "Workspaces", desc: "", kind: "pref", key: "workspaces", opts: [["5", 5], ["7", 7], ["10", 10]] },
        { page: 2, title: "Transparency", desc: "Lower shows more of what is behind panels.", kind: "pref", key: "islandOpacity", opts: [["60%", 0.6], ["80%", 0.8], ["94%", 0.94], ["100%", 1.0]] },
        { page: 2, title: "Clock format", desc: "", kind: "pref", key: "clock24", opts: [["12 hour", false], ["24 hour", true]] },

        { page: 3, title: "Position", desc: "", kind: "pref", key: "dockPos", opts: [["Bottom", "bottom"], ["Top", "top"], ["Left", "left"], ["Right", "right"]] },
        { page: 3, title: "Hide when not in use", desc: "Slides away and returns when you touch the screen edge.", kind: "pref", key: "dockAutoHide", opts: [["On", true], ["Off", false]] },
        { page: 3, title: "Icon size", desc: "", kind: "pref", key: "dockSize", opts: [["Small", 36], ["Medium", 44], ["Large", 52], ["Huge", 62]] },
        { page: 3, title: "Gap from the screen edge", desc: "", kind: "pref", key: "dockMargin", opts: [["0", 0], ["6", 6], ["12", 12], ["20", 20]] },
        { page: 3, title: "Keep windows clear of it", desc: "Only works when hiding is off.", kind: "pref", key: "dockReserve", opts: [["On", true], ["Off", false]] },
        { page: 3, special: "dock" },

        { page: 4, title: "Style", desc: "", kind: "pref", key: "clockStyle", opts: [["Digital", "digital"], ["Analog", "analog"]] },
        { page: 4, title: "Position", desc: "", kind: "pref", key: "clockPos", opts: [["Top left", "topleft"], ["Top right", "topright"], ["Bottom left", "bottomleft"], ["Bottom right", "bottomright"], ["Center", "center"]] },
        { page: 4, title: "Seconds", desc: "", kind: "pref", key: "clockSeconds", opts: [["Show", true], ["Hide", false]] },
        { page: 4, title: "Date", desc: "", kind: "pref", key: "clockDate", opts: [["Show", true], ["Hide", false]] },
        { page: 4, title: "Card behind the clock", desc: "", kind: "pref", key: "clockCard", opts: [["On", true], ["Off", false]] },

        { page: 5, special: "wallprev" },
        { page: 5, title: "Change wallpaper", desc: "Shortcuts: Super+W to browse, Super+Shift+W for random.", kind: "action", opts: [["Choose wallpaper", "wallpaper"], ["Random", "random"]] },

        { page: 6, title: "Customize the launcher", desc: "Layout, size, colors, animation, favorites and more, with a live preview.", kind: "action", opts: [["Open launcher settings", "launcherset"], ["Try the launcher", "launcheropen"]] },

        { page: 7, title: "Color engine", desc: "OKLCH is more accurate. Material 3 is Google's algorithm.", kind: "theme", key: "engine", def: "oklch", opts: [["OKLCH", "oklch"], ["Material 3", "material"]] },
        { page: 7, title: "Harmony", desc: "How the extra colors relate to the main one.", kind: "theme", key: "harmony", def: "analogous", opts: [["Analogous", "analogous"], ["One color", "mono"], ["Colorful", "colorful"]] },
        { page: 7, title: "Color intensity", desc: "", kind: "theme", key: "chroma", def: "1.0", opts: [["70%", "0.7"], ["100%", "1.0"], ["130%", "1.3"]] },
        { page: 7, title: "Hue shift", desc: "Rotates every color around the color wheel, in degrees.", kind: "theme", key: "hueshift", def: "0", opts: [["-30", "-30"], ["-15", "-15"], ["0", "0"], ["+15", "15"], ["+30", "30"]] },
        { page: 7, title: "Text contrast", desc: "", kind: "theme", key: "contrast", def: "4.5", opts: [["Normal", "4.5"], ["High", "7"]] },
        { page: 7, title: "Material 3 scheme", desc: "Only used when the engine is Material 3.", kind: "theme", key: "scheme", def: "scheme-tonal-spot", opts: [["Tonal spot", "scheme-tonal-spot"], ["Vibrant", "scheme-vibrant"], ["Expressive", "scheme-expressive"], ["Neutral", "scheme-neutral"], ["Fidelity", "scheme-fidelity"], ["Content", "scheme-content"], ["Monochrome", "scheme-monochrome"], ["Rainbow", "scheme-rainbow"], ["Fruit salad", "scheme-fruit-salad"]] }
    ]

    function appName(id) {
        const e = DesktopEntries.heuristicLookup(id)
        return e ? e.name : id
    }
    readonly property var runningIds: {
        const out = []
        const tl = ToplevelManager.toplevels.values
        for (let i = 0; i < tl.length; i++) {
            const id = tl[i].appId || ""
            if (id !== "" && out.indexOf(id) < 0 && win.pins.indexOf(id) < 0) out.push(id)
        }
        return out
    }

    visible: isOpen || card.opacity > 0.01
    color: "transparent"
    implicitWidth: 920
    implicitHeight: 660
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "qs-menu"

    IpcHandler {
        target: "settings"
        function toggle(): void { win.isOpen = !win.isOpen }
        function open(): void { win.isOpen = true }
        function close(): void { win.isOpen = false }
    }
    HyprlandFocusGrab { windows: [win]; active: win.isOpen; onCleared: win.isOpen = false }

    FileView {
        path: Quickshell.env("HOME") + "/.config/qstheme/dock.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: { try { win.pins = JSON.parse(text()) } catch (e) {} }
    }
    Process {
        id: loadPrefs
        command: ["bash", "-c", "cat \"$1\" 2>/dev/null || echo '{}'", "_", win.prefsPath]
        stdout: StdioCollector {
            onStreamFinished: {
                let o = {}
                try { o = JSON.parse(text) } catch (e) { o = {} }
                win.prefs = o
                for (const k in o) { if (k !== "dockApps") { try { Config[k] = o[k] } catch (e2) {} } }
            }
        }
    }
    Component.onCompleted: loadPrefs.running = true
    Process {
        id: loadWall
        command: ["bash", "-c", "cat \"$HOME/.cache/wal/wal\" 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: win.wall = text.trim() }
    }
    Process {
        id: loadVals
        command: ["bash", "-c", "for k in engine variant harmony chroma bgtint hueshift contrast accent scheme; do printf '%s=%s\\n' $k \"$(cat ~/.config/qstheme/$k 2>/dev/null)\"; done; printf 'mode=%s\\n' \"$(cat ~/.cache/theme-mode 2>/dev/null)\"; for f in ~/.config/qstheme/apps/*; do [ -e \"$f\" ] && printf 'app_%s=%s\\n' \"$(basename $f)\" \"$(cat $f)\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const o = {}
                for (const line of text.split("\n")) {
                    const i = line.indexOf("=")
                    if (i > 0) o[line.slice(0, i)] = line.slice(i + 1)
                }
                win.vals = o
            }
        }
    }
    onIsOpenChanged: { if (isOpen) { busy = false; loadVals.running = true; loadWall.running = true; keys.forceActiveFocus() } }
    onPageChanged: { fl.contentY = 0; fade.restart() }

    function isActive(def, v) {
        if (def.kind === "pref") {
            const cur = Config[def.key]
            return typeof v === "number" ? Math.abs(cur - v) < 0.011 : cur === v
        }
        if (def.kind === "app") return (vals["app_" + def.key] || "on") === v
        if (def.kind === "theme") return (vals[def.key] || def.def || "") === String(v)
        return false
    }
    function setPref(key, value) {
        Config[key] = value
        const o = Object.assign({}, prefs)
        o[key] = value
        prefs = o
        Quickshell.execDetached(["bash", "-c",
            "mkdir -p \"$(dirname \"$2\")\"; printf %s \"$1\" > \"$2\"", "_", JSON.stringify(o), prefsPath])
    }
    function runTheme(script, k, v) {
        busy = true
        Quickshell.execDetached(["bash", "-c",
            "export PATH=\"$HOME/.local/bin:$HOME/.cargo/bin:$PATH\"; " + script + "; sleep 2; qs ipc call settings open",
            "_", k || "", v || ""])
    }
    function choose(def, v) {
        if (def.kind === "pref") { setPref(def.key, v); return }
        if (def.kind === "app") {
            runTheme("mkdir -p ~/.config/qstheme/apps; printf %s \"$2\" > ~/.config/qstheme/apps/$1; setwall", def.key, v)
            return
        }
        if (def.kind === "theme") {
            if (def.key === "mode") runTheme("setwall --mode \"$2\"", def.key, v)
            else runTheme("mkdir -p ~/.config/qstheme; if [ -z \"$2\" ]; then rm -f ~/.config/qstheme/$1; else printf %s \"$2\" > ~/.config/qstheme/$1; fi; setwall", def.key, String(v))
            return
        }
        if (def.kind === "action") {
            if (v === "wallpaper") {
                isOpen = false
                Quickshell.execDetached(["qs", "ipc", "call", "wallpapers", "toggle"])
            } else if (v === "random") {
                runTheme("setwall --random")
            } else if (v === "launcherset") {
                isOpen = false
                Quickshell.execDetached(["qs", "ipc", "call", "launcherset", "open"])
            } else if (v === "launcheropen") {
                isOpen = false
                Quickshell.execDetached(["qs", "ipc", "call", "launcher", "open"])
            } else if (v === "pick") {
                isOpen = false
                Quickshell.execDetached(["bash", "-c",
                    "export PATH=\"$HOME/.local/bin:$PATH\"; c=$(hyprpicker -a) && [ -n \"$c\" ] && mkdir -p ~/.config/qstheme && printf %s \"$c\" > ~/.config/qstheme/accent && setwall; sleep 2; qs ipc call settings open"])
            }
        }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 30
        color: Pal.a(Pal.bg, 0.95)
        border.width: 2
        border.color: Pal.a(Pal.accent, 0.6)
        opacity: win.isOpen ? 1 : 0
        scale: win.isOpen ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }

        // soft glow at the top
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 2
            height: 170
            radius: 28
            gradient: Gradient {
                GradientStop { position: 0.0; color: Pal.a(Pal.accent, 0.22) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Item { id: keys; anchors.fill: parent; Keys.onEscapePressed: win.isOpen = false }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            // ================= sidebar =================
            Rectangle {
                Layout.preferredWidth: 210
                Layout.fillHeight: true
                radius: 22
                color: Pal.a(Pal.fg, 0.05)
                border.width: 1
                border.color: Pal.a(Pal.fg, 0.08)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 4

                    Text {
                        text: "Settings"
                        color: Pal.fg; font.family: Config.font; font.bold: true; font.pixelSize: 22
                        Layout.leftMargin: 8
                        Layout.topMargin: 6
                        Layout.bottomMargin: 12
                    }

                    Repeater {
                        model: win.pages
                        Rectangle {
                            id: nav
                            required property var modelData
                            required property int index
                            readonly property bool cur: win.page === index
                            Layout.fillWidth: true
                            implicitHeight: 42
                            radius: 14
                            color: cur ? Pal.a(Pal.accent, nma.containsMouse ? 0.42 : 0.3)
                                       : (nma.containsMouse ? Pal.a(Pal.fg, 0.14) : "transparent")
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Rectangle {
                                visible: nav.cur
                                width: 4
                                height: 20
                                radius: 2
                                color: Pal.accent
                                anchors.left: parent.left
                                anchors.leftMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                id: gl
                                anchors.left: parent.left
                                anchors.leftMargin: 18
                                anchors.verticalCenter: parent.verticalCenter
                                width: 22
                                text: nav.modelData.i
                                color: (nav.cur || nma.containsMouse) ? Pal.accent : Pal.dim
                                font.family: Config.font; font.pixelSize: 15
                            }
                            Text {
                                anchors.left: gl.right
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: nav.modelData.n
                                color: (nav.cur || nma.containsMouse) ? Pal.fg : Pal.dim
                                font.family: Config.font; font.pixelSize: 13; font.bold: nav.cur
                            }
                            MouseArea { id: nma; anchors.fill: parent; hoverEnabled: true; onClicked: win.page = nav.index }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Rectangle {
                        visible: win.busy
                        Layout.fillWidth: true
                        implicitHeight: 40
                        radius: 14
                        color: Pal.a(Pal.accent, 0.2)
                        Text {
                            anchors.centerIn: parent
                            text: "Applying colors…"
                            color: Pal.fg; font.family: Config.font; font.pixelSize: 12
                        }
                    }
                }
            }

            // ================= content =================
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true
                        Text {
                            text: win.pages[win.page].n
                            color: Pal.fg; font.family: Config.font; font.bold: true; font.pixelSize: 26
                        }
                        Text {
                            text: win.pages[win.page].s
                            color: Pal.dim; font.family: Config.font; font.pixelSize: 12
                        }
                    }
                    Rectangle {
                        implicitWidth: 34
                        implicitHeight: 34
                        radius: 17
                        color: xma.containsMouse ? Pal.a(Pal.fg, 0.2) : Pal.a(Pal.fg, 0.07)
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text { anchors.centerIn: parent; text: "\uf00d"; color: xma.containsMouse ? Pal.fg : Pal.dim; font.family: Config.font; font.pixelSize: 14 }
                        MouseArea { id: xma; anchors.fill: parent; hoverEnabled: true; onClicked: win.isOpen = false }
                    }
                }

                Flickable {
                    id: fl
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: width
                    contentHeight: content.implicitHeight + 10
                    boundsBehavior: Flickable.StopAtBounds

                    NumberAnimation { id: fade; target: content; property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }

                    ColumnLayout {
                        id: content
                        width: fl.width - 10
                        spacing: 10

                        Repeater {
                            model: win.schema

                            Rectangle {
                                id: sc
                                required property var modelData
                                readonly property var d: modelData
                                readonly property bool useSeg: !!d.opts && d.opts.length <= 5 && d.opts.reduce((n, o) => n + String(o[0]).length, 0) < 38
                                visible: d.page === win.page
                                Layout.fillWidth: true
                                implicitHeight: inner.implicitHeight + 30
                                radius: 20
                                color: ch.hovered ? Pal.a(Pal.fg, 0.1) : Pal.a(Pal.fg, 0.05)
                                border.width: 1
                                border.color: ch.hovered ? Pal.a(Pal.accent, 0.4) : Pal.a(Pal.fg, 0.08)
                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 140 } }
                                HoverHandler { id: ch }

                                ColumnLayout {
                                    id: inner
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 16
                                    spacing: 4

                                    Text {
                                        visible: !!sc.d.title
                                        text: sc.d.title || ""
                                        color: Pal.fg; font.family: Config.font; font.bold: true; font.pixelSize: 14
                                    }
                                    Text {
                                        visible: !!sc.d.desc
                                        text: sc.d.desc || ""
                                        color: Pal.dim; font.family: Config.font; font.pixelSize: 11
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }

                                    // normal option
                                    Item {
                                        visible: !!sc.d.opts
                                        Layout.fillWidth: true
                                        Layout.topMargin: 8
                                        implicitHeight: sc.useSeg ? seg.implicitHeight : optFlow.implicitHeight
                                        Seg {
                                            id: seg
                                            visible: sc.useSeg && sc.d.kind !== "action"
                                            opts: sc.d.opts || []
                                            isActive: function(v) { return win.isActive(sc.d, v) }
                                            onPicked: (v) => win.choose(sc.d, v)
                                        }
                                        Flow {
                                            id: optFlow
                                            visible: !seg.visible
                                            width: parent.width
                                            spacing: 8
                                            Repeater {
                                                model: seg.visible ? [] : (sc.d.opts || [])
                                                Chip {
                                                    required property var modelData
                                                    label: modelData[0]
                                                    active: sc.d.kind !== "action" && win.isActive(sc.d, modelData[1])
                                                    onClicked: win.choose(sc.d, modelData[1])
                                                }
                                            }
                                        }
                                    }

                                    // Light / Dark / Wallpaper cards
                                    RowLayout {
                                        visible: sc.d.special === "mode"
                                        Layout.fillWidth: true
                                        spacing: 14
                                        ModeCard {
                                            label: "Wallpaper"
                                            bg: Pal.bg; fg: Pal.fg; ac: Pal.accent
                                            wall: win.wall
                                            active: win.isActive(win.modeDef, "wallpaper")
                                            onClicked: win.choose(win.modeDef, "wallpaper")
                                        }
                                        ModeCard {
                                            label: "Light"
                                            bg: "#f1ecf3"; fg: "#2b2630"; ac: "#8b6c9e"
                                            active: win.isActive(win.modeDef, "light")
                                            onClicked: win.choose(win.modeDef, "light")
                                        }
                                        ModeCard {
                                            label: "Dark"
                                            bg: "#1f1b24"; fg: "#e9e3ee"; ac: "#b79ccb"
                                            active: win.isActive(win.modeDef, "dark")
                                            onClicked: win.choose(win.modeDef, "dark")
                                        }
                                    }

                                    // current wallpaper preview
                                    Item {
                                        visible: sc.d.special === "wallprev"
                                        Layout.fillWidth: true
                                        implicitHeight: 190
                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 16
                                            color: Pal.a(Pal.fg, 0.06)
                                            clip: true
                                            Image {
                                                anchors.fill: parent
                                                source: win.wall !== "" ? "file://" + encodeURI(win.wall) : ""
                                                asynchronous: true
                                                fillMode: Image.PreserveAspectCrop
                                                sourceSize.width: 900
                                                sourceSize.height: 400
                                            }
                                            Text {
                                                visible: win.wall === ""
                                                anchors.centerIn: parent
                                                text: "Current wallpaper preview"
                                                color: Pal.dim; font.family: Config.font; font.pixelSize: 12
                                            }
                                        }
                                    }

                                    // dock apps
                                    ColumnLayout {
                                        visible: sc.d.special === "dock"
                                        Layout.fillWidth: true
                                        spacing: 4
                                        Text { text: "Apps on the dock"; color: Pal.fg; font.family: Config.font; font.bold: true; font.pixelSize: 14 }
                                        Text {
                                            text: "Click one to remove it. You can also right-click any dock icon, or click + on the dock."
                                            color: Pal.dim; font.family: Config.font; font.pixelSize: 11
                                            wrapMode: Text.WordWrap
                                            Layout.fillWidth: true
                                        }
                                        Flow {
                                            Layout.fillWidth: true
                                            Layout.topMargin: 6
                                            spacing: 8
                                            Repeater {
                                                model: sc.d.special === "dock" ? win.pins : []
                                                Chip {
                                                    required property string modelData
                                                    label: win.appName(modelData) + "  \uf00d"
                                                    onClicked: Quickshell.execDetached([win.bin, "remove", modelData])
                                                }
                                            }
                                        }
                                        Text {
                                            text: "Open right now (click to add)"
                                            color: Pal.fg; font.family: Config.font; font.bold: true; font.pixelSize: 13
                                            Layout.topMargin: 10
                                        }
                                        Flow {
                                            Layout.fillWidth: true
                                            Layout.topMargin: 6
                                            spacing: 8
                                            Repeater {
                                                model: sc.d.special === "dock" ? win.runningIds : []
                                                Chip {
                                                    required property string modelData
                                                    label: "\uf067  " + win.appName(modelData)
                                                    onClicked: Quickshell.execDetached([win.bin, "add", modelData])
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
    }
}
