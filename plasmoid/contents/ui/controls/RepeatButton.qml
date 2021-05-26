import QtQuick 2.15
import QtQuick.Controls 2.5
import org.kde.plasma.components 3.0 as PComp

PComp.ToolButton {
    icon.name: 'media-playlist-repeat'
    onClicked: repeatMenu.popup()

    PComp.ToolTip {
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
