import QtQuick 2.9
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.4 as QtControls
import org.kde.kirigami 2.4 as Kirigami

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
        width: parent.width

        Rectangle {
            height: 1
            Layout.margins: Kirigami.Units.smallSpacing
            Layout.fillWidth: true
            visible: index > 0 && !abbrevZoneView
            color: theme.highlightColor
        }

        // album art and zone name/info
        RowLayout {
            Layout.margins: Kirigami.Units.smallSpacing
            TrackImage {
                sourceKey: filekey
                sourceSize.height: Math.max(thumbSize/2, 32)
            }
            ColumnLayout {
                spacing: 0
                RowLayout {
                    // link icon
                    Kirigami.Icon {
                        visible: linked
                        width: Kirigami.Units.iconSizes.small
                        height: width
                        source: "link"
                    }
                    Kirigami.Heading {
                        level: lvDel.ListView.isCurrentItem ? 2 : 4
                        text: zonename
                        Layout.fillWidth: true
                        MouseAreaEx {
                            // next track info
                            tipText: nexttrackdisplay
                            // explicit because MA propogate does not work to ItemDelegate::clicked
                            onClicked: zoneClicked(index)
                        }
                    }
                    // pos display
                    Kirigami.Heading {
                        visible: (model.state === PlayerState.Playing || model.state === PlayerState.Paused)
                        level: lvDel.ListView.isCurrentItem ? 3 : 5
                        text: '(%1)'.arg(positiondisplay)
                    }
                }
                TrackPosControl {
                    showSlider: model.state === PlayerState.Playing || model.state === PlayerState.Paused
                    visible: plasmoid.configuration.showTrackSlider
                             && (!abbrevZoneView || lvDel.ListView.isCurrentItem)
                }
            }

        }

        // track info
        FadeText {
            visible: !abbrevZoneView || lvDel.ListView.isCurrentItem
            Layout.leftMargin: Kirigami.Units.smallSpacing
            aText: trackdisplay
            font.italic: true
            Layout.fillWidth: true
            MouseAreaEx {
                // popup track detail
                tipShown: pressed && filekey !== '-1'
                tipText: Utils.stringifyObj(track)
                // explicit because MA propogate does not work to ItemDelegate::clicked
                onClicked: zoneClicked(index)
            }
        }

        // player controls
        Player {
            showVolumeSlider: plasmoid.configuration.showVolumeSlider
            visible: !abbrevZoneView || lvDel.ListView.isCurrentItem
        }

    }
}
