import QtQuick 2.12
import QtQuick.Controls 2.12
import org.kde.plasma.components 3.0 as PComp

PComp.ToolButton {
    id: root
    icon.name: 'media-playlist-shuffle'

    property PComp.Menu _m
    onClicked: {
        if (!_m)
            _m = menuComp.createObject(root)

        _m.popup()
    }

    PComp.ToolTip {
        text: 'Shuffle Mode'
    }

    Component {
        id: menuComp

        PComp.Menu {
            id: shuffleMenu

            onAboutToShow: player.getShuffleMode()

            PComp.MenuItem {
                action: player.shuffle
            }
            PComp.MenuSeparator {}
            Repeater {
                model: player.shuffleModes
                delegate: PComp.MenuItem {
                    action: modelData
                    autoExclusive: true
                }
            }
        }
    }

}
