import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property string icon: ""
    property color tint: Pal.fg
    property bool lit: false
    signal clicked()
    signal scrolled(int dir)

    Layout.alignment: Qt.AlignCenter
    Layout.preferredWidth: Config.iconSize
    Layout.preferredHeight: Config.iconSize
    scale: ma.pressed ? 0.88 : 1.0
    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: (ma.containsMouse || root.lit) ? Pal.a(Pal.accent, 0.25) : "transparent"
        Behavior on color { ColorAnimation { duration: 180 } }
    }
    Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.tint
        font.family: Config.font
        font.pixelSize: Config.glyphSize
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
        onWheel: (w) => root.scrolled(w.angleDelta.y > 0 ? 1 : -1)
    }
}
