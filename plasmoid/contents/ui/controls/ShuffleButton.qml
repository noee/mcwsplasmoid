import QtQuick 2.12
import QtQuick.Controls 2.12
import org.kde.plasma.components 3.0 as PComp

PComp.ToolButton {
    id: root
    icon.name: 'media-playlist-shuffle'

    property var _m
    onClicked: {
        if (!_m)
            _m = menuComp.createObject(root)
        else
            _m.popup()
    }

    PComp.ToolTip {
        text: 'Shuffle Mode'
    }

    Component {
        id: menuComp

        Menu {
            id: shuffleMenu
            Component.onCompleted: shuffleMenu.popup()

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

}
