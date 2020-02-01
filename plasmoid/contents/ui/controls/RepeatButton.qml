import QtQuick 2.8
import QtQuick.Controls 2.5

ToolButton {
    icon.name: 'media-playlist-repeat'
    enabled: playingnowtracks > 0
    onClicked: repeatMenu.open()

    ToolTip {
        text: 'Repeat Mode'
    }

    Menu {
        id: repeatMenu

        onAboutToShow: player.getRepeatMode()

        Repeater {
            model: player.repeatModes
            MenuItem {
                action: modelData
                autoExclusive: true
            }
        }
    }
}
