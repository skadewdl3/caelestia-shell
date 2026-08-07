pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Greetd

Scope {
    id: root

    readonly property string username: Quickshell.env("CAELESTIA_GREETER_USER")
    readonly property string sessionScript: Quickshell.env("CAELESTIA_GREETER_SESSION") || Quickshell.shellPath("packaging/greetd/start-session")

    property bool authenticating
    property bool submittedPassword
    property bool handoff
    property string errorMessage
    property string password

    signal retryRequested

    function authenticate(password: string): void {
        if (authenticating || password.length === 0)
            return;

        if (username.length === 0) {
            fail("CAELESTIA_GREETER_USER is not configured");
            return;
        }

        if (!Greetd.available) {
            fail("Preview mode - greetd is not connected");
            return;
        }

        root.password = password;
        root.errorMessage = "";
        root.authenticating = true;
        root.submittedPassword = false;
        Greetd.createSession(username);
    }

    function fail(message: string): void {
        root.password = "";
        root.authenticating = false;
        root.submittedPassword = false;
        root.handoff = false;
        root.errorMessage = message || "Authentication failed";
        root.retryRequested();
    }

    Connections {
        target: Greetd

        function onAuthMessage(message: string, error: bool, responseRequired: bool, echoResponse: bool): void {
            if (error)
                root.errorMessage = message;

            if (!responseRequired)
                return;

            if (echoResponse) {
                Greetd.respond(root.username);
            } else if (!root.submittedPassword) {
                root.submittedPassword = true;
                Greetd.respond(root.password);
                root.password = "";
            } else {
                Greetd.respond("");
            }
        }

        function onAuthFailure(message: string): void {
            root.fail(message);
        }

        function onReadyToLaunch(): void {
            root.password = "";
            root.handoff = true;
            handoffTimer.restart();
        }

        function onError(message: string): void {
            root.fail(message);
        }

        function onLaunched(): void {
            Qt.quit();
        }
    }

    Timer {
        id: handoffTimer

        interval: 180
        onTriggered: Greetd.launch([root.sessionScript], [
            "XDG_CURRENT_DESKTOP=Hyprland",
            "XDG_SESSION_DESKTOP=Hyprland",
            "XDG_SESSION_TYPE=wayland"
        ], true)
    }
}
