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

    readonly property GreeterTheme theme: GreeterTheme {}
    readonly property string infoCommand: Quickshell.env("CAELESTIA_GREETER_INFO") || Quickshell.shellPath("packaging/greetd/system-info")
    readonly property string backgroundSource: Quickshell.env("CAELESTIA_GREETER_BACKGROUND") || Quickshell.shellPath("assets/wallpaper.webp")
    readonly property real panelHeight: height * 0.7
    readonly property real panelWidth: panelHeight * 16 / 9
    readonly property real compactSize: lockIcon.implicitHeight + theme.spacingLarge * 4

    property date now: new Date()
    property string cpuTemp: "--"
    property string memoryPercent: "--"
    property string diskPercent: "--"
    property string uptimeText: "--"
    property string networkName: qsTr("Checking...")
    property string batteryPercent: "--"
    property string batteryStatus: qsTr("Checking...")
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
        networkName = values.network || qsTr("Disconnected");
        batteryPercent = values.battery_percent || "--";
        batteryStatus = values.battery_status || qsTr("Unavailable");
        osName = values.os || "Linux";
        kernelVersion = values.kernel || "--";
        hostName = values.hostname || hostName;
    }

    focus: primary

    Connections {
        function onRetryRequested(): void {
            if (root.primary)
                center.forcePasswordFocus();
        }

        function onHandoffChanged(): void {
            if (!root.auth.handoff)
                return;
            initAnimation.stop();
            exitAnimation.start();
        }

        target: root.auth
    }

    Item {
        id: backgroundLayer

        anchors.fill: parent
        opacity: 0

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
                blur: 1
                blurMax: 64
                blurMultiplier: 1
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#55000000"
        }
    }

    Rectangle {
        id: dashboard

        anchors.centerIn: parent
        implicitWidth: root.compactSize
        implicitHeight: root.compactSize
        radius: root.compactSize / 4
        color: root.theme.surface
        opacity: 0.94
        rotation: 180
        scale: 0

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax: 15
            shadowColor: Qt.alpha(root.theme.shadow, 0.7)
        }

        RowLayout {
            id: dashboardContent

            anchors.centerIn: parent
            width: root.panelWidth - 32
            height: root.panelHeight - 32
            spacing: root.theme.spacingLargeIncreased * 2
            opacity: 0
            scale: 0

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: root.theme.spacingMedium

                Card {
                    Layout.fillWidth: true
                    Layout.preferredHeight: dashboardContent.height * 0.24
                    radius: 12
                    bottomLeftRadius: 28

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: root.theme.spacingExtraLarge
                        spacing: root.theme.spacingSmall

                        SectionLabel {
                            text: qsTr("NETWORK")
                        }
                        Item {
                            Layout.fillHeight: true
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: root.theme.spacingMedium

                            MaterialGlyph {
                                text: root.networkName === qsTr("Disconnected") ? "wifi_off" : "wifi"
                                color: root.theme.primary
                                font.pointSize: 26
                                fill: 1
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                BodyText {
                                    Layout.fillWidth: true
                                    text: root.networkName
                                    font.pointSize: 16
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }
                                BodyText {
                                    text: root.networkName === qsTr("Disconnected") ? qsTr("No active Wi-Fi") : qsTr("Connected")
                                    color: root.theme.outline
                                }
                            }
                        }
                    }
                }

                Card {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: root.theme.spacingExtraLarge
                        spacing: root.theme.spacingMedium

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: root.theme.spacingMedium

                            Rectangle {
                                implicitWidth: fetchPrompt.implicitWidth + root.theme.spacingMedium * 2
                                implicitHeight: fetchPrompt.implicitHeight + root.theme.spacingSmall * 2
                                color: root.theme.primary
                                radius: 12

                                MonoText {
                                    id: fetchPrompt

                                    anchors.centerIn: parent
                                    text: ">"
                                    color: root.theme.primaryText
                                }
                            }
                            MonoText {
                                Layout.fillWidth: true
                                text: "caelestiafetch.sh"
                                elide: Text.ElideRight
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: root.theme.spacingExtraLarge

                            Item {
                                Layout.preferredWidth: 112
                                Layout.preferredHeight: 112

                                MaterialShape {
                                    anchors.centerIn: parent
                                    implicitSize: 112
                                    shape: MaterialShape.Gem
                                    color: root.theme.primaryContainer
                                    rotation: 18
                                }
                                BodyText {
                                    anchors.centerIn: parent
                                    text: "C"
                                    color: root.theme.primary
                                    font.pointSize: 52
                                    font.weight: Font.Black
                                    font.variableAxes: ({
                                            "wdth": 42,
                                            "ROND": 20
                                        })
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: root.theme.spacingMedium

                                FetchLine {
                                    label: "OS"
                                    value: root.osName
                                }
                                FetchLine {
                                    label: "KERNEL"
                                    value: root.kernelVersion
                                }
                                FetchLine {
                                    label: "USER"
                                    value: root.auth.username
                                }
                                FetchLine {
                                    label: "UP"
                                    value: root.uptimeText
                                }
                            }
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: root.theme.spacingLargeIncreased

                            Repeater {
                                model: root.theme.termColours

                                Rectangle {
                                    required property color modelData

                                    implicitWidth: 28
                                    implicitHeight: 28
                                    radius: 12
                                    color: modelData
                                }
                            }
                        }
                    }
                }

                Card {
                    Layout.fillWidth: true
                    Layout.preferredHeight: dashboardContent.height * 0.2
                    radius: 12

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: root.theme.spacingLargeIncreased

                        SectionLabel {
                            text: qsTr("POWER")
                        }
                        Item {
                            Layout.fillHeight: true
                        }
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: root.theme.spacingLargeIncreased

                            PowerAction {
                                icon: "bedtime"
                                label: qsTr("Suspend")
                                command: ["systemctl", "suspend"]
                            }
                            PowerAction {
                                icon: "restart_alt"
                                label: qsTr("Restart")
                                command: ["systemctl", "reboot"]
                            }
                            PowerAction {
                                icon: "power_settings_new"
                                label: qsTr("Power off")
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

            GreeterCenter {
                id: center

                theme: root.theme
                auth: root.auth
                screenHeight: root.height
                now: root.now
                primary: root.primary
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: root.theme.spacingMedium

                Card {
                    Layout.fillWidth: true
                    Layout.preferredHeight: resourceRow.implicitHeight + root.theme.spacingLarge * 2
                    radius: 28

                    RowLayout {
                        id: resourceRow

                        anchors.fill: parent
                        anchors.margins: root.theme.spacingLarge
                        spacing: root.theme.spacingLarge

                        ResourceShape {
                            Layout.fillWidth: true
                            icon: "device_thermostat"
                            value: `${root.cpuTemp}°`
                            colour: root.theme.primary
                            shapeColour: "#f4c642"
                            shapeType: MaterialShape.Pentagon
                        }
                        ResourceShape {
                            Layout.fillWidth: true
                            icon: "memory_alt"
                            value: `${root.memoryPercent}%`
                            colour: root.theme.tertiary
                            shapeColour: "#e19c4c"
                            shapeType: MaterialShape.Slanted
                        }
                        ResourceShape {
                            Layout.fillWidth: true
                            icon: "hard_disk"
                            value: `${root.diskPercent}%`
                            colour: root.theme.secondary
                            shapeColour: "#b1ad6a"
                            shapeType: MaterialShape.Gem
                        }
                    }
                }

                Card {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    bottomRightRadius: 28

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: root.theme.spacingLarge
                        spacing: root.theme.spacingMedium

                        SectionLabel {
                            text: qsTr("STATUS")
                        }
                        StatusRow {
                            icon: root.batteryStatus === "Charging" ? "battery_charging_full" : "battery_5_bar"
                            title: qsTr("Battery")
                            value: `${root.batteryPercent}%`
                            detail: root.batteryStatus
                            progress: Number(root.batteryPercent) / 100
                        }
                        StatusRow {
                            icon: root.networkName === qsTr("Disconnected") ? "wifi_off" : "wifi"
                            title: qsTr("Network")
                            value: root.networkName === qsTr("Disconnected") ? qsTr("Offline") : qsTr("Online")
                            detail: root.networkName
                            progress: root.networkName === qsTr("Disconnected") ? 0 : 1
                        }
                        StatusRow {
                            icon: "schedule"
                            title: qsTr("Uptime")
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

        MaterialGlyph {
            id: lockIcon

            anchors.centerIn: parent
            text: "lock"
            color: root.theme.surfaceText
            font.pointSize: 144
            font.weight: Font.Bold
            rotation: 180
        }
    }

    SequentialAnimation {
        id: initAnimation

        running: true

        ParallelAnimation {
            StandardLargeAnimation {
                target: backgroundLayer
                property: "opacity"
                from: 0
                to: 1
            }
            FastSpatialAnimation {
                target: dashboard
                property: "scale"
                from: 0
                to: 1
            }
            FastSpatialAnimation {
                target: dashboard
                property: "rotation"
                from: 180
                to: 360
            }
        }
        ParallelAnimation {
            SpatialAnimation {
                target: dashboard
                property: "implicitWidth"
                to: root.panelWidth
            }
            SpatialAnimation {
                target: dashboard
                property: "implicitHeight"
                to: root.panelHeight
            }
            SpatialAnimation {
                target: dashboard
                property: "radius"
                to: 42
            }
            SpatialAnimation {
                target: dashboardContent
                property: "scale"
                to: 1
            }
            EffectAnimation {
                target: dashboardContent
                property: "opacity"
                to: 1
            }
            SpatialAnimation {
                target: lockIcon
                property: "rotation"
                to: 360
            }
            EffectAnimation {
                target: lockIcon
                property: "opacity"
                to: 0
            }
        }
        ScriptAction {
            script: {
                if (root.primary)
                    center.forcePasswordFocus();
            }
        }
    }

    SequentialAnimation {
        id: exitAnimation

        onFinished: {
            if (root.primary)
                root.auth.launchSession();
        }

        ParallelAnimation {
            SpatialAnimation {
                target: dashboardContent
                property: "scale"
                to: 0
            }
            EffectAnimation {
                target: dashboardContent
                property: "opacity"
                to: 0
            }
            SpatialAnimation {
                target: dashboard
                property: "implicitWidth"
                to: root.compactSize
            }
            SpatialAnimation {
                target: dashboard
                property: "implicitHeight"
                to: root.compactSize
            }
            SpatialAnimation {
                target: dashboard
                property: "radius"
                to: root.compactSize / 4
            }
            EffectAnimation {
                target: lockIcon
                property: "opacity"
                to: 1
            }
            StandardLargeAnimation {
                target: backgroundLayer
                property: "opacity"
                to: 0
            }
        }
        EffectAnimation {
            target: dashboard
            property: "opacity"
            to: 0
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
        color: root.theme.surfaceContainer
    }

    component BodyText: Text {
        color: root.theme.surfaceText
        renderType: Text.NativeRendering
        textFormat: Text.PlainText
        font.family: root.theme.sansFont
        font.pointSize: 12
        font.variableAxes: ({"ROND": 25})
    }

    component MonoText: BodyText {
        font.family: root.theme.monoFont
    }

    component MaterialGlyph: Text {
        property real fill
        property int weight: 400

        color: root.theme.surfaceText
        renderType: Text.NativeRendering
        font.family: root.theme.iconFont
        font.pointSize: 18
        font.variableAxes: ({
                "FILL": fill,
                "wght": weight,
                "GRAD": -25
            })
    }

    component SectionLabel: MonoText {
        Layout.fillWidth: true
        color: root.theme.outline
        font.weight: Font.Medium
    }

    component FetchLine: RowLayout {
        required property string label
        required property string value
        spacing: root.theme.spacingSmall

        MonoText {
            text: `${parent.label}:`
            color: root.theme.surfaceVariantText
            font.weight: Font.Bold
        }
        MonoText {
            Layout.fillWidth: true
            text: parent.value
            elide: Text.ElideRight
        }
    }

    component PowerAction: Column {
        id: action

        required property string icon
        required property string label
        required property var command
        property bool danger
        spacing: root.theme.spacingExtraSmall

        MaterialShape {
            anchors.horizontalCenter: parent.horizontalCenter
            implicitSize: 48
            shape: MaterialShape.Cookie4Sided
            color: action.danger ? Qt.alpha(root.theme.error, 0.22) : root.theme.surfaceContainerHigh
            scale: actionMouse.pressed ? 0.78 : actionMouse.containsMouse ? 0.9 : 1

            Behavior on scale {
                FastSpatialAnimation {}
            }

            MaterialGlyph {
                anchors.centerIn: parent
                text: action.icon
                color: action.danger ? root.theme.error : root.theme.surfaceVariantText
            }
            MouseArea {
                id: actionMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(action.command)
            }
        }
        BodyText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: action.label
            color: action.danger ? root.theme.error : root.theme.surfaceVariantText
            font.pointSize: 11
        }
    }

    component ResourceShape: Item {
        id: resource

        required property string icon
        required property string value
        required property color colour
        required property color shapeColour
        required property int shapeType
        implicitHeight: width

        MaterialShape {
            anchors.centerIn: parent
            implicitSize: resource.width
            shape: resource.shapeType
            color: resource.shapeColour
        }
        ColumnLayout {
            anchors.centerIn: parent
            spacing: -root.theme.spacingExtraSmall

            MaterialGlyph {
                Layout.alignment: Qt.AlignHCenter
                text: resource.icon
                color: root.theme.primaryText
            }
            BodyText {
                Layout.alignment: Qt.AlignHCenter
                text: resource.value
                color: resource.colour
                font.pointSize: 24
                font.weight: Font.Medium
                font.variableAxes: ({
                        "wdth": 50,
                        "ROND": 25
                    })
            }
        }
    }

    component StatusRow: Rectangle {
        id: status

        required property string icon
        required property string title
        required property string value
        required property string detail
        required property real progress
        Layout.fillWidth: true
        Layout.preferredHeight: 88
        radius: 12
        color: root.theme.surfaceContainerHigh

        RowLayout {
            anchors.fill: parent
            anchors.margins: root.theme.spacingMedium
            spacing: root.theme.spacingMedium

            MaterialGlyph {
                text: status.icon
                color: root.theme.primary
                font.pointSize: 20
                fill: 1
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    BodyText {
                        Layout.fillWidth: true
                        text: status.title
                        font.pointSize: 14
                        font.weight: Font.DemiBold
                    }
                    MonoText {
                        text: status.value
                        color: root.theme.primary
                        font.weight: Font.Bold
                    }
                }
                BodyText {
                    Layout.fillWidth: true
                    text: status.detail
                    color: root.theme.outline
                    elide: Text.ElideRight
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 3
                    Layout.preferredHeight: 4
                    radius: 2
                    color: root.theme.surfaceContainerHighest
                    visible: status.progress >= 0

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, status.progress))
                        height: parent.height
                        radius: parent.radius
                        color: root.theme.primary
                    }
                }
            }
        }
    }

    component SpatialAnimation: NumberAnimation {
        duration: root.theme.durationDefaultSpatial
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.38, 1.21, 0.22, 1, 1, 1]
    }

    component FastSpatialAnimation: NumberAnimation {
        duration: root.theme.durationFastSpatial
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.42, 1.67, 0.21, 0.9, 1, 1]
    }

    component EffectAnimation: NumberAnimation {
        duration: root.theme.durationDefaultEffects
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.34, 0.8, 0.34, 1, 1, 1]
    }

    component StandardLargeAnimation: NumberAnimation {
        duration: root.theme.durationLarge
        easing.type: Easing.OutCubic
    }
}
