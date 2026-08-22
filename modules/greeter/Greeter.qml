pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import M3Shapes

FocusScope {
    id: root

    required property GreeterAuth auth
    required property bool primary

    readonly property color background: "#110e08"
    readonly property color surface: "#110e08"
    readonly property color surfaceContainer: "#1e1910"
    readonly property color surfaceContainerHigh: "#241f14"
    readonly property color surfaceContainerHighest: "#2b2519"
    readonly property color surfaceInk: "#f1e4d1"
    readonly property color surfaceMuted: "#b5aa98"
    readonly property color primaryColour: "#e1c387"
    readonly property color primaryInk: "#513d0e"
    readonly property color primaryContainer: "#654f1f"
    readonly property color secondary: "#d5c4a1"
    readonly property color outline: "#7e7464"
    readonly property color error: "#f97758"
    readonly property string bodyFont: "GoogleSansFlex"
    readonly property string monoFont: "CaskaydiaCove Nerd Font Mono"
    readonly property string iconFont: "Material Symbols Rounded"
    readonly property string infoCommand: Quickshell.env("CAELESTIA_GREETER_INFO") || Quickshell.shellPath("packaging/greetd/system-info")
    readonly property string backgroundSource: Quickshell.env("CAELESTIA_GREETER_BACKGROUND") || Quickshell.shellPath("assets/wallpaper.webp")

    property date now: new Date()
    property string cpuTemp: "--"
    property string memoryPercent: "--"
    property string diskPercent: "--"
    property string uptimeText: "--"
    property string networkName: "Checking..."
    property string batteryPercent: "--"
    property string batteryStatus: "Checking..."
    property string osName: "Linux"
    property string kernelVersion: "--"
    property string hostName: Quickshell.env("HOSTNAME") || "localhost"

    function updateSystemInfo(output: string): void {
        const values = {};
        for (const line of output.trim().split("\n")) {
            const separator = line.indexOf("=");
            if (separator > 0)
                values[line.slice(0, separator)] = line.slice(separator + 1);
        }

        cpuTemp = values.cpu_temp || "--";
        memoryPercent = values.memory_percent || "--";
        diskPercent = values.disk_percent || "--";
        uptimeText = values.uptime || "--";
        networkName = values.network || "Disconnected";
        batteryPercent = values.battery_percent || "--";
        batteryStatus = values.battery_status || "Unavailable";
        osName = values.os || "Linux";
        kernelVersion = values.kernel || "--";
        hostName = values.hostname || hostName;
    }

    function submitPassword(): void {
        const password = passwordField.text;
        passwordField.clear();
        auth.authenticate(password);
    }

    focus: primary
    Component.onCompleted: {
        if (primary)
            passwordField.forceActiveFocus();
    }

    Connections {
        function onRetryRequested(): void {
            passwordField.clear();
            if (root.primary)
                passwordField.forceActiveFocus();
        }

        target: root.auth
    }

    Image {
        anchors.fill: parent
        source: root.backgroundSource
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true

        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 0.45
            blurMax: 32
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#55000000"
    }

    Rectangle {
        id: dashboard

        anchors.centerIn: parent
        width: Math.min(parent.width * 0.88, 1380)
        height: Math.min(parent.height * 0.76, 780)
        radius: 28
        color: Qt.rgba(root.surface.r, root.surface.g, root.surface.b, 0.94)
        border.width: 1
        border.color: Qt.rgba(root.primaryColour.r, root.primaryColour.g, root.primaryColour.b, 0.18)

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 0.8
            shadowVerticalOffset: 10
            shadowColor: "#99000000"
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Math.max(16, dashboard.width * 0.019)
            spacing: 18

            ColumnLayout {
                Layout.preferredWidth: dashboard.width * 0.275
                Layout.fillHeight: true
                spacing: 12

                Card {
                    Layout.fillWidth: true
                    Layout.preferredHeight: dashboard.height * 0.23
                    radius: 24

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 6

                        SectionLabel {
                            text: "NETWORK"
                        }
                        Item {
                            Layout.fillHeight: true
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            MaterialGlyph {
                                text: root.networkName === "Disconnected" ? "wifi_off" : "wifi"
                                color: root.primaryColour
                                font.pixelSize: 34
                                fill: 1
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                BodyText {
                                    Layout.fillWidth: true
                                    text: root.networkName
                                    font.pixelSize: 17
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }
                                BodyText {
                                    text: root.networkName === "Disconnected" ? "No active Wi-Fi" : "Connected"
                                    color: root.outline
                                    font.pixelSize: 12
                                }
                            }
                        }
                    }
                }

                Card {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 10

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 9

                        SectionLabel {
                            text: "SYSTEM"
                        }
                        Item {
                            Layout.preferredHeight: 2
                        }
                        FetchLine {
                            label: "host"
                            value: root.hostName
                        }
                        FetchLine {
                            label: "os"
                            value: root.osName
                        }
                        FetchLine {
                            label: "kernel"
                            value: root.kernelVersion
                        }
                        FetchLine {
                            label: "session"
                            value: "Hyprland / UWSM"
                        }
                        Item {
                            Layout.fillHeight: true
                        }

                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 155
                            implicitHeight: 118

                            MaterialShape {
                                anchors.centerIn: parent
                                implicitSize: 112
                                shape: MaterialShape.Gem
                                color: root.primaryContainer
                                rotation: 18
                            }
                            BodyText {
                                anchors.centerIn: parent
                                text: "C"
                                color: root.primaryColour
                                font.pixelSize: 68
                                font.weight: Font.Black
                                font.variableAxes: ({
                                        "wdth": 42,
                                        "ROND": 20
                                    })
                            }
                        }
                        Item {
                            Layout.fillHeight: true
                        }
                    }
                }

                Card {
                    Layout.fillWidth: true
                    Layout.preferredHeight: dashboard.height * 0.2
                    radius: 10

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 18

                        SectionLabel {
                            text: "POWER"
                        }
                        Item {
                            Layout.fillHeight: true
                        }
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 18

                            PowerAction {
                                icon: "bedtime"
                                label: "Suspend"
                                command: ["systemctl", "suspend"]
                            }
                            PowerAction {
                                icon: "restart_alt"
                                label: "Restart"
                                command: ["systemctl", "reboot"]
                            }
                            PowerAction {
                                icon: "power_settings_new"
                                label: "Power off"
                                command: ["systemctl", "poweroff"]
                                danger: true
                            }
                        }
                        Item {
                            Layout.fillHeight: true
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.preferredWidth: dashboard.width * 0.35
                Layout.fillHeight: true
                spacing: 0

                Item {
                    Layout.fillHeight: true
                }

                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4

                    DisplayText {
                        text: Qt.formatTime(root.now, "hh")
                        font.pixelSize: Math.min(142, dashboard.height * 0.19)
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        DisplayText {
                            text: Qt.formatTime(root.now, "mm")
                            color: root.secondary
                            font.pixelSize: Math.min(66, dashboard.height * 0.09)
                        }

                        Rectangle {
                            width: minutePeriod.implicitWidth + 22
                            height: minutePeriod.implicitHeight + 12
                            radius: 10
                            color: root.surfaceContainerHigh

                            DisplayText {
                                id: minutePeriod

                                anchors.centerIn: parent
                                text: Qt.formatTime(root.now, "AP")
                                color: root.surfaceInk
                                font.pixelSize: 26
                            }
                        }
                    }
                }

                BodyText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: -8
                    text: Qt.formatDate(root.now, "dddd  •  d MMM").toUpperCase()
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                }

                Item {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 26
                    Layout.bottomMargin: 22
                    implicitWidth: 230
                    implicitHeight: 180

                    MaterialShape {
                        anchors.centerIn: parent
                        implicitSize: 220
                        shape: MaterialShape.ClamShell
                        color: root.primaryContainer
                    }
                    MaterialGlyph {
                        anchors.centerIn: parent
                        text: "person"
                        color: root.surfaceInk
                        font.pixelSize: 94
                        weight: 350
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: Math.min(370, dashboard.width * 0.29)
                    implicitHeight: 52
                    radius: 26
                    color: root.surfaceContainerHigh
                    border.width: passwordField.activeFocus ? 2 : 0
                    border.color: root.primaryColour

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 8

                        MaterialGlyph {
                            Layout.leftMargin: 8
                            text: root.auth.authenticating ? "progress_activity" : "lock"
                            color: root.surfaceMuted
                            font.pixelSize: 21

                            RotationAnimation on rotation {
                                running: root.auth.authenticating
                                from: 0
                                to: 360
                                duration: 900
                                loops: Animation.Infinite
                            }
                        }

                        TextInput {
                            id: passwordField

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            enabled: !root.auth.authenticating && root.primary
                            color: root.surfaceInk
                            selectionColor: root.primaryContainer
                            selectedTextColor: root.surfaceInk
                            font.family: root.bodyFont
                            font.pixelSize: 15
                            font.weight: Font.Medium
                            echoMode: TextInput.Password
                            passwordCharacter: "●"
                            verticalAlignment: TextInput.AlignVCenter
                            clip: true
                            onAccepted: root.submitPassword()

                            BodyText {
                                anchors.fill: parent
                                text: root.primary ? (root.auth.authenticating ? "Authenticating..." : "Enter your password") : "Use the primary display"
                                color: root.outline
                                font.pixelSize: 15
                                verticalAlignment: Text.AlignVCenter
                                visible: passwordField.text.length === 0
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            radius: 20
                            color: passwordField.text.length > 0 ? root.primaryColour : root.surfaceContainerHighest

                            MaterialGlyph {
                                anchors.centerIn: parent
                                text: "arrow_forward"
                                color: passwordField.text.length > 0 ? root.primaryInk : root.surfaceMuted
                                font.pixelSize: 22
                                weight: 600
                            }
                            MouseArea {
                                anchors.fill: parent
                                enabled: root.primary && passwordField.text.length > 0 && !root.auth.authenticating
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: root.submitPassword()
                            }
                        }
                    }
                }

                BodyText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 10
                    Layout.maximumWidth: 380
                    text: root.auth.errorMessage
                    color: root.error
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    visible: text.length > 0
                }

                BodyText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 4
                    text: root.auth.username.length > 0 ? root.auth.username : "User is not configured"
                    color: root.surfaceMuted
                    font.family: root.monoFont
                    font.pixelSize: 12
                }

                Item {
                    Layout.fillHeight: true
                }
            }

            ColumnLayout {
                Layout.preferredWidth: dashboard.width * 0.275
                Layout.fillHeight: true
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 124
                    spacing: 9

                    StatShape {
                        Layout.fillWidth: true
                        icon: "device_thermostat"
                        value: `${root.cpuTemp}°`
                        label: "CPU"
                        accent: "#f4c642"
                        shapeType: MaterialShape.Pentagon
                    }
                    StatShape {
                        Layout.fillWidth: true
                        icon: "memory"
                        value: `${root.memoryPercent}%`
                        label: "RAM"
                        accent: "#e19c4c"
                        shapeType: MaterialShape.Cookie4Sided
                    }
                    StatShape {
                        Layout.fillWidth: true
                        icon: "hard_drive"
                        value: `${root.diskPercent}%`
                        label: "DISK"
                        accent: "#b1ad6a"
                        shapeType: MaterialShape.Gem
                    }
                }

                Card {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 10

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 8

                        SectionLabel {
                            text: "STATUS"
                        }
                        Item {
                            Layout.preferredHeight: 8
                        }
                        StatusRow {
                            icon: root.batteryStatus === "Charging" ? "battery_charging_full" : "battery_5_bar"
                            title: "Battery"
                            value: `${root.batteryPercent}%`
                            detail: root.batteryStatus
                            progress: Number(root.batteryPercent) / 100
                        }
                        StatusRow {
                            icon: root.networkName === "Disconnected" ? "wifi_off" : "wifi"
                            title: "Network"
                            value: root.networkName === "Disconnected" ? "Offline" : "Online"
                            detail: root.networkName
                            progress: root.networkName === "Disconnected" ? 0 : 1
                        }
                        StatusRow {
                            icon: "schedule"
                            title: "Uptime"
                            value: root.uptimeText
                            detail: root.hostName
                            progress: -1
                        }
                        Item {
                            Layout.fillHeight: true
                        }
                    }
                }
            }
        }
    }

    Process {
        id: systemInfoProcess

        running: true
        command: [root.infoCommand]

        stdout: StdioCollector {
            onStreamFinished: root.updateSystemInfo(text)
        }
    }

    Rectangle {
        anchors.fill: parent
        z: 1000
        color: "black"
        opacity: root.auth.handoff ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: {
            if (!systemInfoProcess.running)
                systemInfoProcess.running = true;
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    component Card: Rectangle {
        color: root.surfaceContainer
        border.width: 1
        border.color: Qt.rgba(root.surfaceMuted.r, root.surfaceMuted.g, root.surfaceMuted.b, 0.06)
    }

    component BodyText: Text {
        color: root.surfaceInk
        font.family: root.bodyFont
        renderType: Text.NativeRendering
        textFormat: Text.PlainText
    }

    component DisplayText: BodyText {
        color: root.primaryColour
        font.weight: 700
        font.variableAxes: ({
                "wdth": 30,
                "ROND": 20
            })
    }

    component MaterialGlyph: BodyText {
        property real fill
        property int weight: 400

        font.family: root.iconFont
        font.variableAxes: ({
                "FILL": fill,
                "wght": weight,
                "GRAD": -25
            })
    }

    component SectionLabel: BodyText {
        Layout.fillWidth: true
        color: root.surfaceMuted
        font.family: root.monoFont
        font.pixelSize: 13
        font.weight: Font.Bold
    }

    component FetchLine: RowLayout {
        required property string label
        required property string value

        spacing: 6

        BodyText {
            text: `${parent.label}:`
            color: root.surfaceMuted
            font.family: root.monoFont
            font.pixelSize: 13
            font.weight: Font.Bold
        }
        BodyText {
            Layout.fillWidth: true
            text: parent.value
            font.family: root.monoFont
            font.pixelSize: 13
            elide: Text.ElideRight
        }
    }

    component PowerAction: Column {
        id: powerAction

        required property string icon
        required property string label
        required property var command
        property bool danger

        spacing: 5

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 50
            height: 42
            radius: 13
            color: powerAction.danger ? Qt.rgba(root.error.r, root.error.g, root.error.b, 0.22) : root.surfaceContainerHigh

            MaterialGlyph {
                anchors.centerIn: parent
                text: powerAction.icon
                color: powerAction.danger ? root.error : root.surfaceMuted
                font.pixelSize: 22
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(powerAction.command)
            }
        }
        BodyText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: powerAction.label
            color: powerAction.danger ? root.error : root.surfaceMuted
            font.pixelSize: 11
        }
    }

    component StatShape: Item {
        id: statShape

        required property string icon
        required property string value
        required property string label
        required property color accent
        required property int shapeType
        Layout.preferredHeight: 124

        MaterialShape {
            anchors.centerIn: parent
            implicitSize: Math.min(parent.width, parent.height) - 4
            shape: statShape.shapeType
            color: statShape.accent
        }
        Column {
            anchors.centerIn: parent

            MaterialGlyph {
                anchors.horizontalCenter: parent.horizontalCenter
                text: statShape.icon
                color: root.primaryInk
                font.pixelSize: 21
                fill: 1
            }
            BodyText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: statShape.value
                color: root.primaryInk
                font.pixelSize: statShape.value.length > 4 ? 12 : 19
                font.weight: Font.Bold
            }
            BodyText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: statShape.label
                color: Qt.rgba(root.primaryInk.r, root.primaryInk.g, root.primaryInk.b, 0.78)
                font.family: root.monoFont
                font.pixelSize: 9
                font.weight: Font.Bold
            }
        }
    }

    component StatusRow: Rectangle {
        id: statusRow

        required property string icon
        required property string title
        required property string value
        required property string detail
        required property real progress
        Layout.fillWidth: true
        Layout.preferredHeight: 88

        radius: 12
        color: root.surfaceContainerHigh

        RowLayout {
            anchors.fill: parent
            anchors.margins: 13
            spacing: 12

            MaterialGlyph {
                text: statusRow.icon
                color: root.primaryColour
                font.pixelSize: 27
                fill: 1
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    BodyText {
                        Layout.fillWidth: true
                        text: statusRow.title
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }
                    BodyText {
                        text: statusRow.value
                        color: root.primaryColour
                        font.family: root.monoFont
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }
                }
                BodyText {
                    Layout.fillWidth: true
                    text: statusRow.detail
                    color: root.outline
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 3
                    Layout.preferredHeight: 4
                    radius: 2
                    color: root.surfaceContainerHighest
                    visible: statusRow.progress >= 0

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, statusRow.progress))
                        height: parent.height
                        radius: parent.radius
                        color: root.primaryColour
                    }
                }
            }
        }
    }
}
