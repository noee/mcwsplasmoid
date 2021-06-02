import QtQuick 2.15
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.15
import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.plasma.extras 2.0 as PE
import org.kde.plasma.components 3.0 as PComp

import 'helpers'
import 'controls'
import 'theme'

ItemDelegate {
    id: lvDel
    implicitHeight: cl.height
    implicitWidth: ListView.view.width
    opacity: ListView.isCurrentItem ? 1 : .5

    onClicked: ListView.view.currentIndex = index

    Behavior on opacity {
        NumberAnimation { duration: 500 }
    }

    background: BaseBackground {
        theme: backgroundTheme
        source: ti
    }

    function zoneClicked(ndx) {
        ListView.view.currentIndex = ndx
    }

    // Zone Playback options Menu
    // Link menu uses zoneModel Repeater
    Component {
        id: zmComp

        PComp.Menu {
            id: zoneMenu
            Component.onCompleted: zoneMenu.popup()

            PComp.MenuItem { action: player.clearPlayingNow }
            PComp.MenuSeparator {}
            PComp.Menu {
                title: 'DSP'
                enabled: model.state !== PlayerState.Stopped

                onAboutToShow: player.getLoudness()

                PComp.MenuItem {
                    action: player.equalizer
                }
                PComp.MenuItem {
                    action: player.loudness
                }
            }
            PComp.Menu {
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

                PComp.MenuItem {
                    text: 'Unlink'
                    enabled: linked
                    icon.name: 'remove-link'
                    onTriggered: player.unLinkZone()
                }
                PComp.MenuSeparator {}

                Repeater {
                    id: linkRepeater
                    model: BaseListModel{ id: linkModel }
                    PComp.MenuItem {
                        text: name
                        icon.name: linked ? 'edit-link' : ''
                        onTriggered: if (!linked) player.linkZone(id)
                    }

                }
            }
            PComp.Menu {
                id: audioMenu
                title: "Audio Device"

                onAboutToShow: {
                    // make sure device is current
                    player.getAudioDevice()
                }

                Repeater {
                    id: audioDevices
                    model: mcws.audioDevices
                    delegate: PComp.MenuItem {
                        text: '(%1) %2'.arg(device).arg(devicePlugin)
                        checkable: true
                        checked: index === player.audioDevice  // index is for menu model
                        autoExclusive: true
                        onTriggered: {
                            if (index !== player.audioDevice) {
                                player.setAudioDevice(index)
                            }
                        }
                    }

                }
            }
        }
    }

    // Stream playback options
    Component {
        id: smComp

        PComp.Menu {
            id: streamMenu
            Component.onCompleted: streamMenu.popup()

            PComp.Menu {
                title: 'Stations'
                Repeater {
                    model: mcws.stationSources
                    delegate: PComp.MenuItem {
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
    }

    ColumnLayout {
        id: cl
        width: lvDel.width

        // album art and track info
        RowLayout {

            ShadowImage {
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

                        PComp.ToolButton {
                            icon.name: 'streamtuner'

                            // stream menu
                            property var sm
                            onClicked: {
                                if (!sm) {
                                    sm = smComp.createObject(lvDel)
                                } else {
                                    sm.popup()
                                }
                            }

                            PComp.ToolTip {
                                text: 'Streaming Stations'
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

                    FadeBehavior on text {}
                }

                // Album
                PE.DescriptiveLabel {
                    text: album
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    Layout.maximumHeight: Math.round(ti.height/2.5)

                    FadeBehavior on text {}
                }

                TrackPosControl {
                    Layout.fillWidth: true
                    showSlider: model.state !== PlayerState.Stopped
                }
            }

        }

        // zone name/info & playback controls
        RowLayout {

            // Zone name/options menu
            PComp.ToolButton {
                id: zb
                text: model.zonename
                icon.name: model.linked ? 'edit-link' : ''
                implicitWidth: ti.width
                font: PlasmaCore.Theme.smallestFont

                // zone options menu
                property var zm
                onClicked: {
                    if (!zm) {
                        zm = zmComp.createObject(lvDel)
                    } else {
                        zm.popup()
                    }
                }

                PComp.ToolTip {
                    text: model.state !== PlayerState.Stopped
                          ? model.audiopath
                          : model.status
                }
            }

            // player controls
            Player {
                Layout.fillWidth: true
                showVolumeSlider: plasmoid.configuration.showVolumeSlider
                showStopButton: plasmoid.configuration.showStopButton
            }
        }

    }
}
