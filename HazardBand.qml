import QtQuick

// Scrolling orange/black hazard stripes with an optional marquee label.
Item {
    id: band

    property real s: 1
    property color stripe: "#ff8a1f"
    property string label: ""
    property string mono: ""
    property bool reverse: false
    readonly property real period: 44 * s

    clip: true

    Canvas {
        id: stripes
        width: band.width + band.period * 2
        height: band.height
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.fillStyle = "#0b0603";
            ctx.fillRect(0, 0, width, height);
            ctx.fillStyle = band.stripe;
            const p = band.period, h = height;
            for (let x = -h; x < width + h; x += p) {
                ctx.beginPath();
                ctx.moveTo(x, h);
                ctx.lineTo(x + p / 2, h);
                ctx.lineTo(x + p / 2 + h, 0);
                ctx.lineTo(x + h, 0);
                ctx.closePath();
                ctx.fill();
            }
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        NumberAnimation on x {
            from: band.reverse ? -band.period : 0
            to: band.reverse ? 0 : -band.period
            duration: 1400
            loops: Animation.Infinite
        }
    }

    Rectangle {
        visible: band.label !== ""
        anchors.centerIn: parent
        width: Math.min(band.width * 0.62, 1100 * band.s)
        height: band.height - 8 * band.s
        color: "#0b0603"
        clip: true

        Row {
            id: marquee
            spacing: 0
            anchors.verticalCenter: parent.verticalCenter
            Repeater {
                model: 2
                Text {
                    text: band.label
                    color: band.stripe
                    font { family: band.mono; pixelSize: band.height * 0.48; bold: true; letterSpacing: 4 * band.s }
                }
            }
            NumberAnimation on x {
                from: 0
                to: -marquee.width / 2
                duration: 16000
                loops: Animation.Infinite
            }
        }
    }
}
