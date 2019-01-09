import QtQuick 2.9
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.4 as QtControls
import org.kde.kirigami 2.4 as Kirigami
import org.kde.plasma.core 2.1 as PlasmaCore

import 'controls'
import 'helpers/utils.js' as Utils

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
                sourceKey: filekey
                sourceSize.height: Math.max(thumbSize/2, 32) //theme.mSize(theme.defaultFont).width * 6
            }
            // link icon
            PlasmaCore.IconItem {
                visible: linked
                source: "link"
            }
            Kirigami.Heading {
                level: lvDel.ListView.isCurrentItem ? 2 : 4
                text: zonename
                Layout.fillWidth: true
                wrapMode: Text.NoWrap
                MouseAreaEx {
                    // popup next track info
                    tipShown: containsMouse && playingnowtracks !== 0
                    tipText: nexttrackdisplay
                    // explicit because MA propogate does not work to ItemDelegate::clicked
                    onClicked: zoneClicked(index)
                }
            }
            // pos display
            Kirigami.Heading {
                Layout.alignment: Qt.AlignRight
                visible: (model.state === PlayerState.Playing || model.state === PlayerState.Paused)
                level: lvDel.ListView.isCurrentItem ? 3 : 5
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
