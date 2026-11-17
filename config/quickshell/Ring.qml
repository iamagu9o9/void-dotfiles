import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property string icon: ""
    property real value: 0
    property color tint: Pal.accent
    property real shown: value
    signal clicked()
    signal scrolled(int dir)

    Layout.alignment: Qt.AlignCenter
    Layout.preferredWidth: Config.iconSize
    Layout.preferredHeight: Config.iconSize

    Behavior on shown { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
    onShownChanged: cv.requestPaint()
    onTintChanged: cv.requestPaint()

    scale: ma.pressed ? 0.9 : (ma.containsMouse ? 1.08 : 1.0)
    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }

    Canvas {
        id: cv
        anchors.fill: parent
        antialiasing: true
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const c = width / 2
            const r = c - 2.5
            ctx.lineWidth = 2.5
            ctx.lineCap = "round"
            ctx.strokeStyle = Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.22)
            ctx.beginPath()
            ctx.arc(c, c, r, 0, 2 * Math.PI)
            ctx.stroke()
            if (root.shown > 0) {
                ctx.strokeStyle = root.tint
                ctx.beginPath()
                ctx.arc(c, c, r, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * Math.min(100, root.shown) / 100)
                ctx.stroke()
            }
        }
    }
    Text {
        anchors.centerIn: parent
        text: ma.containsMouse ? Math.round(root.value) : root.icon
        color: root.tint
        font.family: Config.font
        font.bold: ma.containsMouse
        font.pixelSize: ma.containsMouse ? 10 : Config.glyphSize - 3
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
        onWheel: (w) => root.scrolled(w.angleDelta.y > 0 ? 1 : -1)
    }
}
