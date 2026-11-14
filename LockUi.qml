import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io

Item {
    id: ui

    required property var shell

    readonly property real s: Math.min(width / 1920, height / 1080)
    readonly property color orange: "#ff8a1f"
    readonly property color orangeDim: "#6b3510"
    readonly property color red: "#ff2a2a"
    readonly property color green: "#4dff91"
    readonly property color white: "#f3ece4"
    readonly property string serif: "Noto Serif CJK JP"
    readonly property string mono: "Iosevka Nerd Font Mono"
    readonly property string phase: shell.phase
    readonly property color accent: phase === "denied" ? red : phase === "approved" ? green : orange

    // ---------- verdict reveal ----------
    property int revealed: 0
    property bool bandOpen: false
    function startReveal() {
        revealed = 0;
        bandOpen = false;
        reveal.restart();
    }
    onPhaseChanged: {
        if (phase === "approved" || phase === "denied")
            startReveal();
        if (phase === "denied") {
            shake.restart();
            flash.restart();
        }
        if (phase === "approved")
            outro.restart();
        if (phase === "idle" || phase === "deliberating")
            bandOpen = false;
        input.forceActiveFocus();
    }
    Component.onCompleted: {
        if (phase === "approved" || phase === "denied")
            startReveal();
        input.forceActiveFocus();
    }
    Timer {
        id: reveal
        interval: 260
        repeat: true
        onTriggered: {
            ui.revealed++;
            if (ui.revealed >= 3) {
                stop();
                ui.bandOpen = true;
            }
        }
    }
    // CASPER (index 2) is the dissenting vote on a rejection, for flavour.
    function verdict(i) {
        if (phase === "deliberating")
            return "thinking";
        if (phase === "approved")
            return revealed > i ? "yes" : "thinking";
        if (phase === "denied")
            return revealed > i ? (i === 2 ? "yes" : "no") : "thinking";
        return "idle";
    }
    readonly property bool verdictShown: (phase === "approved" || phase === "denied") && revealed >= 3

    // ---------- data ----------
    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
    readonly property var kanjiDays: ["日", "月", "火", "水", "木", "金", "土"]

    property string battery: "--"
    property string batStatus: ""
    property string host: ""
    Process {
        id: sys
        running: true
        command: ["sh", "-c", "uname -n; cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1; cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n");
                ui.host = (Quickshell.env("NERV_HOST") || l[0] || "").toUpperCase();
                ui.battery = Quickshell.env("NERV_BATTERY") || l[1] || "--";
                ui.batStatus = (l[2] || "").toUpperCase();
            }
        }
    }
    Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: sys.running = true
    }

    property real sync: 41.3
    property string hexNoise: ""
    Timer {
        interval: 140
        repeat: true
        running: true
        onTriggered: {
            ui.sync = Math.max(36, Math.min(46, ui.sync + (Math.random() - 0.5) * 0.8));
            let h = "";
            for (let i = 0; i < 4; i++)
                h += (Math.random() * 0xffff | 0).toString(16).toUpperCase().padStart(4, "0") + " ";
            ui.hexNoise = h;
        }
    }

    function bar(pct, n) {
        const f = Math.round(Math.max(0, Math.min(100, pct)) / 100 * n);
        return "■".repeat(f) + "□".repeat(n - f);
    }

    // ---------- background ----------
    Rectangle {
        anchors.fill: parent
        color: "#060302"
    }

    Canvas {
        anchors.fill: parent
        opacity: 0.09
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.strokeStyle = "#ff8a1f";
            ctx.lineWidth = 1;
            const r = 34 * ui.s, w = Math.sqrt(3) * r, h = 1.5 * r;
            for (let row = -1; row * h < height + r; row++) {
                for (let col = -1; col * w < width + w; col++) {
                    const cx = col * w + (Math.abs(row) % 2 ? w / 2 : 0), cy = row * h;
                    ctx.beginPath();
                    for (let k = 0; k < 6; k++) {
                        const a = Math.PI / 3 * k + Math.PI / 6;
                        const x = cx + r * Math.cos(a), y = cy + r * Math.sin(a);
                        if (k === 0)
                            ctx.moveTo(x, y);
                        else
                            ctx.lineTo(x, y);
                    }
                    ctx.closePath();
                    ctx.stroke();
                }
            }
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    // vignette
    Canvas {
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const g = ctx.createRadialGradient(width * 0.45, height * 0.45, height * 0.2, width * 0.5, height * 0.5, width * 0.75);
            g.addColorStop(0, "rgba(0,0,0,0)");
            g.addColorStop(1, "rgba(0,0,0,0.85)");
            ctx.fillStyle = g;
            ctx.fillRect(0, 0, width, height);
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    // big faint kanji watermark
    Text {
        anchors { right: parent.right; bottom: parent.bottom; rightMargin: -40 * ui.s; bottomMargin: 40 * ui.s }
        text: "封鎖"
        color: ui.accent
        opacity: 0.05
        font { family: ui.serif; pixelSize: 520 * ui.s; weight: Font.Black }
        Behavior on color { ColorAnimation { duration: 300 } }
    }

    // ---------- content (shakes on denial) ----------
    Item {
        id: content
        anchors.fill: parent

        SequentialAnimation {
            id: shake
            loops: 1
            NumberAnimation { target: content; property: "x"; to: -18 * ui.s; duration: 45 }
            NumberAnimation { target: content; property: "x"; to: 16 * ui.s; duration: 60 }
            NumberAnimation { target: content; property: "x"; to: -10 * ui.s; duration: 60 }
            NumberAnimation { target: content; property: "x"; to: 6 * ui.s; duration: 60 }
            NumberAnimation { target: content; property: "x"; to: 0; duration: 60 }
        }

        HazardBand {
            id: topBand
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: 30 * ui.s
            s: ui.s
            mono: ui.mono
            stripe: ui.accent
        }

        HazardBand {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 38 * ui.s
            s: ui.s
            mono: ui.mono
            stripe: ui.accent
            reverse: true
            label: "  緊急事態  ·  EMERGENCY  ·  SESSION LOCKED  ·  特務機関  ·  CENTRAL DOGMA  ·  PATTERN BLUE  ·  第一種戦闘配置  ·"
        }

        // ---- top header row ----
        Text {
            x: 110 * ui.s
            y: 62 * ui.s
            text: "SESSION LOCK  //  第3新東京市  中央管制室"
            color: ui.accent
            font { family: ui.mono; pixelSize: 19 * ui.s; bold: true; letterSpacing: 5 * ui.s }
        }
        Text {
            anchors { right: parent.right; rightMargin: 110 * ui.s }
            y: 62 * ui.s
            text: ui.hexNoise
            color: ui.orangeDim
            font { family: ui.mono; pixelSize: 19 * ui.s; letterSpacing: 2 * ui.s }
        }
        Rectangle {
            x: 110 * ui.s
            y: 96 * ui.s
            width: parent.width - 220 * ui.s
            height: 2 * ui.s
            color: ui.accent
            opacity: 0.6
        }

        // ---- left column: clock + date + status ----
        Item {
            id: left
            x: 110 * ui.s
            y: 130 * ui.s
            width: 760 * ui.s
            height: 700 * ui.s

            Text {
                id: clockText
                y: -20 * ui.s
                text: Qt.formatTime(clock.date, "hh:mm")
                color: ui.white
                font { family: ui.serif; pixelSize: 290 * ui.s; weight: Font.Black }
                transform: Scale { xScale: 0.8 }
            }
            Text {
                x: clockText.contentWidth * 0.8 + 18 * ui.s
                y: 92 * ui.s
                text: Qt.formatTime(clock.date, "ss")
                color: ui.accent
                font { family: ui.mono; pixelSize: 54 * ui.s; bold: true }
            }
            Text {
                x: clockText.contentWidth * 0.8 + 20 * ui.s
                y: 158 * ui.s
                text: "SEC"
                color: ui.orangeDim
                font { family: ui.mono; pixelSize: 16 * ui.s; letterSpacing: 4 * ui.s }
            }

            Text {
                id: jpDate
                y: 330 * ui.s
                text: (clock.date.getMonth() + 1) + "月" + clock.date.getDate() + "日  " + ui.kanjiDays[clock.date.getDay()] + "曜日"
                color: ui.white
                font { family: ui.serif; pixelSize: 58 * ui.s; weight: Font.Black }
                transform: Scale { xScale: 0.85 }
            }
            Text {
                y: 412 * ui.s
                text: Qt.formatDate(clock.date, "ddd").toUpperCase() + "  //  " + Qt.formatDate(clock.date, "dd MMM yyyy").toUpperCase() + "  //  " + clock.date.getFullYear() + "年"
                color: ui.accent
                font { family: ui.mono; pixelSize: 22 * ui.s; bold: true; letterSpacing: 4 * ui.s }
            }

            Column {
                y: 480 * ui.s
                spacing: 8 * ui.s
                Repeater {
                    model: [
                        ["OPERATOR", (Quickshell.env("NERV_USER") || Quickshell.env("USER") || "").toUpperCase(), false],
                        ["TERMINAL", ui.host, false],
                        ["POWER CELL", ui.battery + "%  " + ui.bar(Number(ui.battery) || 0, 10) + "  " + ui.batStatus, false],
                        ["SYNC RATIO", ui.sync.toFixed(1) + "%", false],
                        ["PATTERN", "BLUE", true]
                    ]
                    Row {
                        required property var modelData
                        spacing: 0
                        Text {
                            width: 230 * ui.s
                            text: modelData[0] + " " + "·".repeat(Math.max(2, 13 - modelData[0].length))
                            color: ui.orangeDim
                            font { family: ui.mono; pixelSize: 19 * ui.s; letterSpacing: 2 * ui.s }
                        }
                        Text {
                            text: modelData[1]
                            color: modelData[2] ? ui.red : ui.white
                            font { family: ui.mono; pixelSize: 19 * ui.s; bold: true; letterSpacing: 2 * ui.s }
                            SequentialAnimation on opacity {
                                running: modelData[2]
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.15; duration: 500 }
                                NumberAnimation { to: 1; duration: 500 }
                            }
                        }
                    }
                }
            }
        }

        // ---- right column: MAGI ----
        Item {
            id: magi
            width: 680 * ui.s
            height: 560 * ui.s
            x: parent.width - width - 110 * ui.s
            y: 150 * ui.s

            Text {
                text: "MAGI SYSTEM  //  意思決定"
                color: ui.accent
                font { family: ui.mono; pixelSize: 19 * ui.s; bold: true; letterSpacing: 5 * ui.s }
            }

            readonly property real pw: 300 * ui.s
            readonly property real ph: 170 * ui.s

            // links to the core
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: ui.accent
                    strokeWidth: 2 * ui.s
                    fillColor: "transparent"
                    startX: magi.pw / 2; startY: 60 * ui.s + magi.ph
                    PathLine { x: magi.width / 2; y: 300 * ui.s }
                    PathMove { x: magi.width - magi.pw / 2; y: 60 * ui.s + magi.ph }
                    PathLine { x: magi.width / 2; y: 300 * ui.s }
                    PathMove { x: magi.width / 2; y: 300 * ui.s }
                    PathLine { x: magi.width / 2; y: 360 * ui.s }
                }
            }
            Rectangle {
                x: magi.width / 2 - width / 2
                y: 300 * ui.s - height / 2
                width: 86 * ui.s
                height: 30 * ui.s
                color: "#0b0603"
                border { color: ui.accent; width: 2 * ui.s }
                Text {
                    anchors.centerIn: parent
                    text: "MAGI"
                    color: ui.accent
                    font { family: ui.mono; pixelSize: 17 * ui.s; bold: true; letterSpacing: 3 * ui.s }
                }
            }

            MagiPanel {
                x: 0
                y: 60 * ui.s
                width: magi.pw; height: magi.ph
                label: "CASPER·3"
                verdict: ui.verdict(2)
                s: ui.s; serif: ui.serif; mono: ui.mono
                orange: ui.orange; green: ui.green; red: ui.red
            }
            MagiPanel {
                x: magi.width - magi.pw
                y: 60 * ui.s
                width: magi.pw; height: magi.ph
                label: "BALTHASAR·2"
                verdict: ui.verdict(1)
                s: ui.s; serif: ui.serif; mono: ui.mono
                orange: ui.orange; green: ui.green; red: ui.red
            }
            MagiPanel {
                x: magi.width / 2 - magi.pw / 2
                y: 360 * ui.s
                width: magi.pw; height: magi.ph
                label: "MELCHIOR·1"
                verdict: ui.verdict(0)
                s: ui.s; serif: ui.serif; mono: ui.mono
                orange: ui.orange; green: ui.green; red: ui.red
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 556 * ui.s
                text: ui.phase === "deliberating" || (!ui.verdictShown && ui.phase !== "idle") ? "審議中  —  DELIBERATING"
                    : ui.phase === "approved" ? "全会一致  承認  —  UNANIMOUS"
                    : ui.phase === "denied" ? "賛成1 反対2  否決  —  REJECTED"
                    : "待機中  —  AWAITING INPUT"
                color: ui.accent
                font { family: ui.mono; pixelSize: 19 * ui.s; bold: true; letterSpacing: 4 * ui.s }
            }
        }

        // ---- password field ----
        Item {
            id: field
            width: 760 * ui.s
            height: 80 * ui.s
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height - 210 * ui.s

            Text {
                anchors { left: parent.left; bottom: parent.top; bottomMargin: 10 * ui.s }
                text: "AUTHORIZATION CODE  //  認証コード入力"
                color: ui.accent
                font { family: ui.mono; pixelSize: 17 * ui.s; bold: true; letterSpacing: 4 * ui.s }
            }
            Text {
                anchors { right: parent.right; bottom: parent.top; bottomMargin: 10 * ui.s }
                text: ui.shell.failures > 0 ? "FAILED ATTEMPTS: " + ui.shell.failures : "SECURITY LV.A"
                color: ui.shell.failures > 0 ? ui.red : ui.orangeDim
                font { family: ui.mono; pixelSize: 17 * ui.s; bold: true; letterSpacing: 3 * ui.s }
            }

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                readonly property real c: 22 * ui.s
                ShapePath {
                    strokeColor: ui.accent
                    strokeWidth: 2.5 * ui.s
                    fillColor: "#cc0b0603"
                    joinStyle: ShapePath.MiterJoin
                    startX: 0; startY: 0
                    PathLine { x: field.width - 22 * ui.s; y: 0 }
                    PathLine { x: field.width; y: 22 * ui.s }
                    PathLine { x: field.width; y: field.height }
                    PathLine { x: 22 * ui.s; y: field.height }
                    PathLine { x: 0; y: field.height - 22 * ui.s }
                    PathLine { x: 0; y: 0 }
                }
            }

            Text {
                anchors { left: parent.left; leftMargin: 28 * ui.s; verticalCenter: parent.verticalCenter }
                text: "▶"
                color: ui.accent
                font { family: ui.mono; pixelSize: 24 * ui.s }
            }

            Row {
                id: dots
                anchors { left: parent.left; leftMargin: 70 * ui.s; verticalCenter: parent.verticalCenter }
                spacing: 10 * ui.s
                Repeater {
                    model: Math.min(input.text.length, 28)
                    Rectangle {
                        width: 14 * ui.s
                        height: 30 * ui.s
                        color: ui.accent
                        transform: Matrix4x4 { matrix: Qt.matrix4x4(1, -0.25, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1) }
                    }
                }
                Rectangle {
                    width: 14 * ui.s
                    height: 30 * ui.s
                    color: ui.accent
                    visible: ui.phase === "idle" || ui.phase === "denied"
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { to: 0; duration: 450 }
                        NumberAnimation { to: 1; duration: 450 }
                    }
                }
            }

            Text {
                visible: input.text.length === 0 && ui.phase === "idle"
                anchors { left: parent.left; leftMargin: 100 * ui.s; verticalCenter: parent.verticalCenter }
                text: "ENTER CODE  ·  コードを入力せよ"
                color: ui.orangeDim
                font { family: ui.mono; pixelSize: 20 * ui.s; letterSpacing: 4 * ui.s }
            }

            Text {
                visible: ui.phase === "deliberating"
                anchors { left: parent.left; leftMargin: 70 * ui.s; verticalCenter: parent.verticalCenter }
                text: "VERIFYING" + ".".repeat(1 + (dotTick.n % 3))
                color: ui.accent
                font { family: ui.mono; pixelSize: 22 * ui.s; bold: true; letterSpacing: 6 * ui.s }
                Timer {
                    id: dotTick
                    property int n: 0
                    interval: 250
                    repeat: true
                    running: ui.phase === "deliberating"
                    onTriggered: n++
                }
            }

            Text {
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.bottom; topMargin: 14 * ui.s }
                text: ui.phase === "denied" ? (ui.shell.pamMessage !== "" ? ui.shell.pamMessage.toUpperCase() : "ACCESS DENIED  ·  再入力せよ")
                    : ui.phase === "approved" ? "ACCESS GRANTED  ·  ロック解除"
                    : ui.phase === "deliberating" ? "MAGI SYSTEM DELIBERATING"
                    : "PRESS ENTER TO SUBMIT"
                color: ui.phase === "idle" ? ui.orangeDim : ui.accent
                font { family: ui.mono; pixelSize: 16 * ui.s; bold: true; letterSpacing: 5 * ui.s }
            }
        }
    }

    // ---------- scanlines + sweep ----------
    Canvas {
        anchors.fill: parent
        opacity: 0.35
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.fillStyle = "#000000";
            for (let y = 0; y < height; y += 3)
                ctx.fillRect(0, y, width, 1);
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }
    Rectangle {
        width: parent.width
        height: 160 * ui.s
        gradient: Gradient {
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 0.85; color: Qt.rgba(1, 0.54, 0.12, 0.05) }
            GradientStop { position: 1; color: Qt.rgba(1, 0.54, 0.12, 0.12) }
        }
        NumberAnimation on y {
            from: -160 * ui.s
            to: ui.height
            duration: 7000
            loops: Animation.Infinite
        }
    }

    // ---------- verdict band ----------
    Rectangle {
        id: verdictBand
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 170 * ui.s
        color: ui.phase === "approved" ? ui.green : ui.red
        visible: ui.bandOpen
        transform: Scale {
            origin.y: verdictBand.height / 2
            yScale: ui.bandOpen ? 1 : 0
            Behavior on yScale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        }
        Row {
            anchors.centerIn: parent
            spacing: 40 * ui.s
            Text {
                text: ui.phase === "approved" ? "承認" : "否決"
                color: "#0b0603"
                font { family: ui.serif; pixelSize: 130 * ui.s; weight: Font.Black }
                anchors.verticalCenter: parent.verticalCenter
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    text: ui.phase === "approved" ? "ACCESS GRANTED" : "ACCESS DENIED"
                    color: "#0b0603"
                    font { family: ui.mono; pixelSize: 64 * ui.s; bold: true; letterSpacing: 8 * ui.s }
                }
                Text {
                    text: ui.phase === "approved" ? "MAGI: UNANIMOUS APPROVAL  ·  SESSION RELEASED" : "MAGI: MAJORITY REJECTION  ·  ATTEMPT " + ui.shell.failures
                    color: "#0b0603"
                    font { family: ui.mono; pixelSize: 20 * ui.s; bold: true; letterSpacing: 4 * ui.s }
                }
            }
        }
        // auto-dismiss the rejection band so the user can retry
        Timer {
            running: ui.bandOpen && ui.phase === "denied"
            interval: 1300
            onTriggered: ui.bandOpen = false
        }
    }

    // red flash on denial
    Rectangle {
        id: flashRect
        anchors.fill: parent
        color: ui.red
        opacity: 0
        SequentialAnimation {
            id: flash
            NumberAnimation { target: flashRect; property: "opacity"; to: 0.35; duration: 60 }
            NumberAnimation { target: flashRect; property: "opacity"; to: 0; duration: 420 }
        }
    }

    // fade out on unlock
    Rectangle {
        id: fade
        anchors.fill: parent
        color: "black"
        opacity: 0
        SequentialAnimation {
            id: outro
            PauseAnimation { duration: 1250 }
            NumberAnimation { target: fade; property: "opacity"; to: 1; duration: 400 }
        }
    }

    // boot-in: black curtain that wipes away
    Rectangle {
        id: curtain
        property real k: 1
        width: parent.width
        height: parent.height * k
        color: "black"
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 3 * ui.s
            color: ui.orange
        }
        NumberAnimation on k {
            from: 1
            to: 0
            duration: 520
            easing.type: Easing.InOutQuad
        }
    }

    // ---------- input ----------
    TextInput {
        id: input
        width: 1
        height: 1
        opacity: 0
        focus: true
        echoMode: TextInput.Password
        maximumLength: 256
        readOnly: ui.phase === "deliberating" || ui.phase === "approved"
        onAccepted: {
            ui.shell.submit(text);
            text = "";
        }
        onTextChanged: if (text.length > 0 && ui.phase === "denied") ui.shell.phase = "idle"
        Keys.onEscapePressed: {
            if (ui.shell.testMode)
                Qt.quit();
            else
                text = "";
        }
    }
    MouseArea {
        anchors.fill: parent
        onClicked: input.forceActiveFocus()
    }
}
