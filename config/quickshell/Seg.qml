import QtQuick

Rectangle {
    id: root
    property var opts: []
    property var isActive: function(v) { return false }
    signal picked(var v)

    implicitWidth: row.implicitWidth + 8
    implicitHeight: 38
    radius: 19
    color: Pal.a(Pal.fg, 0.06)
    border.width: 1
    border.color: Pal.a(Pal.fg, 0.1)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 2
        Repeater {
            model: root.opts
            Rectangle {
                id: seg
                required property var modelData
                readonly property bool on: root.isActive(modelData[1])
                width: lbl.implicitWidth + 30
                height: 30
                radius: 15
                color: on ? (sma.containsMouse ? Pal.a(Pal.accent, 0.55) : Pal.a(Pal.accent, 0.38))
                          : (sma.containsMouse ? Pal.a(Pal.fg, 0.2) : "transparent")
                Behavior on color { ColorAnimation { duration: 120 } }
                Text {
                    id: lbl
                    anchors.centerIn: parent
                    text: seg.modelData[0]
                    color: (seg.on || sma.containsMouse) ? Pal.fg : Pal.dim
                    font.family: Config.font
                    font.pixelSize: 12
                    font.bold: seg.on
                }
                MouseArea {
                    id: sma
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.picked(seg.modelData[1])
                }
            }
        }
    }
}
