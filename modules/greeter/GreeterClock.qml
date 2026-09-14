pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    required property GreeterTheme theme
    required property real centerScale
    required property date now
    property bool useTwelveHourClock: true

    function calcTopOff(metrics: TextMetrics): real {
        return metrics.tightBoundingRect.y - metrics.boundingRect.y;
    }

    implicitWidth: hours.implicitWidth + minutes.implicitWidth + root.theme.spacingSmall
    implicitHeight: hourMetrics.tightBoundingRect.height

    Text {
        id: hours

        y: -root.calcTopOff(hourMetrics)
        text: Qt.formatTime(root.now, "hh")
        color: root.theme.primary
        renderType: Text.NativeRendering
        font.family: root.theme.sansFont
        font.pointSize: 32 * 7 * root.centerScale
        font.weight: Font.Medium
        font.variableAxes: ({
                "wdth": 30,
                "ROND": 25
            })

        TextMetrics {
            id: hourMetrics

            text: hours.text
            font: hours.font
        }
    }

    Text {
        id: minutes

        anchors.right: parent.right
        y: -root.calcTopOff(minuteMetrics)
        text: Qt.formatTime(root.now, "mm")
        color: root.theme.secondary
        renderType: Text.NativeRendering
        font.family: root.theme.sansFont
        font.pointSize: 32 * (root.useTwelveHourClock ? 3.8 : 7) * root.centerScale
        font.weight: Font.Medium
        font.variableAxes: ({
                "wdth": 30,
                "ROND": 25
            })

        TextMetrics {
            id: minuteMetrics

            text: minutes.text
            font: minutes.font
        }
    }

    Rectangle {
        anchors.left: minutes.left
        anchors.leftMargin: minuteMetrics.tightBoundingRect.x
        y: hourMetrics.tightBoundingRect.height - implicitHeight
        visible: root.useTwelveHourClock
        color: root.theme.surfaceContainerHigh
        radius: 16
        implicitWidth: minuteMetrics.tightBoundingRect.width
        implicitHeight: amPmMetrics.tightBoundingRect.height + root.theme.spacingLarge * 2

        Text {
            id: amPm

            anchors.centerIn: parent
            width: amPmMetrics.tightBoundingRect.width
            height: amPmMetrics.tightBoundingRect.height
            transform: Translate {
                x: -amPmMetrics.tightBoundingRect.x
                y: -root.calcTopOff(amPmMetrics)
            }

            text: Qt.formatTime(root.now, "AP")
            color: root.theme.surfaceText
            renderType: Text.NativeRendering
            font.family: root.theme.sansFont
            font.pointSize: 24 * 2 * root.centerScale
            font.weight: Font.Medium
            font.variableAxes: ({
                    "wdth": 30,
                    "ROND": 25
                })

            TextMetrics {
                id: amPmMetrics

                text: amPm.text
                font: amPm.font
            }
        }
    }
}
