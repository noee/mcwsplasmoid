import QtQuick 2.8
import QtQuick.Layouts 1.3
import org.kde.plasma.components 3.0 as PComp
import org.kde.plasma.core 2.0 as PlasmaCore

Item {
    implicitHeight: rl.height

    property bool showButton: true
    property bool showSlider: true
    property bool showLabel: true

    RowLayout {
        id: rl
        spacing: 3

        PComp.ToolButton {
            icon.name: model.mute ? "volume-level-muted" : "volume-level-high"
            visible: showButton
            flat: true
            onClicked: model.player.setMute(!mute)
            checkable: true
            checked: model.mute

            PComp.ToolTip {
                text: model.mute ?  'Volume is muted' : 'Mute'
            }
        }

        PComp.Slider {
            id: control
            visible: showSlider
            value: model.volume
            implicitWidth: PlasmaCore.Units.gridUnit * 5

            onMoved: model.player.setVolume(value)

            PComp.ToolTip {
                visible: showLabel && control.pressed
                text: Math.round(control.value*100) + '%'
                delay: 0
            }
        }
    }
}


