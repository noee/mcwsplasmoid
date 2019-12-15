import QtQuick 2.9
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.4
import org.kde.kirigami 2.4 as Kirigami

import 'controls'
import 'helpers/utils.js' as Utils

ItemDelegate {
    id: lvDel
    width: parent.width
    height: cl.implicitHeight

    background: Rectangle {
        width: parent.width
        height: 1
        color: Kirigami.Theme.disabledTextColor
        opacity: !abbrevZoneView
        anchors.bottom: parent.bottom
    }

    // explicit because MA propogate does not work to ItemDelegate::clicked
    signal zoneClicked(int zonendx)

    ColumnLayout {
        id: cl
        width: parent.width
        Layout.bottomMargin: 5

        // album art and zone name/info
        RowLayout {
            Layout.margins: Kirigami.Units.smallSpacing
            TrackImage {
                sourceKey: filekey
                sourceSize.height: Math.max(thumbSize/2, 32)
            }
            ColumnLayout {
                spacing: 0
                Kirigami.BasicListItem {
                    separatorVisible: false
                    padding: 0
                    reserveSpaceForIcon: linked
                    icon: linked ? 'link' : ''
                    text: zonename
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize + (lvDel.ListView.isCurrentItem ? 3 : 0)

                    MouseArea {
                        id: ma
                        hoverEnabled: true
                        width: parent.width
                        height: parent.height
                        onClicked: zoneClicked(index)

                        ToolTip {
                            id: tt
                            text: qsTr(nexttrackdisplay)
                            visible: ma.containsMouse
                            delay: Qt.styleHints.mousePressAndHoldInterval
                            contentItem: Label {
                                      text: tt.text
                                      font.italic: true
                                      color: Kirigami.Theme.textColor
                                      textFormat: Text.StyledText
                            }
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
        RowLayout {
            visible: !abbrevZoneView || lvDel.ListView.isCurrentItem
            Player {
                showVolumeSlider: plasmoid.configuration.showVolumeSlider
            }
            ToolButton {
                icon.name: 'configure'
                onClicked: {
                    zoneView.currentIndex = index
                    zoneMenu.open(this)
                }
            }
        }

    }
}
