pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    property var entries: []
    readonly property string helper: Quickshell.shellPath("assets/clipboard.sh")
    readonly property string previewDir: `${Paths.cache}/clipboard`

    property bool reloadPending

    function imageFormat(preview: string): string {
        const formats = ["png", "jpeg", "jpg", "webp", "gif", "bmp", "tiff", "svg"];
        const lower = preview.toLowerCase();

        for (const format of formats) {
            const pattern = new RegExp(`\\b${format}(?:\\s+\\d+x\\d+)?\\s*\\]\\]$`);
            if (pattern.test(lower))
                return format;
        }

        return "";
    }

    function mimeForFormat(format: string): string {
        switch (format) {
        case "jpg":
        case "jpeg":
            return "image/jpeg";
        case "svg":
            return "image/svg+xml";
        case "tiff":
            return "image/tiff";
        default:
            return `image/${format}`;
        }
    }

    function parseList(data: string): var {
        return data.trim().split("\n").map(line => {
            const separator = line.indexOf("\t");
            if (separator < 1)
                return null;

            const id = line.slice(0, separator);
            if (!/^\d+$/.test(id))
                return null;

            const preview = line.slice(separator + 1);
            const binary = preview.startsWith("[[ binary data ");
            const format = binary ? root.imageFormat(preview) : "";

            return {
                id,
                preview,
                binary,
                format,
                mime: format ? root.mimeForFormat(format) : "application/octet-stream",
                image: format !== "",
                previewPath: `${root.previewDir}/${id}.${format || "bin"}`,
                searchTextLower: preview.toLowerCase()
            };
        }).filter(entry => entry !== null);
    }

    function reload(): void {
        if (listProcess.running) {
            reloadPending = true;
            return;
        }

        listProcess.running = true;
    }

    function scheduleReload(): void {
        reloadTimer.restart();
    }

    function activate(entry: var, list: var): void {
        if (!entry || !/^\d+$/.test(entry.id))
            return;

        list.screenState.launcher = false;
        Quickshell.execDetached([root.helper, "copy", entry.id, entry.binary ? entry.mime : "text/plain;charset=utf-8"]);
    }

    Process {
        id: listProcess

        command: ["cliphist", "list"]

        stdout: StdioCollector {
            onStreamFinished: root.entries = root.parseList(text)
        }

        onExited: { // qmllint disable signal-handler-parameters
            if (root.reloadPending) {
                root.reloadPending = false;
                Qt.callLater(root.reload);
            }
        }
    }

    // Keep the history populated even when Caelestia is used without the full
    // dots configuration, where these watchers are normally started for us.
    Process {
        running: true
        command: ["wl-paste", "--type", "text", "--watch", root.helper, "store"]

        stdout: SplitParser {
            onRead: root.scheduleReload()
        }
    }

    Process {
        running: true
        command: ["wl-paste", "--type", "image", "--watch", root.helper, "store"]

        stdout: SplitParser {
            onRead: root.scheduleReload()
        }
    }

    Timer {
        id: reloadTimer

        interval: 100
        onTriggered: root.reload()
    }
}
