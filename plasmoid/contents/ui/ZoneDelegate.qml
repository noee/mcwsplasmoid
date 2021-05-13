import QtQuick 2.15
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
    opacity: ListView.isCurrentItem ? 1 : .5

    Behavior on opacity {
        NumberAnimation { duration: 500 }
    }

    // background image
    Component {
        id: imgComp
        BackgroundHue {
            source: ti
            opacity: useDefaultBkgd | useCoverArt
                        ? plasmoid.configuration.themeDark ? .5 : 1
                        : 1
        }
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

    Menu {
        id: streamMenu
        Menu {
            title: 'Stations'
            Repeater {
                model: mcws.stationSources
                delegate: MenuItem {
                    text: modelData
                    icon.name: 'radiotray'
                    onTriggered: {
                        let arr = text.replace(/ /g,'').split('-')
                        console.log(arr)
                        player.playRadioStation(arr[0], arr[1])
                    }
                }
            }
        }
//        Menu {
//            title: 'Streams'
//            Repeater {
//                model: mcws.streamSources
//                delegate: MenuItem {
//                    text: modelData
//                    icon.name: 'radiotray'
//                }
//            }
//        }

    }

    ColumnLayout {
            id: cl
            width: lvDel.width

            // album art and track info
            RowLayout {

                McwsImageUtils.ShadowImage {
                    id: ti
                    sourceKey: filekey
                    imageUtils: mcws.imageUtils
                    sourceSize: Qt.size(Math.round(thumbSize*1.5)
                                        , Math.round(thumbSize*1.5))
                    duration: 750
                    shadow.size: PlasmaCore.Units.largeSpacing*2

                    MouseAreaEx {
                        id: ma
                        onClicked: zoneClicked(index)

                        // control box
                        Rectangle {
                            id: zbox
                            z: 1
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            width: parent.width
                            implicitHeight: PlasmaCore.Units.iconSizes.medium
                            color: PlasmaCore.ColorScope.backgroundColor
                            opacity: ma.containsMouse ? .6 : 0
                            Behavior on opacity {
                                NumberAnimation { duration: 400 }
                            }

                        }

                        // zone controls
                        RowLayout {
                            anchors.centerIn: zbox
                            z: 1
                            opacity: ma.containsMouse ? 1 : 0
                            Behavior on opacity {
                                NumberAnimation { duration: 400 }
                            }

                            ShuffleButton {}

                            RepeatButton {}

                            ToolButton {
                                icon.name: 'streamtuner'
                                onClicked: streamMenu.popup()
                                ToolTip {
                                    text: 'Streaming Stations'
                                }
                            }

                            ToolButton {
                                icon.name: 'equalizer'
                                onClicked: zoneMenu.popup()
                                ToolTip {
                                    text: model.state !== PlayerState.Stopped
                                        ? audiopath
                                        : 'Zone Options'
                                }
                            }
                        }

                    } // ma
                }

                // Track Info
                ColumnLayout {
                    spacing: 0
                    Layout.maximumHeight: ti.height + PlasmaCore.Units.largeSpacing

                    // Track name
                    PE.Heading {
                        text: name
                        color: Qt.lighter(PlasmaCore.ColorScope.textColor, 1.5)
                        level: 1
                        elide: Text.ElideRight
                        lineHeight: .8
                        Layout.fillWidth: true
                        Layout.maximumHeight: Math.round(ti.height*.45)

                        MouseAreaEx {
                            tipText: nexttrackdisplay
                            // explicit because MA propogate does not work to ItemDelegate::clicked
                            onClicked: zoneClicked(index)
                            onPressAndHold: logger.log('Track ' + filekey, track)
                        }
                        FadeBehavior on text {}
                    }

                    // Artist
                    PE.Heading {
                        text: artist
                        Layout.fillWidth: true
                        color: Qt.lighter(PlasmaCore.ColorScope.textColor, 1.5)
                        level: 3
                        lineHeight: 1
                        elide: Text.ElideRight
                        Layout.maximumHeight: Math.round(ti.height*.45)

                        MouseAreaEx {
                            // explicit because MA propogate does not work to ItemDelegate::clicked
                            onClicked: zoneClicked(index)
                        }
                        FadeBehavior on text {}
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
                        }
                        FadeBehavior on text {}
                    }

                    TrackPosControl {
                        showSlider: model.state === PlayerState.Playing
                                    || model.state === PlayerState.Paused
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
