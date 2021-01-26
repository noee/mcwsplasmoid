import QtQuick 2.9
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.15
import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.plasma.extras 2.0 as PE

import 'helpers'
import 'controls'

ItemDelegate {
    id: lvDel
    width: ListView.view.width
    implicitHeight: cl.height
    opacity: ListView.isCurrentItem ? 1 : .4

    Component {
        id: imgComp
        BackgroundHue { source: ti }
    }

    background: Loader {
        sourceComponent: {
            if (useCoverArt)
                imgComp
            else
                useDefaultBkgd
                 ? hueComp
                 : useTheme
                   ? (radialTheme ? radComp: gradComp)
                   : null
        }
    }

    // explicit because MA propogate does not work to ItemDelegate::clicked
    signal zoneClicked(int zonendx)

    // Link menu uses zoneModel Repeater
    // Zone Playback options Menu
    Menu {
        id: zoneMenu

        MenuItem { action: player.clearPlayingNow }
        MenuSeparator {}
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

            // load the link zone model
            // Include all zones except yourself
            // def'n { name: zonename, id: zoneid, linked: bool }
            Component.onCompleted: {
                mcws.zoneModel.forEach((z,i) => {
                    if (i !== index) {
                        linkModel.append({ name: z.zonename
                                       , id: z.zoneid
                                       , linked: false })
                    }
                })
            }

            // Set link menu settings every show
            onAboutToShow: {
                let zonelist = linkedzones === undefined
                    ? []
                    : linkedzones.split(';')

                linkModel.forEach(z => {
                    z.linked = zonelist.length === 0
                                ? false
                                : zonelist.includes(z.id.toString())
                })
            }

            MenuItem {
                text: 'Unlink'
                enabled: linked
                icon.name: 'remove-link'
                onTriggered: player.unLinkZone()
            }
            MenuSeparator {}

            Repeater {
                id: linkRepeater
                model: BaseListModel{ id: linkModel }
                MenuItem {
                    text: name
                    icon.name: linked ? 'edit-link' : ''
                    onTriggered: if (!linked) player.linkZone(id)
                }

            }
        }
        Menu {
            title: "Audio Device"

            onAboutToShow: {
                player.getAudioDevice()
                audioDevices.model = mcws.audioDevices
            }

            Repeater {
                id: audioDevices
                delegate: MenuItem {
                    text: modelData
                    checkable: true
                    checked: index === player.currentAudioDevice
                    autoExclusive: true
                    onTriggered: {
                        if (index !== player.currentAudioDevice) {
                            player.setAudioDevice(index)
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
                thumbnail: false
                sourceSize.height: Math.round(thumbSize*1.5)
                sourceSize.width: Math.round(thumbSize*1.5)
                duration: 700
                shadow.size: PlasmaCore.Units.largeSpacing*2

                MouseAreaEx {
                    id: ma
                    onClicked: zoneClicked(index)
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    implicitHeight: btn.height
                    color: PlasmaCore.ColorScope.backgroundColor
                    opacity: ma.containsMouse | btnArea.containsMouse ? .7 : 0
                    Behavior on opacity {
                        NumberAnimation { duration: 300 }
                    }

                    MouseAreaEx {
                        id: btnArea
                        RowLayout {
                            anchors.fill: parent

                            ShuffleButton{
                                id: btn
                                Layout.fillWidth: true
                            }

                            RepeatButton { Layout.fillWidth: true }

                            ToolButton {
                                icon.name: 'equalizer'
                                Layout.fillWidth: true
                                onClicked: zoneMenu.popup()
                                ToolTip {
                                    text: audiopath ?? 'Playback Options'
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
                    Layout.maximumHeight: Math.round(ti.height*.45)

                    MouseAreaEx {
                        tipText: nexttrackdisplay
                        // explicit because MA propogate does not work to ItemDelegate::clicked
                        onClicked: zoneClicked(index)
                        onPressAndHold: logger.log(track)
                    }
                }
                // Artist
                PE.Heading {
                    text: artist
                    Layout.fillWidth: true
                    color: Qt.lighter(PlasmaCore.ColorScope.textColor, 1.5)
                    level: 3
                    elide: Text.ElideRight
                    Layout.maximumHeight: Math.round(ti.height*.45)

                    MouseAreaEx {
                        // explicit because MA propogate does not work to ItemDelegate::clicked
                        onClicked: zoneClicked(index)
                        onPressAndHold: logger.log(track)
                    }
                }
                // Album
                PE.DescriptiveLabel {
                    text: album
                    Layout.fillWidth: true
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
            PlasmaCore.IconItem {
                visible: linked
                source: 'edit-link'
                width: PlasmaCore.Units.iconSizes.small
                height: PlasmaCore.Units.iconSizes.small
                MouseAreaEx {
                    tipText: 'Click to Unlink Zone'
                    onClicked: player.unLinkZone()
                }
            }

            PE.DescriptiveLabel {
                text: zonename
                Layout.preferredWidth: Math.round(ti.width)
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                MouseAreaEx {
                    onClicked: zoneClicked(index)
                }
            }
            // player controls
            Player {
                showVolumeSlider: plasmoid.configuration.showVolumeSlider
                showStopButton: plasmoid.configuration.showStopButton
            }
        }

    }

}
