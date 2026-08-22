pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var modelData
    required property var list

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: Emojis.activate(root.modelData, root.list)
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        anchors.margins: Tokens.padding.small

        StyledText {
            id: glyph

            anchors.verticalCenter: parent.verticalCenter
            width: Tokens.sizes.launcher.itemHeight - Tokens.padding.large
            height: glyph.width
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: root.modelData?.glyph ?? ""
            font: Tokens.font.title.large
            fontSizeMode: Text.Fit
            minimumPixelSize: 8
            wrapMode: Text.NoWrap
            clip: true
        }

        StyledText {
            id: name

            anchors.left: glyph.right
            anchors.leftMargin: Tokens.spacing.medium
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.modelData?.description ?? ""
            font: Tokens.font.body.small
            color: Colours.palette.m3outline
            elide: Text.ElideRight
        }
    }
}
