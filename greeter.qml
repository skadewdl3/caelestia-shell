pragma ComponentBehavior: Bound

//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded

import "modules"
import "modules/greeter"
import QtQuick
import Quickshell

ShellRoot {
    id: root

    GSFLoader {}

    GreeterAuth {
        id: greeterAuth
    }

    Variants {
        model: Quickshell.screens

        FloatingWindow {
            id: window

            required property var modelData

            screen: modelData
            visible: true
            implicitWidth: modelData.width
            implicitHeight: modelData.height
            color: "transparent"
            title: "Caelestia Greeter"

            Greeter {
                anchors.fill: parent
                auth: greeterAuth
                primary: window.modelData === Quickshell.screens[0]
            }
        }
    }
}
