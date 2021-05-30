import QtQuick 2.8
import QtQuick.Layouts 1.12
import org.kde.plasma.extras 2.0 as PE
import org.kde.plasma.components 3.0 as PComp
import org.kde.plasma.core 2.0 as PlasmaCore
import '..'
import '../helpers'

Item {
    implicitHeight: rl.height

    property alias showLabel: pnPosLabel.visible
    property alias showSlider: trackPos.visible

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
                    trackPos.value = model.positionms / 10000
            }
        }

        PE.DescriptiveLabel {
            visible: showSlider
            font: PlasmaCore.Theme.smallestFont
            text: model.elapsedtimedisplay ?? ''
        }


        PComp.Slider {
            id: trackPos

            property bool disablePosUpdate: false

            from: 0
            to: model.durationms / 10000
            value: 0
            implicitWidth: Math.round(parent.width/2)
            implicitHeight: PlasmaCore.Units.iconSizes.small

            onPressedChanged: {
                if (!pressed) {
                    player.setPlayingPosition(position*to*10000)
                    event.queueCall(500, () => disablePosUpdate = false)
                }
                else
                    disablePosUpdate = true
            }

            VisibleBehavior on visible {}
        }

        PE.DescriptiveLabel {
            visible: showSlider
            font: PlasmaCore.Theme.smallestFont
            text: model.remainingtimedisplay ?? ''
        }

        PE.DescriptiveLabel {
            id: pnPosLabel
            font: PlasmaCore.Theme.smallestFont
            text: "[%1]".arg(model.playingnowpositiondisplay)
        }
    }
}
