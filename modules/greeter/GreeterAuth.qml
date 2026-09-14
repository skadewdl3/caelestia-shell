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
    property bool launchRequested
    property string errorMessage
    property string password
    property string buffer

    signal retryRequested

    function handleKey(event: KeyEvent): void {
        if (authenticating || handoff)
            return;

        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            submitBuffer();
            event.accepted = true;
        } else if (event.key === Qt.Key_Backspace) {
            if (event.modifiers & Qt.ControlModifier)
                buffer = "";
            else
                buffer = buffer.slice(0, -1);
            event.accepted = true;
        } else if (/^[^\x00-\x1F\x7F-\x9F]+$/.test(event.text)) {
            buffer += event.text;
            event.accepted = true;
        }
    }

    function submitBuffer(): void {
        if (!buffer.length)
            return;
        authenticate(buffer);
    }

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
        root.buffer = "";
        root.authenticating = false;
        root.submittedPassword = false;
        root.handoff = false;
        root.launchRequested = false;
        root.errorMessage = message || "Authentication failed";
        root.retryRequested();
    }

    function launchSession(): void {
        if (!root.handoff || root.launchRequested || !Greetd.available)
            return;

        root.launchRequested = true;
        Greetd.launch([root.sessionScript], ["XDG_CURRENT_DESKTOP=Hyprland", "XDG_SESSION_DESKTOP=Hyprland", "XDG_SESSION_TYPE=wayland"], true);
    }

    Connections {
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
                root.buffer = "";
            } else {
                Greetd.respond("");
            }
        }

        function onAuthFailure(message: string): void {
            root.fail(message);
        }

        function onReadyToLaunch(): void {
            root.password = "";
            root.buffer = "";
            root.handoff = true;
        }

        function onError(message: string): void {
            root.fail(message);
        }

        function onLaunched(): void {
            Qt.quit();
        }

        target: Greetd
    }
}
