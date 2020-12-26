import QtQuick 2.9
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.4
import QtGraphicalEffects 1.15
import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.kirigami 2.8 as Kirigami

import 'controls'

ItemDelegate {
    id: lvDel
    width: ListView.view.width
    implicitHeight: cl.height

    background: HueSaturation {
        lightness: -0.5
        saturation: 1.0
        source: ti
        layer.enabled: true
        layer.effect: GaussianBlur {
            radius: 128
            deviation: 12
            samples: 63
            transparentBorder: false
        }
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
                let z = zoneView.currentZone
                let zonelist = z.linkedzones !== undefined ? z.linkedzones.split(';') : []

                mcws.zoneModel.forEach((zone, ndx) => {
                    linkMenu.itemAt(ndx).checked = zonelist.indexOf(zone.zoneid.toString()) !== -1
                })
            }

            Repeater {
                model: mcws.zoneModel
                MenuItem {
                    text: zonename
                    checkable: true
                    icon.name: checked ? 'link' : 'remove-link'
                    visible: zoneView.currentZone && zoneid !== zoneView.currentZone.zoneid
                            ? true : false

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
        width: lvDel.width

        // album art
        RowLayout {
            Layout.margins: PlasmaCore.Units.smallSpacing
            ShadowImage {
                id: ti
                sourceKey: filekey
                sourceSize.height: thumbSize
                duration: 700
                MouseAreaEx {
                    tipText: audiopath
                    onClicked: zoneClicked(index)
                }
            }
            // Track Info
            ColumnLayout {
                spacing: PlasmaCore.Units.smallSpacing
                // Track name
                Kirigami.Heading {
                    text: name
                    Layout.fillWidth: true
                    level: 1
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    fontSizeMode: Text.VerticalFit
                    elide: Text.ElideRight
                    Layout.maximumHeight: PlasmaCore.Units.gridUnit*5

                    MouseAreaEx {
                        tipText: nexttrackdisplay
                        // explicit because MA propogate does not work to ItemDelegate::clicked
                        onClicked: zoneClicked(index)
                        onPressAndHold: logger.log(track)
                    }
                }
                // Artist
                Kirigami.Heading {
                    Layout.leftMargin: PlasmaCore.Units.smallSpacing
                    Layout.fillWidth: true
                    text: artist
                    textFormat: Text.PlainText
                    fontSizeMode: Text.VerticalFit
                    elide: Text.ElideRight
                    level: 5
                    Layout.maximumHeight: units.gridUnit*2

                    MouseAreaEx {
                        // explicit because MA propogate does not work to ItemDelegate::clicked
                        onClicked: zoneClicked(index)
                        onPressAndHold: logger.log(track)
                    }
                }
                // Album
                Kirigami.Heading {
                    Layout.leftMargin: PlasmaCore.Units.smallSpacing
                    Layout.fillWidth: true
                    text: album
                    textFormat: Text.PlainText
                    fontSizeMode: Text.VerticalFit
                    elide: Text.ElideRight
                    level: 5
                    Layout.maximumHeight: units.gridUnit*2

                    MouseAreaEx {
                        // explicit because MA propogate does not work to ItemDelegate::clicked
                        onClicked: zoneClicked(index)
                        onPressAndHold: logger.log(track)
                    }
                }

                Item {
                    Layout.fillHeight: true
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

            Kirigami.Heading {
                text: zonename
                level: 5
                Layout.preferredWidth: Math.round(cl.width * .28)
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                MouseAreaEx {
                    tipText: 'Playback options'
                    onClicked: { zoneClicked(index); zoneMenu.open() }
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
        source: 'checkbox'
        x: ti.x
        y: ti.y
        width: PlasmaCore.Units.iconSizes.smallMedium
        height: PlasmaCore.Units.iconSizes.smallMedium
    }
}
