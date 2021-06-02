import QtQuick 2.8
import QtQuick.Layouts 1.3
import org.kde.plasma.components 3.0 as PComp
import org.kde.plasma.core 2.0 as PlasmaCore

Item {
    id: root
    implicitHeight: rl.height

    property alias showButton: muteBtn.visible
    property alias showSlider: control.visible
    property bool showLabel: true

    RowLayout {
        id: rl

        PComp.ToolButton {
            id: muteBtn
            icon.name: model.mute ? "volume-level-muted" : "volume-level-high"
            checkable: true
            checked: model.mute
            onClicked: model.player.setMute(!mute)

            PComp.ToolTip {
                text: model.mute ?  'Volume is muted' : 'Mute'
            }
        }

        PComp.Slider {
            id: control
            value: model.volume
            implicitWidth: Math.round(root.width/1.75)

            onMoved: model.player.setVolume(value)

            PComp.ToolTip {
                visible: showLabel && control.pressed
                text: Math.round(control.value*100) + '%'
                delay: 0
            }
        }
    }
}


