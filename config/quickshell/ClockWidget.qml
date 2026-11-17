import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: win
    readonly property string pos: Config.clockPos
    readonly property bool analog: Config.clockStyle === "analog"
    readonly property string fam: Config.clockFont !== "" ? Config.clockFont : Config.font
    function col(n) {
        return n === "accent" ? Pal.accent : n === "accent2" ? Pal.accent2 : n === "dim" ? Pal.dim
        : n === "c1" ? Pal.c1 : n === "c2" ? Pal.c2 : n === "c3" ? Pal.c3 : n === "c5" ? Pal.c5 : Pal.fg
    }

    anchors {
        top: pos.indexOf("top") === 0
        bottom: pos.indexOf("bottom") === 0
        left: pos.indexOf("left") >= 0
        right: pos.indexOf("right") >= 0
    }
    margins {
        top: Config.clockMarginY
        bottom: Config.clockMarginY
        left: Config.clockMarginX
        right: Config.clockMarginX
    }
    implicitWidth: analog ? Config.clockSize * 3 : Math.max(tt.implicitWidth, dt.implicitWidth) + 56
    implicitHeight: analog ? Config.clockSize * 3 : tt.implicitHeight + (Config.clockDate ? dt.implicitHeight + 6 : 0) + 36
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "qs-widget"

    SystemClock {
        id: clock
        precision: (Config.clockSeconds || win.analog) ? SystemClock.Seconds : SystemClock.Minutes
        onDateChanged: cv.requestPaint()
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: win.analog ? width / 2 : 28
        color: Config.clockCard ? Pal.a(Pal.bg, Config.clockOpacity) : "transparent"
        border.width: Config.clockCard ? 1 : 0
        border.color: Pal.a(Pal.accent, 0.5)

        // ---------- digital ----------
        Column {
            visible: !win.analog
            anchors.centerIn: parent
            spacing: 4
            Text {
                id: tt
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, Config.clock24
                ? (Config.clockSeconds ? "HH:mm:ss" : "HH:mm")
                : (Config.clockSeconds ? "hh:mm:ss AP" : "hh:mm AP"))
                color: win.col(Config.clockColor)
                font.family: win.fam
                font.pixelSize: Config.clockSize
                font.bold: Config.clockBold
            }
            Text {
                id: dt
                visible: Config.clockDate
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, Config.clockDateFormat)
                color: win.col(Config.clockDateColor)
                font.family: win.fam
                font.pixelSize: Math.max(12, Config.clockSize * 0.26)
            }
        }

        // ---------- analog ----------
        Canvas {
            id: cv
            visible: win.analog
            anchors.fill: parent
            anchors.margins: 14
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                const c = width / 2
                const r = c - 4
                const d = clock.date
                const m = d.getMinutes()
                const s = d.getSeconds()
                const h = d.getHours() % 12 + m / 60
                ctx.lineCap = "round"
                ctx.strokeStyle = Pal.dim
                ctx.lineWidth = 2
                for (let i = 0; i < 12; i++) {
                    const a = i * Math.PI / 6
                    ctx.beginPath()
                    ctx.moveTo(c + r * 0.86 * Math.sin(a), c - r * 0.86 * Math.cos(a))
                    ctx.lineTo(c + r * 0.96 * Math.sin(a), c - r * 0.96 * Math.cos(a))
                    ctx.stroke()
                }
                const hand = (ang, len, w, color) => {
                    ctx.strokeStyle = color
                    ctx.lineWidth = w
                    ctx.beginPath()
                    ctx.moveTo(c, c)
                    ctx.lineTo(c + r * len * Math.sin(ang), c - r * len * Math.cos(ang))
                    ctx.stroke()
                }
                hand(h * Math.PI / 6, 0.5, 5, win.col(Config.clockColor))
                hand((m + s / 60) * Math.PI / 30, 0.75, 3.5, win.col(Config.clockColor))
                if (Config.clockSeconds) hand(s * Math.PI / 30, 0.85, 1.5, win.col(Config.clockDateColor))
                    ctx.fillStyle = win.col(Config.clockDateColor)
                    ctx.beginPath()
                    ctx.arc(c, c, 5, 0, 2 * Math.PI)
                    ctx.fill()
            }
        }
    }
}
