pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import M3Shapes

ColumnLayout {
    id: root

    function forcePasswordFocus(): void {
        passwordInput.forceActiveFocus();
    }

    required property GreeterTheme theme
    required property GreeterAuth auth
    required property real screenHeight
    required property date now
    required property bool primary
    readonly property real centerScale: Math.min(1, (screenHeight || 1440) / 1440)
    readonly property int centerWidth: 600 * centerScale

    Layout.preferredWidth: centerWidth
    Layout.fillWidth: false
    Layout.fillHeight: true
    spacing: theme.spacingLargeIncreased

    GreeterClock {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: root.theme.spacingLarge
        theme: root.theme
        centerScale: root.centerScale
        now: root.now
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDate(root.now, "dddd • d MMM").toUpperCase()
        color: root.theme.surfaceText
        renderType: Text.NativeRendering
        font.family: root.theme.sansFont
        font.pointSize: 16
        font.weight: Font.DemiBold
        font.variableAxes: ({"ROND": 25})
    }

    Item {
        id: profile

        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: root.theme.spacingExtraExtraLarge * root.centerScale
        Layout.bottomMargin: root.theme.spacingExtraLarge * root.centerScale
        implicitWidth: Math.round(root.centerWidth * 0.7)
        implicitHeight: {
            profileShape.height;
            return profileShape.pathBounds().height;
        }

        MaterialShape {
            id: profileShape

            anchors.centerIn: parent
            implicitSize: profile.implicitWidth
            shape: MaterialShape.ClamShell
            color: root.theme.surfaceContainerHighest
        }

        Text {
            anchors.centerIn: parent
            text: "person"
            color: root.theme.surfaceVariantText
            renderType: Text.NativeRendering
            font.family: root.theme.iconFont
            font.pointSize: root.centerWidth / 4
            font.variableAxes: ({
                    "FILL": 0,
                    "wght": 400,
                    "GRAD": -25
                })
        }
    }

    GreeterPasswordInput {
        id: passwordInput

        Layout.alignment: Qt.AlignHCenter
        theme: root.theme
        auth: root.auth
        centerScale: Math.max(0.8, root.centerScale)
        centerWidth: root.centerWidth
        primary: root.primary
    }

    GreeterStateMessage {
        Layout.fillWidth: true
        theme: root.theme
        auth: root.auth
    }
}
