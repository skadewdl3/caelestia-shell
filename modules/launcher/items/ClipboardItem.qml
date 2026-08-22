pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    required property var modelData
    required property var list

    property bool previewRequested
    property bool previewReady
    property string previewId
    readonly property bool hovered: hoverHandler.hovered

    function preparePreview(): void {
        if (!root.modelData?.image || previewRequested)
            return;

        previewRequested = true;
        previewId = root.modelData.id;
        previewProcess.running = true;
    }

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    Component.onCompleted: preparePreview()
    onModelDataChanged: {
        previewRequested = false;
        previewReady = false;
        previewId = "";
        preparePreview();
    }

    ListView.onRemove: {
        if (root.list.state === "clip")
            removeAnim.start();
    }

    SequentialAnimation {
        id: removeAnim

        PropertyAction {
            target: root
            property: "ListView.delayRemove"
            value: true
        }
        PropertyAction {
            target: root
            property: "enabled"
            value: false
        }
        ParallelAnimation {
            Anim {
                target: root
                property: "opacity"
                to: 0
                type: Anim.DefaultEffects
            }
            Anim {
                target: root
                property: "implicitHeight"
                to: 0
                duration: Tokens.anim.durations.normal
                easing: Tokens.anim.emphasized
            }
        }
        PropertyAction {
            target: root
            property: "ListView.delayRemove"
            value: false
        }
    }

    Process {
        id: previewProcess

        command: [Clipboard.helper, "preview", root.modelData?.id ?? "", root.modelData?.previewPath ?? ""]
        onExited: exitCode => { // qmllint disable signal-handler-parameters
            if (root.modelData?.id === root.previewId)
                root.previewReady = exitCode === 0;
        }
    }

    HoverHandler {
        id: hoverHandler
    }

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: Clipboard.activate(root.modelData, root.list)
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        anchors.margins: Tokens.padding.small

        Loader {
            id: leading

            anchors.verticalCenter: parent.verticalCenter
            sourceComponent: root.modelData?.image ? imagePreview : typeIcon
        }

        Item {
            anchors.left: leading.right
            anchors.leftMargin: Tokens.spacing.medium
            anchors.right: actions.left
            anchors.rightMargin: Tokens.spacing.small
            anchors.verticalCenter: parent.verticalCenter

            implicitHeight: title.implicitHeight + detail.implicitHeight

            StyledText {
                id: title

                width: parent.width
                text: root.modelData?.binary ? (root.modelData?.image ? qsTr("Image") : qsTr("Binary data")) : (root.modelData?.preview || qsTr("Empty text"))
                font: Tokens.font.body.medium
                elide: Text.ElideRight
            }

            StyledText {
                id: detail

                anchors.top: title.bottom
                width: parent.width
                text: root.modelData?.binary ? root.modelData?.preview.replace(/^\[\[ | \]\]$/g, "").replace(/(\d+)x(\d+)/, "$1 × $2") : qsTr("Text")
                font: Tokens.font.body.small
                color: Colours.palette.m3outline
                elide: Text.ElideRight
            }
        }

        Row {
            id: actions

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            spacing: Tokens.spacing.extraSmall

            IconButton {
                type: IconButton.Text
                isRound: true
                icon: "delete"
                inactiveOnColour: Colours.palette.m3error
                font: Tokens.font.icon.medium
                label.fill: 0
                opacity: root.hovered ? 1 : 0
                enabled: root.hovered

                onClicked: Clipboard.deleteEntry(root.modelData)

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            IconButton {
                id: pinButton

                type: IconButton.Text
                isToggle: true
                isRound: true
                checked: root.modelData?.pinned ?? false
                icon: "star"
                font: Tokens.font.icon.medium
                opacity: root.hovered || pinButton.checked ? 1 : 0
                enabled: root.hovered || pinButton.checked

                onClicked: Clipboard.togglePinned(root.modelData)

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }
        }
    }

    Component {
        id: typeIcon

        Item {
            implicitWidth: Tokens.sizes.launcher.itemHeight - Tokens.padding.large
            implicitHeight: implicitWidth

            MaterialIcon {
                anchors.centerIn: parent
                text: root.modelData?.binary ? "attachment" : "content_paste"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.builders.large.scale(1.3).build()
            }
        }
    }

    Component {
        id: imagePreview

        StyledClippingRect {
            implicitWidth: Tokens.sizes.launcher.itemHeight - Tokens.padding.large
            implicitHeight: implicitWidth
            radius: Tokens.rounding.medium
            color: Colours.palette.m3surfaceContainerHigh

            MaterialIcon {
                anchors.centerIn: parent
                text: "image"
                color: Colours.palette.m3outline
            }

            Image {
                anchors.fill: parent
                source: root.previewReady ? Qt.resolvedUrl(root.modelData.previewPath) : ""
                asynchronous: true
                cache: true
                sourceSize.width: width
                sourceSize.height: height
                fillMode: Image.PreserveAspectCrop
            }
        }
    }
}
