import QtQuick

Rectangle {
    id: root
    property string label: ""
    property bool active: false
    signal clicked()

    implicitWidth: t.implicitWidth + 28
    implicitHeight: 32
    radius: 16
    scale: ma.pressed ? 0.96 : (ma.containsMouse ? 1.04 : 1.0)
    color: active ? (ma.containsMouse ? Pal.a(Pal.accent, 0.5) : Pal.a(Pal.accent, 0.32))
                  : (ma.containsMouse ? Pal.a(Pal.fg, 0.18) : Pal.a(Pal.fg, 0.06))
    border.width: active ? 2 : 1
    border.color: active ? Pal.accent : (ma.containsMouse ? Pal.a(Pal.fg, 0.35) : Pal.a(Pal.fg, 0.12))
    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }
    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }

    Text {
        id: t
        anchors.centerIn: parent
        text: root.label
        color: (root.active || ma.containsMouse) ? Pal.fg : Pal.dim
        font.family: Config.font
        font.pixelSize: 12
        font.bold: true
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
