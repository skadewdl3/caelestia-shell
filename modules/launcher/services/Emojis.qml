pragma Singleton

import QtQuick
import Caelestia.Config
import qs.services as Services

QtObject {
    id: root

    readonly property var list: Services.Emojis.entries

    function transformSearch(search: string): string {
        const command = `${GlobalConfig.launcher.actionPrefix}emoji`;
        return search.length > command.length ? search.slice(command.length).trim() : "";
    }

    function query(search: string): var {
        search = transformSearch(search.trim().replace(/\s+/g, " "));
        const terms = search.toLowerCase().split(" ").filter(term => term);
        const limit = Math.max(Config.launcher.maxShown * 8, 64);

        if (!terms.length) {
            const results = Services.Emojis.popularEntries.slice(0, limit);
            for (const item of list) {
                if (item.frequency === 0)
                    results.push(item);
                if (results.length >= limit)
                    break;
            }
            return results;
        }

        const used = [];
        const unused = [];

        for (const item of list) {
            if (!terms.every(term => item.searchTextLower.includes(term)))
                continue;

            if (item.frequency > 0) {
                used.push(item);
            } else if (unused.length < limit) {
                unused.push(item);
            }
        }

        used.sort((a, b) => b.frequency - a.frequency);
        return used.concat(unused).slice(0, limit);
    }
}
