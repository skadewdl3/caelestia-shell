pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    property var entries: []
    property var pinnedKeys: ({})
    readonly property string helper: Quickshell.shellPath("assets/clipboard.sh")
    readonly property string previewDir: `${Paths.cache}/clipboard`

    property bool reloadPending
    property bool pinsLoaded
    property var deleteQueue: []
    property string deletingId

    function entryKey(entry: var): string {
        if (!entry)
            return "";

        return `${entry.binary ? "binary" : "text"}\u001f${entry.preview}`;
    }

    function isPinned(entry: var): bool {
        const key = root.entryKey(entry);
        return key !== "" && root.pinnedKeys[key] === true;
    }

    function sortPinnedFirst(items: var): var {
        const pinned = [];
        const unpinned = [];

        for (const item of items) {
            const isPinned = root.isPinned(item);
            const updated = item.pinned === isPinned ? item : Object.assign({}, item, {
                pinned: isPinned
            });
            (isPinned ? pinned : unpinned).push(updated);
        }

        return [...pinned, ...unpinned];
    }

    function refreshPinState(): void {
        root.entries = root.sortPinnedFirst(root.entries);
    }

    function savePins(): void {
        if (root.pinsLoaded)
            pinsStorage.setText(JSON.stringify(Object.keys(root.pinnedKeys)));
    }

    function setPinned(entry: var, pinned: bool): void {
        const key = root.entryKey(entry);
        if (!key || root.isPinned(entry) === pinned)
            return;

        const next = Object.assign({}, root.pinnedKeys);
        if (pinned)
            next[key] = true;
        else
            delete next[key];

        root.pinnedKeys = next;
        root.refreshPinState();
        root.savePins();
    }

    function togglePinned(entry: var): void {
        root.setPinned(entry, !root.isPinned(entry));
    }

    function deleteEntry(entry: var): void {
        if (!entry || !/^\d+$/.test(entry.id))
            return;

        root.setPinned(entry, false);
        root.entries = root.entries.filter(item => item.id !== entry.id);

        if (!root.deleteQueue.includes(entry.id) && root.deletingId !== entry.id)
            root.deleteQueue = [...root.deleteQueue, entry.id];
        root.runNextDelete();
    }

    function runNextDelete(): void {
        if (deleteProcess.running)
            return;

        if (!root.deleteQueue.length) {
            root.deletingId = "";
            root.reload();
            return;
        }

        root.deletingId = root.deleteQueue[0];
        root.deleteQueue = root.deleteQueue.slice(1);
        deleteProcess.command = [root.helper, "delete", root.deletingId];
        deleteProcess.running = true;
    }

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
        const previous = {};
        for (const entry of root.entries)
            previous[entry.id] = entry;

        const parsed = data.trim().split("\n").map(line => {
            const separator = line.indexOf("\t");
            if (separator < 1)
                return null;

            const id = line.slice(0, separator);
            if (!/^\d+$/.test(id))
                return null;

            const preview = line.slice(separator + 1);
            const binary = preview.startsWith("[[ binary data ");
            const format = binary ? root.imageFormat(preview) : "";
            const existing = previous[id];

            if (existing?.preview === preview && existing.binary === binary && existing.format === format)
                return existing;

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

        return root.sortPinnedFirst(parsed);
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

    Process {
        id: deleteProcess

        onExited: exitCode => { // qmllint disable signal-handler-parameters
            if (exitCode !== 0)
                console.warn(`Unable to delete clipboard item ${root.deletingId}`);
            Qt.callLater(root.runNextDelete);
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

    FileView {
        id: pinsStorage

        printErrors: false
        path: `${Paths.state}/clipboard-pins.json`
        onLoaded: {
            try {
                const data = JSON.parse(text());
                const keys = {};
                if (Array.isArray(data)) {
                    for (const key of data)
                        if (typeof key === "string" && key)
                            keys[key] = true;
                }
                root.pinnedKeys = keys;
            } catch (error) {
                console.warn(`Unable to parse clipboard pins: ${error}`);
                root.pinnedKeys = {};
            }

            root.pinsLoaded = true;
            root.refreshPinState();
        }
        onLoadFailed: error => {
            root.pinsLoaded = true;
            if (error === FileViewError.FileNotFound)
                Qt.callLater(() => setText("[]"));
            else
                console.warn(`Unable to load clipboard pins: ${error}`);
        }
    }
}
