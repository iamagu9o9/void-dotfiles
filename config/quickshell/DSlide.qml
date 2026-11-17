import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property string icon: ""
    property int value: 0
    signal live(int v)
    signal commit(int v)
    Layout.fillWidth: true
    implicitHeight: 30

    Text {
        id: ic
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        color: Pal.fg
        font.family: Config.font
        font.pixelSize: 16
        width: 26
    }
    Rectangle {
        id: track
        anchors.left: ic.right
        anchors.right: pct.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        height: 12
        radius: 6
        color: Pal.a(Pal.fg, 0.12)
        Rectangle {
            width: parent.width * root.value / 100
            height: parent.height
            radius: 6
            color: Pal.accent
            Behavior on width { NumberAnimation { duration: 80 } }
        }
        MouseArea {
            anchors.fill: parent
            anchors.topMargin: -10
            anchors.bottomMargin: -10
            function calc(x) { return Math.max(0, Math.min(100, Math.round(x / track.width * 100))) }
            onPressed: (m) => root.live(calc(m.x))
            onPositionChanged: (m) => { if (pressed) root.live(calc(m.x)) }
            onReleased: (m) => root.commit(calc(m.x))
        }
    }
    Text {
        id: pct
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.value + "%"
        color: Pal.fg
        font.family: Config.font
        font.pixelSize: 12
        font.bold: true
        width: 38
        horizontalAlignment: Text.AlignRight
    }
}
