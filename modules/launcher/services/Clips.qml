pragma Singleton

import QtQuick
import Caelestia.Config
import qs.services as Services

QtObject {
    id: root

    readonly property var list: Services.Clipboard.entries

    function transformSearch(search: string): string {
        const command = `${GlobalConfig.launcher.actionPrefix}clip`;
        return search.length > command.length ? search.slice(command.length).trim() : "";
    }

    function query(search: string): var {
        search = transformSearch(search.trim().replace(/\s+/g, " "));
        const terms = search.toLowerCase().split(" ").filter(term => term);
        const limit = Math.max(Config.launcher.maxShown * 8, 64);
        const results = [];

        for (const item of list) {
            if (!terms.length || terms.every(term => item.searchTextLower.includes(term)))
                results.push(item);
            if (results.length >= limit)
                break;
        }

        return results;
    }
}
