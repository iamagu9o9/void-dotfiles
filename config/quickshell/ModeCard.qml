import QtQuick

Item {
    id: root
    property string label: ""
    property color bg: "#222222"
    property color fg: "#ffffff"
    property color ac: "#8888ff"
    property string wall: ""
    property bool active: false
    signal clicked()

    implicitWidth: 210
    implicitHeight: 146

    Rectangle {
        id: frame
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 118
        radius: 18
        color: root.bg
        border.width: root.active ? 3 : 1
        border.color: root.active ? Pal.accent : Pal.a(Pal.fg, 0.15)
        scale: ma.containsMouse ? 1.02 : 1.0
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }

        Image {
            visible: root.wall !== ""
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            height: 40
            clip: true
            source: root.wall !== "" ? "file://" + encodeURI(root.wall) : ""
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 400
            sourceSize.height: 200
        }
        Rectangle {
            visible: root.wall === ""
            x: 12; y: 12; width: 30; height: 30; radius: 15
            color: Qt.rgba(root.ac.r, root.ac.g, root.ac.b, 0.6)
        }
        Rectangle {
            visible: root.wall === ""
            x: 50; y: 16; width: parent.width - 70; height: 8; radius: 4
            color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.35)
        }
        Rectangle {
            visible: root.wall === ""
            x: 50; y: 30; width: (parent.width - 70) * 0.6; height: 8; radius: 4
            color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.2)
        }
        Rectangle {
            x: 12; y: 60; width: parent.width - 24; height: 4; radius: 2
            color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.25)
        }
        Row {
            x: 12; y: 76
            spacing: 6
            Rectangle { width: 52; height: 26; radius: 13; color: root.ac }
            Rectangle { width: 52; height: 26; radius: 13; color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.2) }
            Rectangle { width: 52; height: 26; radius: 13; color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.2) }
        }
        Rectangle {
            visible: root.active
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            width: 22; height: 22; radius: 11
            color: Pal.accent
            Text { anchors.centerIn: parent; text: "✓"; color: Pal.bg; font.pixelSize: 13; font.bold: true }
        }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: root.clicked() }
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        text: root.label
        color: root.active ? Pal.fg : Pal.dim
        font.family: Config.font
        font.pixelSize: 13
        font.bold: root.active
    }
}
