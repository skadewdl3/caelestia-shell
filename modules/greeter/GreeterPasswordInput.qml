pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import M3Shapes

Rectangle {
    id: root

    required property GreeterTheme theme
    required property GreeterAuth auth
    required property real centerScale
    required property int centerWidth
    required property bool primary

    implicitWidth: {
        const maximumWidth = centerWidth * 0.8;
        return auth.buffer ? maximumWidth : Math.min(maximumWidth, inputField.placeholderWidth + iconWrapper.implicitWidth + enterButton.implicitWidth + input.spacing * 2 + theme.spacingMedium * 2);
    }
    implicitHeight: input.implicitHeight + theme.spacingSmall
    color: theme.surfaceContainer
    radius: height / 2
    focus: primary

    onActiveFocusChanged: {
        if (primary && !activeFocus)
            forceActiveFocus();
    }

    Keys.onPressed: event => {
        if (root.primary)
            root.auth.handleKey(event);
    }

    Behavior on implicitWidth {
        SpatialAnimation {}
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.IBeamCursor
        onClicked: root.primary && root.forceActiveFocus()
    }

    RowLayout {
        id: input

        anchors.fill: parent
        anchors.margins: root.theme.spacingExtraSmall
        spacing: root.theme.spacingMedium

        Item {
            id: iconWrapper

            Layout.fillHeight: true
            implicitWidth: enterButton.implicitHeight

            Loader {
                anchors.centerIn: parent
                sourceComponent: root.auth.authenticating ? loadingComponent : iconComponent

                Behavior on opacity {
                    EffectAnimation {}
                }
            }

            Component {
                id: iconComponent

                Text {
                    text: "lock"
                    color: root.theme.surfaceVariantText
                    renderType: Text.NativeRendering
                    font.family: root.theme.iconFont
                    font.pointSize: 18 * root.centerScale
                    font.variableAxes: ({
                            "FILL": 0,
                            "wght": 400,
                            "GRAD": -25
                        })
                }
            }

            Component {
                id: loadingComponent

                GreeterLoadingIndicator {
                    theme: root.theme
                    implicitSize: Math.max(18, iconWrapper.height - root.theme.spacingSmall * 2)
                }
            }
        }

        GreeterInputField {
            id: inputField

            Layout.fillWidth: true
            Layout.fillHeight: true
            theme: root.theme
            auth: root.auth
            centerScale: root.centerScale
            primary: root.primary
        }

        Item {
            id: enterButton

            implicitWidth: implicitHeight
            implicitHeight: {
                const height = enterIcon.implicitHeight + root.theme.spacingExtraSmall * 2;
                return height % 2 === 0 ? height : height + 1;
            }

            MaterialShape {
                anchors.fill: parent
                color: root.auth.buffer ? root.theme.primary : root.theme.surfaceContainerHigh
                shape: root.auth.buffer ? MaterialShape.Arrow : MaterialShape.Circle
                scale: !root.auth.buffer ? 1 : enterMouse.pressed ? 0.6 : enterMouse.containsMouse ? 0.8 : 0.7
                rotation: 90

                Behavior on scale {
                    FastSpatialAnimation {}
                }

                Behavior on color {
                    ColorAnimation {
                        duration: root.theme.durationSlowEffects
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Text {
                id: enterIcon

                anchors.centerIn: parent
                text: "arrow_forward"
                color: root.theme.surfaceVariantText
                renderType: Text.NativeRendering
                font.family: root.theme.iconFont
                font.pointSize: 18 * root.centerScale * 1.2
                font.variableAxes: ({
                        "FILL": 0,
                        "wght": 400,
                        "GRAD": -25
                    })
                opacity: root.auth.buffer ? 0 : 1

                Behavior on opacity {
                    EffectAnimation {}
                }
            }

            MouseArea {
                id: enterMouse

                anchors.fill: parent
                hoverEnabled: true
                enabled: root.primary && root.auth.buffer.length > 0 && !root.auth.authenticating
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.auth.submitBuffer()
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
}
