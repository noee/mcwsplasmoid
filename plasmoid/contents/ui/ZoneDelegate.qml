import QtQuick 2.9
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.4 as QtControls
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.core 2.0 as PlasmaCore

import 'controls'
import 'code/utils.js' as Utils

QtControls.ItemDelegate {
    id: lvDel
    anchors.left: parent.left
    anchors.right: parent.right

    height: cl.implicitHeight

    // explicit because MA propogate does not work to ItemDelegate::clicked
    signal zoneClicked(int index)

    ColumnLayout {
        id: cl
        width: zoneView.width
        spacing: 0

        RowLayout {
            Layout.margins: units.smallSpacing
            // album art
            TrackImage {
                animateLoad: true
                height: thumbSize
                sourceKey: filekey
            }
            // link icon
            PlasmaCore.IconItem {
                visible: linked
                source: "link"
            }
            // zone name
            PlasmaExtras.Heading {
                level: lvDel.ListView.isCurrentItem ? 4 : 5
                text: zonename
                Layout.fillWidth: true
                wrapMode: Text.NoWrap
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    propagateComposedEvents: true
                    // popup next track info
                    QtControls.ToolTip.visible: containsMouse && +playingnowtracks !== 0
                    QtControls.ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                    QtControls.ToolTip.text: nexttrackdisplay
                    // explicit because MA propogate does not work to ItemDelegate::clicked
                    onClicked: { zoneClicked(index) ; mouse.accepted = false}
                }
            }
            // pos display
            PlasmaExtras.Heading {
                Layout.alignment: Qt.AlignRight
                visible: (model.state === mcws.statePlaying || model.state === mcws.statePaused)
                level: lvDel.ListView.isCurrentItem ? 4 : 5
                text: '(%1)'.arg(positiondisplay)
            }
        }

        // track info
        FadeText {
            visible: !abbrevZoneView || lvDel.ListView.isCurrentItem
            Layout.leftMargin: units.smallSpacing
            aText: trackdisplay
            MouseArea {
                anchors.fill: parent
                // popup track detail
                QtControls.ToolTip.visible: pressed && filekey !== '-1'
                QtControls.ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                QtControls.ToolTip.text: Utils.stringifyObj(track)

            }
        }
        // player controls
        Player {
            showTrackSlider: plasmoid.configuration.showTrackSlider
            showVolumeSlider: plasmoid.configuration.showVolumeSlider
            visible: !abbrevZoneView || lvDel.ListView.isCurrentItem
        }
    }
}
