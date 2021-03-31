import QtQuick 2.12
import QtQuick.Controls 2.12

ToolButton {
    icon.name: 'media-playlist-shuffle'
    onClicked: shuffleMenu.popup()

    ToolTip {
        text: 'Shuffle Mode'
    }

    Menu {
        id: shuffleMenu

        onAboutToShow: player.getShuffleMode()

        MenuItem {
            action: player.shuffle
        }
        MenuSeparator {}
        Repeater {
            model: player.shuffleModes
            MenuItem {
                action: modelData
                autoExclusive: true
            }
        }
    }
}
