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
    signal zoneClicked(int zonendx)

    ColumnLayout {
        id: cl
        width: zoneView.width
        spacing: 0

        Rectangle {
            height: 1
            Layout.margins: units.smallSpacing
            Layout.fillWidth: true
            visible: index > 0 && !abbrevZoneView
            color: theme.highlightColor
        }

        // album art and zone name/info
        RowLayout {
            Layout.margins: units.smallSpacing
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
            PlasmaExtras.Heading {
                level: lvDel.ListView.isCurrentItem ? 4 : 5
                text: zonename
                Layout.fillWidth: true
                wrapMode: Text.NoWrap
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    // popup next track info
                    QtControls.ToolTip.visible: containsMouse && +playingnowtracks !== 0
                    QtControls.ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                    QtControls.ToolTip.text: nexttrackdisplay
                    // explicit because MA propogate does not work to ItemDelegate::clicked
                    onClicked: zoneClicked(index)
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
            font.italic: true
            Layout.fillWidth: true
            MouseArea {
                anchors.fill: parent
                // popup track detail
                QtControls.ToolTip.visible: pressed && filekey !== '-1'
                QtControls.ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                QtControls.ToolTip.text: Utils.stringifyObj(track)
                // explicit because MA propogate does not work to ItemDelegate::clicked
                onClicked: zoneClicked(index)
            }
        }

        // player controls
        Player {
            showTrackSlider: plasmoid.configuration.showTrackSlider
            showVolumeSlider: plasmoid.configuration.showVolumeSlider
            visible: !abbrevZoneView || lvDel.ListView.isCurrentItem
            Layout.fillWidth: true
        }

    }
}
