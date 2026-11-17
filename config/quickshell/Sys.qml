pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int vol: 0
    property bool muted: false
    property int bri: 0
    property bool wifiOn: true
    property bool btOn: false
    property int battery: 100
    property bool charging: false
    property int mic: 0
    property bool micMuted: false
    property int cpu: 0
    property int ram: 0
    property int disk: 0
    property bool night: false

    function run(cmd) { Quickshell.execDetached(["bash", "-c", cmd]) }
    function refresh() { poll.running = true }
    function ws(n) { run("hyprctl dispatch 'hl.dsp.focus({ workspace = " + n + " })'") }

    Process {
        id: poll
        command: ["bash", Quickshell.env("HOME") + "/.config/quickshell/state.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.replace(/\n$/, "").split("\t")
                root.vol = parseInt(p[0]) || 0
                root.muted = p[1] === "1"
                root.bri = parseInt(p[2]) || 0
                root.wifiOn = p[3] === "1"
                root.btOn = p[4] === "1"
                root.battery = parseInt(p[5]) || 0
                root.charging = p[6] === "1"
                root.mic = parseInt(p[7]) || 0
                root.micMuted = p[8] === "1"
                root.cpu = parseInt(p[9]) || 0
                root.ram = parseInt(p[10]) || 0
                root.disk = parseInt(p[11]) || 0
                root.night = p[12] === "1"
            }
        }
    }
    Timer {
        interval: 2500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
