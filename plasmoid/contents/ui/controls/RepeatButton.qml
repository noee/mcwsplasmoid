import QtQuick 2.15
import QtQuick.Controls 2.5
import org.kde.plasma.components 3.0 as PComp

PComp.ToolButton {
    id: root
    icon.name: 'media-playlist-repeat'

    property PComp.Menu _m
    onClicked: {
        if (!_m)
            _m = menuComp.createObject(root)

        _m.popup()
    }

    PComp.ToolTip {
        text: 'Repeat Mode'
    }

    Component {
        id: menuComp

        PComp.Menu {
            id: repeatMenu

            onAboutToShow: player.getRepeatMode()

            Repeater {
                model: player.repeatModes
                delegate: PComp.MenuItem {
                    action: modelData
                    autoExclusive: true
                }
            }
        }
    }

}
