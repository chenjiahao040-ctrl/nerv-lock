// NERV / MAGI lock screen for Quickshell.
//   Real lock:  ~/.local/bin/nerv-lock
//   Preview:    NERV_TEST=1 qs -p ~/.local/share/nerv-lock   (password "eva01", Esc quits)
//   Demo state: NERV_TEST=1 NERV_DEMO=deliberating|denied|approved qs -p ...
//   Fullscreen: add NERV_FULL=1   Fake data: NERV_USER, NERV_HOST, NERV_BATTERY
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam

ShellRoot {
    id: root

    readonly property bool testMode: Quickshell.env("NERV_TEST") === "1"
    readonly property string demo: Quickshell.env("NERV_DEMO") || ""

    // idle | deliberating | denied | approved
    property string phase: demo !== "" ? demo : "idle"
    property int failures: 0
    property string pamMessage: ""

    property string pendingPassword: ""
    property double deliberationStart: 0
    property bool pendingSuccess: false
    readonly property int minDeliberation: 1100

    function submit(pw) {
        if (phase === "deliberating" || phase === "approved" || pw.length === 0)
            return;
        pamMessage = "";
        pendingPassword = pw;
        deliberationStart = Date.now();
        phase = "deliberating";
        if (testMode)
            finish(pw === "eva01");
        else
            pam.start();
    }

    // Keep the MAGI "deliberating" for a minimum time so the animation reads.
    function finish(ok) {
        pendingPassword = "";
        pendingSuccess = ok;
        verdictTimer.interval = Math.max(1, minDeliberation - (Date.now() - deliberationStart));
        verdictTimer.restart();
    }

    Timer {
        id: verdictTimer
        onTriggered: {
            if (root.pendingSuccess) {
                root.phase = "approved";
                unlockTimer.restart();
            } else {
                root.failures++;
                root.phase = "denied";
            }
        }
    }

    Timer {
        id: unlockTimer
        interval: 1700
        onTriggered: {
            if (root.testMode) {
                Qt.quit();
                return;
            }
            lock.locked = false;
            quitTimer.restart();
        }
    }

    Timer {
        id: quitTimer
        interval: 250
        onTriggered: Qt.quit()
    }

    PamContext {
        id: pam
        config: "hyprlock"

        onResponseRequiredChanged: {
            if (responseRequired) {
                respond(root.pendingPassword);
                root.pendingPassword = "";
            }
        }
        onPamMessage: {
            if (messageIsError)
                root.pamMessage = message;
        }
        onCompleted: result => root.finish(result === PamResult.Success)
    }

    WlSessionLock {
        id: lock
        locked: !root.testMode

        WlSessionLockSurface {
            color: "black"
            LockUi {
                anchors.fill: parent
                shell: root
            }
        }
    }

    // NERV_TEST=1 NERV_FULL=1: fullscreen overlay preview (used for screenshots).
    LazyLoader {
        active: root.testMode && Quickshell.env("NERV_FULL") === "1"

        PanelWindow {
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "nerv-lock-preview"
            color: "black"
            LockUi {
                anchors.fill: parent
                shell: root
            }
        }
    }

    LazyLoader {
        active: root.testMode && Quickshell.env("NERV_FULL") !== "1"

        FloatingWindow {
            implicitWidth: 1600
            implicitHeight: 900
            color: "black"
            title: "nerv-lock-preview"
            LockUi {
                anchors.fill: parent
                shell: root
            }
        }
    }
}
