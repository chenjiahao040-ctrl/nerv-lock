import QtQuick
import QtQuick.Shapes

// One MAGI unit. verdict: idle | thinking | yes | no
Item {
    id: p

    property string label: ""
    property string verdict: "idle"
    property real s: 1
    property color orange: "#ff8a1f"
    property color green: "#4dff91"
    property color red: "#ff2a2a"
    property string serif: ""
    property string mono: ""
    property bool flick: false
    readonly property real cut: 30 * s

    readonly property color fill: verdict === "yes" ? green
        : verdict === "no" ? red
        : verdict === "thinking" ? (flick ? orange : "#3a1c05")
        : "#0b0603"
    readonly property color ink: verdict === "idle" ? orange
        : (verdict === "thinking" && !flick) ? orange : "#0b0603"

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: p.verdict === "idle" ? p.orange : p.fill
            strokeWidth: 2 * p.s
            fillColor: p.fill
            joinStyle: ShapePath.MiterJoin
            startX: p.cut; startY: 0
            PathLine { x: p.width; y: 0 }
            PathLine { x: p.width; y: p.height - p.cut }
            PathLine { x: p.width - p.cut; y: p.height }
            PathLine { x: 0; y: p.height }
            PathLine { x: 0; y: p.cut }
            PathLine { x: p.cut; y: 0 }
        }
    }

    Text {
        anchors { left: parent.left; top: parent.top; leftMargin: p.cut + 6 * p.s; topMargin: 10 * p.s }
        text: p.label
        color: p.ink
        font { family: p.mono; pixelSize: 17 * p.s; bold: true; letterSpacing: 3 * p.s }
    }

    Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 12 * p.s
        text: p.verdict === "yes" ? "承認" : p.verdict === "no" ? "否決" : p.verdict === "thinking" ? "審議中" : "待機"
        color: p.ink
        font { family: p.serif; pixelSize: (p.verdict === "thinking" ? 52 : 70) * p.s; weight: Font.Black }
        transform: Scale { origin.x: 0; xScale: 0.9 }
    }

    Timer {
        running: p.verdict === "thinking"
        repeat: true
        interval: 75
        onTriggered: {
            p.flick = Math.random() > 0.45;
            interval = 50 + Math.random() * 110;
        }
        onRunningChanged: if (!running) p.flick = false
    }
}
