import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: win
    property bool isOpen: false
    property bool busy: false
    property string attach: ""
    property string backend: "claude"

    ListModel { id: msgs }

    visible: isOpen || card.opacity > 0.01
    color: "transparent"
    anchors { top: true; bottom: true; right: true }
    margins {
        top: 14 + (Config.barPosition === "top" ? Config.sideWidth + Config.sideMargin : 0)
        bottom: 14 + (Config.barPosition === "bottom" ? Config.sideWidth + Config.sideMargin : 0)
        right: 14 + (Config.barPosition === "right" ? Config.sideWidth + Config.sideMargin : 0)
    }
    implicitWidth: 460
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "qs-menu"

    IpcHandler {
        target: "ai"
        function toggle(): void { win.isOpen = !win.isOpen }
        function open(): void { win.isOpen = true }
        function close(): void { win.isOpen = false }
        function ask(q: string): void { win.isOpen = true; win.send(q) }
    }
    HyprlandFocusGrab { windows: [win]; active: win.isOpen; onCleared: win.isOpen = false }

    onIsOpenChanged: {
        if (isOpen) { rd.running = true; focusTimer.restart() }
    }
    Timer { id: focusTimer; interval: 60; onTriggered: input.forceActiveFocus() }

    Process {
        id: rd
        command: ["bash", "-c", "cat ~/.config/qstheme/ai 2>/dev/null || echo claude"]
        stdout: StdioCollector { onStreamFinished: win.backend = text.trim() || "claude" }
    }
    function setBackend(b) {
        backend = b
        Quickshell.execDetached(["bash", "-c",
            'mkdir -p ~/.config/qstheme; printf %s "$1" > ~/.config/qstheme/ai', "_", b])
    }

    Process {
        id: clip
        command: ["bash", "-c", "wl-paste -n 2>/dev/null | head -c 6000"]
        stdout: StdioCollector { onStreamFinished: win.attach = text }
    }

    Process {
        id: ask
        stdout: StdioCollector {
            onStreamFinished: {
                win.busy = false
                const t = text.trim()
                msgs.append({ role: "assistant", body: t !== "" ? t : "No answer came back. In a terminal, run:  echo hi | qsask  and see what it prints." })
            }
        }
    }

    function buildPrompt() {
        let p = "You are a helpful assistant built into the user's Fedora Linux desktop (Hyprland and Quickshell). " +
                "Answer clearly and briefly. Give exact commands when they help. Use plain Markdown.\n\n"
        if (attach !== "") p += "The user attached this text from their clipboard:\n```\n" + attach + "\n```\n\n"
        const start = Math.max(0, msgs.count - 9)
        for (let i = start; i < msgs.count; i++) {
            const m = msgs.get(i)
            p += (m.role === "user" ? "User: " : "Assistant: ") + m.body + "\n\n"
        }
        return p + "Assistant:"
    }

    function send(q) {
        q = (q || "").trim()
        if (q === "" || busy) return
        msgs.append({ role: "user", body: q })
        busy = true
        ask.command = ["bash", "-c",
            'export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"; printf %s "$1" | qsask 2>&1', "_", buildPrompt()]
        attach = ""
        ask.running = true
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 28
        color: Pal.a(Pal.bg, 0.95)
        border.width: 2
        border.color: Pal.a(Pal.accent, 0.6)
        opacity: win.isOpen ? 1 : 0
        transform: Translate {
            x: win.isOpen ? 0 : 40
            Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
        }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 10

            // ---------- header ----------
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "\uf0eb  Assistant"
                    color: Pal.fg; font.family: Config.font; font.bold: true; font.pixelSize: 18
                    Layout.fillWidth: true
                }
                Chip { label: "Clear"; onClicked: msgs.clear() }
                Text {
                    text: "\uf00d"
                    color: Pal.dim; font.family: Config.font; font.pixelSize: 16
                    MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: win.isOpen = false }
                }
            }

            Flow {
                Layout.fillWidth: true
                spacing: 8
                Chip { label: "Claude"; active: win.backend === "claude"; onClicked: win.setBackend("claude") }
                Chip { label: "Local (Ollama)"; active: win.backend.indexOf("ollama:") === 0; onClicked: win.setBackend("ollama:llama3.2") }
            }

            // ---------- messages ----------
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: list
                    anchors.fill: parent
                    clip: true
                    spacing: 6
                    model: msgs
                    boundsBehavior: Flickable.StopAtBounds
                    onCountChanged: positionViewAtEnd()

                    delegate: Item {
                        id: d
                        required property string role
                        required property string body
                        readonly property bool me: role === "user"
                        width: ListView.view.width
                        height: bub.height + 4

                        Rectangle {
                            id: bub
                            anchors.right: d.me ? parent.right : undefined
                            anchors.left: d.me ? undefined : parent.left
                            width: parent.width - 36
                            height: txt.implicitHeight + 22
                            radius: 16
                            color: d.me ? Pal.a(Pal.accent, 0.3) : Pal.a(Pal.fg, 0.08)

                            TextEdit {
                                id: txt
                                x: 14
                                y: 11
                                width: parent.width - 28
                                readOnly: true
                                selectByMouse: true
                                wrapMode: TextEdit.Wrap
                                text: d.body
                                textFormat: d.me ? TextEdit.PlainText : TextEdit.MarkdownText
                                color: Pal.fg
                                selectionColor: Pal.accent
                                font.family: Config.font
                                font.pixelSize: 13
                            }
                        }
                    }
                }

                // empty state
                ColumnLayout {
                    visible: msgs.count === 0
                    anchors.centerIn: parent
                    width: parent.width - 20
                    spacing: 12
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "How can I help?"
                        color: Pal.fg; font.family: Config.font; font.bold: true; font.pixelSize: 18
                    }
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: "Ask about Linux, Hyprland, your config, or anything else. Copy an error message, click Attach clipboard, then ask what it means."
                        color: Pal.dim; font.family: Config.font; font.pixelSize: 11
                    }
                    Flow {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        spacing: 8
                        Chip { label: "Explain the clipboard"; onClicked: { clip.running = true; win.send("Explain what I copied.") } }
                        Chip { label: "Fix an error"; onClicked: win.send("I get an error on Fedora. How do I troubleshoot it step by step?") }
                        Chip { label: "Hyprland tips"; onClicked: win.send("Give me 5 useful Hyprland tips.") }
                    }
                }
            }

            Text {
                visible: win.busy
                text: "Thinking…"
                color: Pal.accent; font.family: Config.font; font.pixelSize: 12
            }

            // ---------- input ----------
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Chip { label: "Attach clipboard"; visible: win.attach === ""; onClicked: clip.running = true }
                Chip { label: "Clipboard attached  \uf00d"; visible: win.attach !== ""; active: true; onClicked: win.attach = "" }
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 46
                radius: 23
                color: Pal.a(Pal.fg, 0.08)
                border.width: 1
                border.color: Pal.a(Pal.accent, 0.35)

                TextInput {
                    id: input
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.right: sendBtn.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    color: Pal.fg
                    font.family: Config.font
                    font.pixelSize: 14
                    clip: true
                    Keys.onReturnPressed: { win.send(text); text = "" }
                    Keys.onEnterPressed: { win.send(text); text = "" }
                    Keys.onEscapePressed: win.isOpen = false
                    Text {
                        visible: input.text === ""
                        text: "Ask anything…"
                        color: Pal.dim
                        font.family: Config.font
                        font.pixelSize: 14
                    }
                }
                Rectangle {
                    id: sendBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: 34; height: 34; radius: 17
                    color: sma.containsMouse ? Pal.accent : Pal.a(Pal.accent, 0.6)
                    Text { anchors.centerIn: parent; text: "\uf061"; color: Pal.bg; font.family: Config.font; font.pixelSize: 14 }
                    MouseArea { id: sma; anchors.fill: parent; hoverEnabled: true; onClicked: { win.send(input.text); input.text = "" } }
                }
            }
        }
    }
}
