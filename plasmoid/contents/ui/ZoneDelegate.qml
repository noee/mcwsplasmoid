import QtQuick 2.9
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.4
import org.kde.kirigami 2.4 as Kirigami

import 'controls'

ItemDelegate {
    id: lvDel
    width: ListView.view.width
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

    Menu {
        id: zoneMenu

        Menu {
            title: 'DSP'
            enabled: model.state !== PlayerState.Stopped

            onAboutToShow: player.getLoudness()

            MenuItem {
                action: player.equalizer
            }
            MenuItem {
                action: player.loudness
            }
        }
        Menu {
            id: linkMenu
            title: "Link to"
            enabled: zoneView.viewer.count > 1
            // Hide/Show/Check/Uncheck menu items based on selected Zone
            onAboutToShow: {
                var z = zoneView.currentZone
                var zonelist = z.linkedzones !== undefined ? z.linkedzones.split(';') : []

                mcws.zoneModel.forEach((zone, ndx) => {
                    linkMenu.itemAt(ndx).visible = z.zoneid !== zone.zoneid
                    linkMenu.itemAt(ndx).checked = zonelist.indexOf(zone.zoneid.toString()) !== -1
                })
            }

            Repeater {
                model: mcws.zoneModel
                MenuItem {
                    text: zonename
                    checkable: true
                    icon.name: checked ? 'link' : 'remove-link'
                    onTriggered: {
                        if (!checked)
                            zoneView.currentPlayer.unLinkZone()
                        else
                            zoneView.currentPlayer.linkZone(zoneid)
                    }
                }

            }
        }
        MenuSeparator {}
        MenuItem { action: player.clearPlayingNow }
        MenuSeparator {}
        MenuItem { action: player.clearAllZones }
        MenuItem { action: player.stopAllZones }
        MenuSeparator {}
        Menu {
            title: "Audio Device"

            onAboutToShow: {
                // Set the model, forces a reset
                mcws.audioDevices.getDevice(index, () =>
                {
                    adevRepeater.model = mcws.audioDevices.items
                })
            }

            Repeater {
                id: adevRepeater
                MenuItem {
                    text: modelData
                    checkable: true
                    checked: index === mcws.audioDevices.currentDevice
                    autoExclusive: true
                    onTriggered: {
                        if (index !== mcws.audioDevices.currentDevice) {
                            mcws.audioDevices.setDevice(zoneView.viewer.currentIndex, index)
                        }
                    }
                }

            }
        }
    }

    ColumnLayout {
        id: cl
        width: parent.width
        Layout.bottomMargin: 5

        // album art and zone name/info
        RowLayout {
            Layout.margins: Kirigami.Units.smallSpacing
            TrackImage {
                id: ti
                sourceKey: filekey
                sourceSize.height: Math.max(thumbSize/2, 32)
                MouseAreaEx {
                    tipText: (audiopath ? audiopath + '\n\n' : '') + 'Click for Playback Options'
                    onClicked: zoneMenu.open()
                }
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
                            text: lvDel.ListView.isCurrentItem
                                  ? nexttrackdisplay
                                  : 'Playing Now:<br>%1'.arg(trackdisplay)
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

                // player controls
                Player {
                    showVolumeSlider: plasmoid.configuration.showVolumeSlider
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
                // explicit because MA propogate does not work to ItemDelegate::clicked
                onClicked: zoneClicked(index)
                onPressAndHold: logger.log(track)
            }
        }

        TrackPosControl {
            showSlider: model.state === PlayerState.Playing || model.state === PlayerState.Paused
            visible: plasmoid.configuration.showTrackSlider
                     && (!abbrevZoneView || lvDel.ListView.isCurrentItem)
        }

    }
}
