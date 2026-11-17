pragma Singleton
import Quickshell
import QtQuick

Singleton {
    readonly property bool light: false
    readonly property color bg: "#1f142e"
    readonly property color fg: "#edeaf1"
    readonly property color dim: "#968aa8"
    readonly property color accent: "#a473e8"
    readonly property color accent2: "#e873de"
    readonly property color c1: "#73dee8"
    readonly property color c2: "#e87390"
    readonly property color c3: "#7390e8"
    readonly property color c5: "#b7e873"
    function a(c, o) { return Qt.rgba(c.r, c.g, c.b, o) }
}
