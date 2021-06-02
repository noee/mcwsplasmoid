import QtQuick 2.8
import QtQuick.Layouts 1.12
import org.kde.plasma.extras 2.0 as PE
import org.kde.plasma.components 3.0 as PComp
import org.kde.plasma.core 2.0 as PlasmaCore
import '..'
import '../helpers'

Item {
    id: root
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

        TextMetrics {
            id: timeSize
            font: PlasmaCore.Theme.smallestFont
            text: model.totaltimedisplay
                    ? model.totaltimedisplay === 'Live'
                      ? '00:00' : model.totaltimedisplay
                    : '00:00'
        }

        PE.DescriptiveLabel {
            id: pnPosLabel
            font: PlasmaCore.Theme.smallestFont
            text: model.playingnowpositiondisplay
                  ? "[%1]".arg(model.playingnowpositiondisplay)
                  : ''
        }

        PE.DescriptiveLabel {
            visible: showSlider
            Layout.preferredWidth: timeSize.width
            horizontalAlignment: Text.AlignRight
            font: PlasmaCore.Theme.smallestFont
            text: model.elapsedtimedisplay ?? ''
        }

        PComp.Slider {
            id: trackPos

            property bool disablePosUpdate: false

            from: 0
            to: model.durationms / 10000
            value: 0
            implicitWidth: Math.round(root.width/2)
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
    }
}
