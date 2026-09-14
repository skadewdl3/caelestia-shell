pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    required property GreeterTheme theme
    required property GreeterAuth auth
    property string messageText

    implicitHeight: message.implicitHeight

    Connections {
        function onErrorMessageChanged(): void {
            if (root.auth.errorMessage) {
                root.messageText = root.auth.errorMessage;
                exitAnimation.stop();
                if (message.scale < 1)
                    appearAnimation.restart();
                else
                    flashAnimation.restart();
            } else {
                appearAnimation.stop();
                flashAnimation.stop();
                exitAnimation.start();
            }
        }

        function onRetryRequested(): void {
            if (!root.auth.errorMessage)
                return;
            exitAnimation.stop();
            if (message.scale < 1)
                appearAnimation.restart();
            else
                flashAnimation.restart();
        }

        target: root.auth
    }

    Text {
        id: message

        anchors.left: parent.left
        anchors.right: parent.right
        text: root.messageText
        color: root.theme.error
        renderType: Text.NativeRendering
        font.family: root.theme.sansFont
        font.pointSize: 12
        font.variableAxes: ({"ROND": 25})
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        scale: 0.7
        opacity: 0
    }

    NumberAnimation {
        id: appearAnimation

        target: message
        properties: "scale,opacity"
        to: 1
        duration: root.theme.durationDefaultEffects
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.34, 0.8, 0.34, 1, 1, 1]
        onFinished: flashAnimation.restart()
    }

    SequentialAnimation {
        id: flashAnimation

        loops: 2

        NumberAnimation {
            target: message
            property: "opacity"
            to: 0.3
            duration: root.theme.durationSmall
            easing.type: Easing.Linear
        }
        NumberAnimation {
            target: message
            property: "opacity"
            to: 1
            duration: root.theme.durationSmall
            easing.type: Easing.Linear
        }
    }

    ParallelAnimation {
        id: exitAnimation

        NumberAnimation {
            target: message
            property: "scale"
            to: 0.7
            duration: root.theme.durationLarge
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: message
            property: "opacity"
            to: 0
            duration: root.theme.durationLarge
            easing.type: Easing.OutCubic
        }
    }
}
