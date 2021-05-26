import QtQuick 2.8
import QtQuick.Layouts 1.12
import org.kde.plasma.extras 2.0 as PE
import org.kde.plasma.components 3.0 as PComp
import org.kde.plasma.core 2.0 as PlasmaCore
import '..'

Item {
    implicitHeight: rl.height

    property bool showLabel: true
    property bool showSlider: true

    RowLayout {
        id: rl

        Timer {
            repeat: true
            interval: 1000
            running: plasmoid.expanded
                     && model.state === PlayerState.Playing
            triggeredOnStart: true

            onTriggered: {
                if (!trackPos.disablePosUpdate)
                    trackPos.value = positionms / 10000
            }
        }

        PE.DescriptiveLabel {
            visible: showSlider
            font: PlasmaCore.Theme.smallestFont
            text: elapsedtimedisplay ?? ''
        }


        PComp.Slider {
            id: trackPos

            property bool disablePosUpdate: false

            visible: showSlider
            from: 0
            to: durationms / 10000
            value: 0
            implicitWidth: Math.round(parent.width/2)

            onPressedChanged: {
                if (!pressed) {
                    player.setPlayingPosition(position*to*10000)
                    event.queueCall(500, () => disablePosUpdate = false)
                }
                else
                    disablePosUpdate = true
            }
        }

        PE.DescriptiveLabel {
            visible: showSlider
            font: PlasmaCore.Theme.smallestFont
            text: remainingtimedisplay ?? ''
        }

        PE.DescriptiveLabel {
            visible: showLabel
            font: PlasmaCore.Theme.smallestFont
            text: "[%1]".arg(playingnowpositiondisplay)
        }
    }
}
