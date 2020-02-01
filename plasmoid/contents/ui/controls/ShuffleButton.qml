import QtQuick 2.8
import QtQuick.Controls 2.5

ToolButton {
    icon.name: 'shuffle'
    enabled: playingnowtracks > 0
    onClicked: shuffleMenu.open()

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
