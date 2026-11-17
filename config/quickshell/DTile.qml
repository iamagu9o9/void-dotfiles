import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property string icon: ""
    property string label: ""
    property bool active: false
    signal clicked()
    Layout.fillWidth: true
    implicitHeight: 74
    radius: 20
    color: active ? Pal.a(Pal.accent, 0.32) : Pal.a(Pal.fg, 0.07)
    border.width: active ? 2 : 1
    border.color: active ? Pal.accent : Pal.a(Pal.fg, 0.12)
    Behavior on color { ColorAnimation { duration: 150 } }
    scale: ma.pressed ? 0.95 : 1.0
    Behavior on scale { NumberAnimation { duration: 120 } }
    Column {
        anchors.centerIn: parent
        spacing: 6
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.icon
            color: root.active ? Pal.accent : Pal.fg
            font.family: Config.font
            font.pixelSize: 22
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            color: Pal.dim
            font.family: Config.font
            font.pixelSize: 11
            font.bold: true
        }
    }
    MouseArea { id: ma; anchors.fill: parent; onClicked: root.clicked() }
}
