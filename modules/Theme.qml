pragma Singleton

import Quickshell
import QtQuick

Singleton {
    //font
    readonly property FontLoader regularFont: FontLoader {
        source: Qt.resolvedUrl("../assets/fonts/SF-Pro/SF-Pro-Display-Regular.otf")
    }
    readonly property string fontFamily:
        regularFont.status === FontLoader.ready ? regularFont.name : "Sans-Serif"

    readonly property int fontSmall: 11
    readonly property int fontNormal : 13
    readonly property int fontLarge: 16

    //colors
    readonly property color text: "#FFFFFF"
    readonly property color mutedText: "#AAAAAA"

    readonly property color barBackgound: "#00000000"
    readonly property color menuBackgound: "#C02a2a2a"
    readonly property color hoverBackground: "#444444"
    readonly property color separator: "#55FFFFFF"
    readonly property color menuBorder: "#545454"

    // dimenstions
    readonly property int barHeight: 25
    readonly property int barMargin : 15
    readonly property int barSpacing: 4
    readonly property int menuWidht: 200
    readonly property int menuItemHeight: 15
    readonly property int menuPadding: 12
    readonly property int menuMargin: 9
    readonly property int menuSpacing: 4
    readonly property int radius: 4
}
