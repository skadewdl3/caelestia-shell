pragma ComponentBehavior: Bound

import QtQuick
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.services as Services
import qs.modules.launcher.services

Item {
    id: root

    required property ScreenState screenState
    required property var panels
    required property real maxHeight

    readonly property int padding: Tokens.padding.large
    readonly property int rounding: Tokens.rounding.extraLarge
    readonly property real listBottomMargin: list.showClips ? shortcutHint.implicitHeight + Tokens.spacing.small * 2 : padding

    function applyLauncherQuery(): void {
        const query = root.screenState.launcherQuery;
        if (!query)
            return;

        search.text = query;
        root.screenState.launcherQuery = "";
        search.forceActiveFocus();
    }

    function activateCurrentItem(): void {
        const currentItem = list.currentList?.currentItem;
        if (currentItem) {
            if (list.showWallpapers) {
                if (Colours.scheme === "dynamic" && currentItem.modelData.path !== Wallpapers.actualCurrent)
                    Wallpapers.previewColourLock = true;
                Wallpapers.setWallpaper(currentItem.modelData.path);
                root.screenState.launcher = false;
            } else if (search.text.startsWith(GlobalConfig.launcher.actionPrefix)) {
                if (search.text.startsWith(`${GlobalConfig.launcher.actionPrefix}calc `))
                    currentItem.onClicked();
                else if (list.showClips)
                    Services.Clipboard.activate(currentItem.modelData, list.currentList);
                else if (list.showEmojis)
                    Services.Emojis.activate(currentItem.modelData, list.currentList);
                else
                    currentItem.modelData.onClicked(list.currentList);
            } else {
                Apps.launch(currentItem.modelData);
                root.screenState.launcher = false;
            }
        }
    }

    function handleClipboardShortcut(event: var): bool {
        if (!list.showClips)
            return false;

        const entry = list.currentList?.currentItem?.modelData;
        if (!entry)
            return false;

        if (event.key === Qt.Key_Delete && (event.modifiers & Qt.ShiftModifier)) {
            if (!event.isAutoRepeat)
                Services.Clipboard.deleteEntry(entry);
            return true;
        }

        if (event.key === Qt.Key_P && (event.modifiers & Qt.ControlModifier)) {
            if (!event.isAutoRepeat)
                Services.Clipboard.togglePinned(entry);
            return true;
        }

        return false;
    }

    implicitWidth: listWrapper.width + padding * 2
    implicitHeight: search.height + listWrapper.height + listBottomMargin + search.anchors.bottomMargin

    Item {
        id: listWrapper

        implicitWidth: list.width
        implicitHeight: list.height + root.padding

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: search.top
        anchors.bottomMargin: root.listBottomMargin

        ContentList {
            id: list

            content: root
            screenState: root.screenState
            panels: root.panels
            maxHeight: root.maxHeight - search.implicitHeight - root.padding * 2 - root.listBottomMargin
            search: search
            padding: root.padding
            rounding: root.rounding
        }
    }

    StyledText {
        id: shortcutHint

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: search.top
        anchors.bottomMargin: Tokens.spacing.small

        text: qsTr("Ctrl+P: pin/unpin    Shift+Delete: delete")
        color: Colours.palette.m3outline
        font: Tokens.font.label.small
        opacity: list.showClips ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    SearchBar {
        id: search

        objectName: "launcherSearch"

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: root.padding
        anchors.bottomMargin: CUtils.clamp(root.padding - Config.border.thickness, 0, root.padding)

        topPadding: Math.round((Tokens.padding.medium + Tokens.padding.large) / 2)
        bottomPadding: Math.round((Tokens.padding.medium + Tokens.padding.large) / 2)

        placeholderText: qsTr("Type \"%1\" for commands").arg(GlobalConfig.launcher.actionPrefix)

        onAccepted: {
            const currentList = list.currentList;
            if (currentList && typeof currentList.flushSearch === "function" && currentList.flushSearch()) {
                Qt.callLater(root.activateCurrentItem);
                return;
            }

            root.activateCurrentItem();
        }

        Keys.onUpPressed: list.currentList?.decrementCurrentIndex()
        Keys.onDownPressed: list.currentList?.incrementCurrentIndex()

        Keys.onEscapePressed: root.screenState.launcher = false

        Keys.onPressed: event => {
            if (root.handleClipboardShortcut(event)) {
                event.accepted = true;
                return;
            }

            if (!GlobalConfig.launcher.vimKeybinds)
                return;

            if (event.modifiers & Qt.ControlModifier) {
                if (event.key === Qt.Key_J || event.key === Qt.Key_N) {
                    list.currentList?.incrementCurrentIndex();
                    event.accepted = true;
                } else if (event.key === Qt.Key_K || event.key === Qt.Key_P) {
                    list.currentList?.decrementCurrentIndex();
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Tab) {
                list.currentList?.incrementCurrentIndex();
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                list.currentList?.decrementCurrentIndex();
                event.accepted = true;
            }
        }

        Component.onCompleted: {
            root.applyLauncherQuery();
            forceActiveFocus();
        }

        Connections {
            function onLauncherChanged(): void {
                if (!root.screenState.launcher)
                    search.text = "";
                else
                    root.applyLauncherQuery();
            }

            function onLauncherQueryChanged(): void {
                if (root.screenState.launcher)
                    root.applyLauncherQuery();
            }

            function onSessionChanged(): void {
                if (!root.screenState.session)
                    search.forceActiveFocus();
            }

            target: root.screenState
        }
    }
}
