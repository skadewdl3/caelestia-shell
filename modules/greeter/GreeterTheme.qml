pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property string sansFont: "Google Sans Flex"
    readonly property string monoFont: "CaskaydiaCove NF"
    readonly property string iconFont: "Material Symbols Rounded"

    property color background: "#110e08"
    property color surface: "#110e08"
    property color surfaceContainer: "#1e1910"
    property color surfaceContainerHigh: "#241f14"
    property color surfaceContainerHighest: "#2b2519"
    property color surfaceText: "#f1e4d1"
    property color surfaceVariantText: "#b5aa98"
    property color outline: "#7e7464"
    property color outlineVariant: "#4f4739"
    property color shadow: "#000000"
    property color primary: "#e1c387"
    property color primaryText: "#513d0e"
    property color primaryContainer: "#654f1f"
    property color secondary: "#d8c4a0"
    property color secondaryContainer: "#463a1f"
    property color tertiary: "#ffcdad"
    property color error: "#f97758"

    readonly property var termColours: ["#353433", "#c78300", "#f4c642", "#ffe2af", "#b1ad6a", "#e19c4c", "#dfc96f", "#e6d6be"]
    readonly property string schemePath: Quickshell.env("CAELESTIA_GREETER_SCHEME")

    readonly property int spacingExtraSmall: 4
    readonly property int spacingSmall: 8
    readonly property int spacingMedium: 12
    readonly property int spacingLarge: 16
    readonly property int spacingLargeIncreased: 20
    readonly property int spacingExtraLarge: 28
    readonly property int spacingExtraExtraLarge: 48

    readonly property int durationSmall: 200
    readonly property int durationNormal: 400
    readonly property int durationLarge: 600
    readonly property int durationFastSpatial: 350
    readonly property int durationDefaultSpatial: 500
    readonly property int durationFastEffects: 150
    readonly property int durationDefaultEffects: 200
    readonly property int durationSlowEffects: 300

    function applyScheme(data: string): void {
        try {
            const scheme = JSON.parse(data);
            const colours = scheme?.colours;
            if (!colours || typeof colours !== "object")
                return;

            const bindings = {
                background: "background",
                surface: "surface",
                surfaceContainer: "surfaceContainer",
                surfaceContainerHigh: "surfaceContainerHigh",
                surfaceContainerHighest: "surfaceContainerHighest",
                surfaceText: "onSurface",
                surfaceVariantText: "onSurfaceVariant",
                outline: "outline",
                outlineVariant: "outlineVariant",
                shadow: "shadow",
                primary: "primary",
                primaryText: "onPrimary",
                primaryContainer: "primaryContainer",
                secondary: "secondary",
                secondaryContainer: "secondaryContainer",
                tertiary: "tertiary",
                error: "error"
            };

            for (const [propertyName, colourName] of Object.entries(bindings)) {
                const value = colours[colourName];
                if (typeof value === "string" && /^[0-9a-fA-F]{6,8}$/.test(value))
                    root[propertyName] = `#${value}`;
            }
        } catch (error) {
            console.warn(`Unable to load greeter colour scheme: ${error}`);
        }
    }

    readonly property FileView schemeFile: FileView {
        printErrors: false
        path: root.schemePath
        onLoaded: root.applyScheme(text())
    }
}
