pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import M3Shapes

Item {
    id: root

    required property GreeterTheme theme
    required property GreeterAuth auth
    required property real centerScale
    required property bool primary
    readonly property alias placeholderWidth: nonAnimPlaceholder.width
    property string buffer
    readonly property list<int> shapeQueue: {
        const shapes = [MaterialShape.Slanted, MaterialShape.Arch, MaterialShape.Fan, MaterialShape.Arrow, MaterialShape.SemiCircle, MaterialShape.Triangle, MaterialShape.Diamond, MaterialShape.ClamShell, MaterialShape.Pentagon, MaterialShape.Gem, MaterialShape.Sunny, MaterialShape.VerySunny, MaterialShape.Cookie4Sided, MaterialShape.Ghostish, MaterialShape.SoftBurst];
        for (let i = shapes.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [shapes[i], shapes[j]] = [shapes[j], shapes[i]];
        }
        return shapes;
    }

    clip: true

    Connections {
        function onBufferChanged(): void {
            if (root.auth.buffer.length > root.buffer.length) {
                charList.bindImplicitWidth();
            } else if (root.auth.buffer.length === 0) {
                charList.implicitWidth = charList.implicitWidth;
            }
            root.buffer = root.auth.buffer;
        }

        target: root.auth
    }

    TextMetrics {
        id: nonAnimPlaceholder

        text: root.primary ? (root.auth.authenticating ? qsTr("Loading...") : qsTr("Enter your password")) : qsTr("Use the primary display")
        font: placeholder.font
    }

    Text {
        id: placeholder

        anchors.centerIn: parent
        anchors.verticalCenterOffset: 1
        text: nonAnimPlaceholder.text
        color: root.auth.authenticating ? root.theme.secondary : root.theme.outline
        renderType: Text.NativeRendering
        font.family: root.theme.sansFont
        font.pointSize: 14 * root.centerScale
        font.weight: Font.Normal
        font.variableAxes: ({
                "wdth": 110,
                "ROND": 25
            })
        opacity: root.buffer ? 0 : 1

        Behavior on opacity {
            EffectAnimation {}
        }
    }

    ListView {
        id: charList

        readonly property real fullWidth: {
            let width = (count - 1) * spacing;
            for (let i = 0; i < count; i++)
                width += ((itemAtIndex(i) as CharItem)?.nonAnimWidthScale ?? 1) * implicitHeight;
            return width + implicitHeight;
        }

        function bindImplicitWidth(): void {
            widthBehavior.enabled = false;
            implicitWidth = Qt.binding(() => fullWidth);
            widthBehavior.enabled = true;
        }

        anchors.centerIn: parent
        anchors.horizontalCenterOffset: implicitWidth > root.width ? -(implicitWidth - root.width) / 2 : 0
        implicitWidth: fullWidth
        implicitHeight: 14
        orientation: Qt.Horizontal
        spacing: root.theme.spacingExtraSmall
        interactive: false

        model: ScriptModel {
            values: root.buffer.split("")
        }

        delegate: CharItem {}

        Behavior on implicitWidth {
            id: widthBehavior

            SpatialAnimation {}
        }
    }

    component CharItem: Item {
        id: character

        required property int index
        property real nonAnimWidthScale: 1
        implicitHeight: charList.implicitHeight

        ListView.onRemove: {
            appearAnimation.stop();
            removeAnimation.start();
        }

        MaterialShape {
            id: characterShape

            anchors.centerIn: parent
            implicitSize: charList.implicitHeight * 1.5
            shape: root.shapeQueue[character.index % root.shapeQueue.length] ?? MaterialShape.Circle
            color: root.theme.surfaceText

            SequentialAnimation {
                id: appearAnimation

                running: true

                ParallelAnimation {
                    EffectAnimation {
                        target: characterShape
                        property: "opacity"
                        from: 0
                        to: 1
                    }
                    FastSpatialAnimation {
                        target: characterShape
                        property: "scale"
                        from: 0
                        to: 1
                    }
                    EffectAnimation {
                        target: character
                        property: "implicitWidth"
                        from: charList.implicitHeight
                        to: charList.implicitHeight * 1.3
                    }
                    PropertyAction {
                        target: character
                        property: "nonAnimWidthScale"
                        value: 1.5
                    }
                }
                PauseAnimation {
                    duration: 180
                }
                PropertyAction {
                    target: characterShape
                    property: "shape"
                    value: MaterialShape.Circle
                }
                ParallelAnimation {
                    FastSpatialAnimation {
                        target: characterShape
                        property: "scale"
                        to: 2 / 3
                    }
                    EffectAnimation {
                        target: character
                        property: "implicitWidth"
                        to: charList.implicitHeight
                    }
                    PropertyAction {
                        target: character
                        property: "nonAnimWidthScale"
                        value: 1
                    }
                }
            }

            SequentialAnimation {
                id: removeAnimation

                PropertyAction {
                    target: character
                    property: "ListView.delayRemove"
                    value: true
                }
                ParallelAnimation {
                    EffectAnimation {
                        target: characterShape
                        property: "opacity"
                        to: 0
                    }
                    SpatialAnimation {
                        target: characterShape
                        property: "scale"
                        to: 0.5
                    }
                }
                PropertyAction {
                    target: character
                    property: "ListView.delayRemove"
                    value: false
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
}
