import QtQuick 2.9
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.4
import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.plasma.extras 2.0 as PE
import org.kde.plasma.components 3.0 as PComp

import 'controls'

ItemDelegate {
    id: lvDel
    width: ListView.view.width
    implicitHeight: cl.height

    background: BackgroundHue {
        source: ti
        lightness: -0.5
        opacity: 1
    }

    // explicit because MA propogate does not work to ItemDelegate::clicked
    signal zoneClicked(int zonendx)

    // Zone Playback options Menu
    // Link menu uses zoneModel Repeater
    Menu {
        id: zoneMenu

        // Model for linked zones menu items
        // def'n { name: zonename, id: zoneid, linked: bool }
        property var linkModel: []

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
            title: "Zone Link"
            enabled: zoneView.count > 1

            // Set link menu settings every time
            onAboutToShow: {
                linkRepeater.model = ''
                zoneMenu.linkModel.length = 0
                let zonelist = linkedzones !== undefined
                    ? linkedzones.split(';')
                    : []

                mcws.zoneModel.forEach((z,i) => {
                    // Include all zones except yourself
                    if (i !== index) {
                        let obj = { name: z.zonename, id: z.zoneid, linked: false }
                        // Another zone is linked?
                        if (zonelist.length > 0) {
                            obj.linked = zonelist.indexOf(z.zoneid.toString()) !== -1
                        }
                        zoneMenu.linkModel.push(obj)
                    }

                })
                linkRepeater.model = zoneMenu.linkModel
            }

            Repeater {
                id: linkRepeater
                model: zoneMenu.linkModel
                MenuItem {
                    text: modelData.name
                    checkable: true
                    checked: modelData.linked
                    icon.name: modelData.linked ? 'link' : 'remove-link'

                    onTriggered: {
                        if (!checked)
                            player.unLinkZone()
                        else {
                            player.linkZone(modelData.id)
                        }
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
                            mcws.audioDevices.setDevice(zoneView.currentIndex, index)
                        }
                    }
                }

            }
        }
    }

    ColumnLayout {
        id: cl
        width: lvDel.width

        // album art
        RowLayout {
            Layout.margins: PlasmaCore.Units.smallSpacing
            ShadowImage {
                id: ti
                sourceKey: filekey
                sourceSize.height: 128
                duration: 700

                MouseAreaEx {
                    id: ma
                    tipText: audiopath
                    onClicked: zoneClicked(index)
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    implicitHeight: btn.height
                    color: PlasmaCore.ColorScope.backgroundColor
                    opacity: ma.containsMouse | btnArea.containsMouse ? .6 : 0
                    Behavior on opacity {
                        NumberAnimation { duration: 300 }
                    }

                    MouseAreaEx {
                        id: btnArea
                        RowLayout {
                            anchors.fill: parent
                            ShuffleButton{
                                id: btn
                            }
                            RepeatButton{}
                            ToolButton {
                                icon.name: 'configure'
                                onClicked: zoneMenu.popup()

                                ToolTip {
                                    text: 'Playback Options'
                                }
                            }

                        }
                    }

                }

            }

            // Track Info
            ColumnLayout {
                Layout.maximumHeight: ti.height + PlasmaCore.Units.largeSpacing
                // Track name
                PE.Heading {
                    text: name
                    Layout.fillWidth: true
                    color: Qt.lighter(PlasmaCore.ColorScope.textColor, 1.5)
                    level: 1
                    elide: Text.ElideRight
                    Layout.maximumHeight: Math.round(ti.height/1.5)

                    MouseAreaEx {
                        tipText: nexttrackdisplay
                        // explicit because MA propogate does not work to ItemDelegate::clicked
                        onClicked: zoneClicked(index)
                        onPressAndHold: logger.log(track)
                    }
                }
                // Artist
                PComp.Label {
                    Layout.fillWidth: true
                    text: artist
                    color: Qt.lighter(PlasmaCore.ColorScope.textColor, 1.5)
                    elide: Text.ElideRight
                    Layout.maximumHeight: Math.round(ti.height/2.5)

                    MouseAreaEx {
                        // explicit because MA propogate does not work to ItemDelegate::clicked
                        onClicked: zoneClicked(index)
                        onPressAndHold: logger.log(track)
                    }
                }
                // Album
                PE.DescriptiveLabel {
                    Layout.fillWidth: true
                    text: album
                    elide: Text.ElideRight
                    Layout.maximumHeight: Math.round(ti.height/2.5)

                    MouseAreaEx {
                        // explicit because MA propogate does not work to ItemDelegate::clicked
                        onClicked: zoneClicked(index)
                        onPressAndHold: logger.log(track)
                    }
                }

                TrackPosControl {
                    showSlider: model.state === PlayerState.Playing || model.state === PlayerState.Paused
                }
            }

        }
        // zone name/info
        RowLayout {
            Layout.margins: PlasmaCore.Units.smallSpacing
            PlasmaCore.IconItem {
                visible: linked
                source: 'link'
                width: PlasmaCore.Units.iconSizes.small
                height: PlasmaCore.Units.iconSizes.small
            }

            PE.Heading {
                text: zonename
                level: 5
                Layout.preferredWidth: Math.round(ti.width)
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                MouseAreaEx {
                    onClicked: { zoneClicked(index) }
                }
            }
            // player controls
            Player {
                showVolumeSlider: plasmoid.configuration.showVolumeSlider
                showStopButton: plasmoid.configuration.showStopButton
            }
        }

    }

    // Current zone indicator
    PlasmaCore.IconItem {
        visible: lvDel.ListView.view.count > 1 && lvDel.ListView.isCurrentItem
        source: 'check-filled'
        anchors.top: lvDel.top
        anchors.right: lvDel.right
        width: PlasmaCore.Units.iconSizes.smallMedium
        height: PlasmaCore.Units.iconSizes.smallMedium
    }

}
