pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    property var entries: []
    property bool loaded
    property var usageCounts: ({})
    property var popularEntries: []
    property bool usageLoaded

    function parseLine(line: string): var {
        const match = line.match(/^(\S+)\s+(.*)$/);
        if (!match)
            return null;

        const glyph = match[1];
        const description = match[2].trim();
        const searchText = `${glyph} ${description}`;

        return {
            glyph,
            description,
            searchText,
            searchTextLower: searchText.toLowerCase(),
            frequency: Number(root.usageCounts[glyph]) || 0
        };
    }

    function parse(data: string): var {
        return data.split("\n").map(root.parseLine).filter(entry => entry !== null);
    }

    function reload(): void {
        if (!loaded && !loadProcess.running)
            loadProcess.running = true;
    }

    function recordUse(glyph: string): void {
        const next = Object.assign({}, usageCounts);
        next[glyph] = (Number(next[glyph]) || 0) + 1;
        usageCounts = next;

        for (const entry of entries) {
            if (entry.glyph === glyph)
                entry.frequency = next[glyph];
        }
        rebuildPopular();

        if (usageLoaded)
            usageSaveTimer.restart();
    }

    function applyUsage(): void {
        for (const entry of entries)
            entry.frequency = Number(usageCounts[entry.glyph]) || 0;
        rebuildPopular();
    }

    function rebuildPopular(): void {
        popularEntries = entries.filter(entry => entry.frequency > 0).sort((a, b) => b.frequency - a.frequency);
    }

    function activate(entry: var, list: var): void {
        if (!entry?.glyph)
            return;

        root.recordUse(entry.glyph);
        list.screenState.launcher = false;
        Quickshell.execDetached(["wl-copy", entry.glyph]);
    }

    Component.onCompleted: reload()

    Process {
        id: loadProcess

        command: ["caelestia", "emoji"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = root.parse(text);
                root.rebuildPopular();
                root.loaded = true;
            }
        }
    }

    Timer {
        id: usageSaveTimer

        interval: 250
        onTriggered: usageStorage.setText(JSON.stringify(root.usageCounts))
    }

    FileView {
        id: usageStorage

        printErrors: false
        path: `${Paths.state}/emoji-usage.json`
        onLoaded: {
            try {
                const data = JSON.parse(text());
                root.usageCounts = data && typeof data === "object" && !Array.isArray(data) ? data : {};
            } catch (error) {
                console.warn(`Unable to parse emoji usage: ${error}`);
                root.usageCounts = {};
            }
            root.applyUsage();
            root.usageLoaded = true;
        }
        onLoadFailed: error => {
            root.usageLoaded = true;
            if (error === FileViewError.FileNotFound)
                Qt.callLater(() => setText("{}"));
            else
                console.warn(`Unable to load emoji usage: ${error}`);
        }
    }
}
