pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string layoutMode: "list"
    property string pos: "center"
    property real px: -1
    property real py: -1
    property int boxW: 520
    property int boxH: 560
    property int corner: 26
    property real bgOpacity: 0.95
    property string borderStyle: "accent"
    property string selStyle: "fill"
    property int iconPx: 32
    property int textPx: 13
    property int gridCols: 5
    property bool showDesc: true
    property bool showHints: true
    property string placeholder: "Search"
    property string sortMode: "alpha"
    property int maxRows: 0
    property string animStyle: "pop"
    property var favs: []
    property var recent: []

    readonly property int rowH: showDesc ? Math.max(iconPx + 20, 54) : Math.max(iconPx + 14, 40)
    readonly property int cellH: iconPx + textPx + 34

    readonly property var allKeys: ["layoutMode", "pos", "px", "py", "boxW", "boxH", "corner", "bgOpacity",
        "borderStyle", "selStyle", "iconPx", "textPx", "gridCols", "showDesc", "showHints", "placeholder",
        "sortMode", "maxRows", "animStyle", "favs", "recent"]
    readonly property string path: Quickshell.env("HOME") + "/.local/state/qstheme/launcher.json"

    readonly property var presets: ({
        classic: { layoutMode: "list", pos: "center", boxW: 520, boxH: 560, corner: 26, bgOpacity: 0.95,
            borderStyle: "accent", selStyle: "fill", iconPx: 32, textPx: 13, showDesc: true, showHints: true,
            placeholder: "Search", sortMode: "alpha", maxRows: 0, animStyle: "pop" },
        spotlight: { layoutMode: "list", pos: "top", boxW: 680, boxH: 420, corner: 36, bgOpacity: 0.92,
            borderStyle: "soft", selStyle: "outline", iconPx: 32, textPx: 15, showDesc: false, showHints: false,
            placeholder: "Search apps…", sortMode: "recent", maxRows: 0, animStyle: "slide" },
        grid: { layoutMode: "grid", pos: "center", boxW: 760, boxH: 560, corner: 30, bgOpacity: 0.95,
            borderStyle: "accent", selStyle: "fill", iconPx: 44, textPx: 12, gridCols: 5, showDesc: false,
            showHints: true, placeholder: "Search", sortMode: "alpha", maxRows: 0, animStyle: "pop" },
        sidebar: { layoutMode: "list", pos: "left", boxW: 400, boxH: 700, corner: 22, bgOpacity: 0.95,
            borderStyle: "accent", selStyle: "bar", iconPx: 32, textPx: 13, showDesc: true, showHints: false,
            placeholder: "Search", sortMode: "recent", maxRows: 0, animStyle: "slide" },
        minimal: { layoutMode: "list", pos: "center", boxW: 420, boxH: 400, corner: 16, bgOpacity: 0.85,
            borderStyle: "none", selStyle: "bar", iconPx: 24, textPx: 12, showDesc: false, showHints: false,
            placeholder: "Type to search", sortMode: "alpha", maxRows: 15, animStyle: "fade" }
    })

    property bool saving: false
    Timer { id: guard; interval: 700; onTriggered: root.saving = false }

    FileView {
        path: root.path
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            if (root.saving) return
            let o = {}
            try { o = JSON.parse(text()) } catch (e) { return }
            for (const k of root.allKeys) {
                if (o[k] === undefined) continue
                try { root[k] = o[k] } catch (e2) {}
            }
        }
    }

    function save() {
        const o = {}
        for (const k of allKeys) o[k] = root[k]
        saving = true
        guard.restart()
        Quickshell.execDetached(["bash", "-c",
            'mkdir -p "$(dirname "$2")"; printf %s "$1" > "$2"', "_", JSON.stringify(o), path])
    }
    function set(k, v) {
        root[k] = v
        if (k === "pos") { px = -1; py = -1 }
        save()
    }
    function setPos(x, y) { px = x; py = y; save() }
    function applyPreset(n) {
        const p = presets[n]
        if (!p) return
        for (const k in p) root[k] = p[k]
        px = -1
        py = -1
        save()
    }
    function toggleFav(id) {
        const a = favs.filter(x => x !== id)
        if (a.length === favs.length) a.push(id)
        favs = a
        save()
    }
    function launched(id) {
        recent = [id].concat(recent.filter(x => x !== id)).slice(0, 30)
        save()
    }
}
