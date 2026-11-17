pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property string mode: "wallpaper"
    readonly property var order: ["wallpaper", "dark", "light"]

    function cycle() {
        const next = order[(order.indexOf(mode) + 1) % order.length]
        mode = next
        Quickshell.execDetached(["bash", "-c", 'export PATH="$HOME/.local/bin:$PATH"; setwall --mode ' + next])
    }

    Process {
        id: rd
        command: ["bash", "-c", "cat \"$HOME/.cache/theme-mode\" 2>/dev/null || echo wallpaper"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.trim()
                if (m === "dark" || m === "light" || m === "wallpaper") root.mode = m
            }
        }
    }
    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: rd.running = true
    }
}
