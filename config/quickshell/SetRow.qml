import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    property string title: ""
    default property alias chips: flow.data
    Layout.fillWidth: true
    spacing: 6

    Text {
        text: root.title
        color: Pal.dim
        font.family: Config.font
        font.pixelSize: 11
        font.bold: true
    }
    Item {
        Layout.fillWidth: true
        implicitHeight: flow.implicitHeight
        Flow {
            id: flow
            width: parent.width
            spacing: 8
        }
    }
}
