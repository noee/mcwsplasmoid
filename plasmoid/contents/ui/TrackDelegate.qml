import QtQuick 2.15
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.15
import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.plasma.components 3.0 as PComp
import org.kde.plasma.extras 2.0 as PE
import org.kde.kcoreaddons 1.0 as KCoreAddons

import 'controls'
import 'actions'
import 'helpers'
import 'theme'

ItemDelegate {
    id: detDel
    width: ListView.view.width
    height: trkDetails.implicitHeight
            + PlasmaCore.Units.smallSpacing

    property bool expanded: false

    background: BaseBackground {
        theme: backgroundTheme
        source: ti
    }

    signal contextClick(var index)

    function animateTrack() {
        trkAni.start()
    }

    SequentialAnimation {
        id: trkAni
        PropertyAnimation { target: detDel; property: "opacity"; to: 0; duration: 100 }
        PropertyAnimation { target: detDel; property: "opacity"; to: 1; duration: 500 }
    }

    Timer {
        interval: 500
        running: mainMa.containsMouse
        onTriggered: {
            if (mainMa.containsMouse) {
                floatingBox.opacity = .5
                floatingControls.opacity = 1
            }
        }
    }

    contentItem: MouseAreaEx {
        id: mainMa
        acceptedButtons: Qt.RightButton | Qt.LeftButton

        onHoveredChanged: {
            if (!containsMouse)
                floatingBox.opacity = floatingControls.opacity = 0
        }

        onClicked: {
            ListView.currentIndex = index
            if (mouse.button === Qt.RightButton) {
                detDel.contextClick(index)
                expanded = !expanded
            }
        }

        ColumnLayout {
            id: trkDetails
            anchors.fill: parent

            // Floating box and controls, controls separate item
            // so opacity can be different
            Item {
                Layout.fillWidth: true
                implicitHeight: rl.implicitHeight

                Rectangle {
                    id: floatingBox
                    anchors.verticalCenter: parent.verticalCenter
                    x: parent.width/2 + PlasmaCore.Units.largeSpacing
                    implicitWidth: Math.round(parent.width*.4)
                    implicitHeight: PlasmaCore.Units.iconSizes.large
                    z: 1
                    radius: 15
                    color: PlasmaCore.ColorScope.backgroundColor
                    opacity: 0
                    Behavior on opacity {
                        NumberAnimation {}
                    }

                }

                RowLayout {
                    id: floatingControls
                    anchors.centerIn: floatingBox
                    z: 1
                    opacity: 0
                    Behavior on opacity {
                        NumberAnimation {}
                    }

                    // play track
                    ToolButton {
                        action: TrackAction { text: ''; method: 'play' }
                        ToolTip { text: 'Play Track Now' }
                    }

                    // add track
                    ToolButton {
                        action: TrackAction { text: ''; method: 'add' }
                        ToolTip { text: 'Add Track to List' }
                    }

                    // remove track
                    ToolButton {
                        visible: !trackView.searchMode
                        action: TrackAction { text: ''; method: 'remove' }
                        ToolTip { text: 'Remove Track from List' }
                    }

                    ToolButton {
                        icon.name: expanded ? 'arrow-up' : 'arrow-down'
                        onClicked: expanded = !expanded
                        ToolTip { text: 'Artist/Album Options' }
                    }
                }

                // Trk info
                RowLayout {
                    id: rl
                    anchors.fill: parent

                    // cover art
                    ShadowImage {
                        id: ti
                        animateLoad: false
                        shadow.size: PlasmaCore.Units.smallSpacing
                        sourceKey: key
                        thumbnail: true
                        imageUtils: mcws.imageUtils
                        sourceSize.height: Math.max(thumbSize/2, 24)
                        sourceSize.width: Math.max(thumbSize/2, 24)
                        Layout.leftMargin: PlasmaCore.Units.smallSpacing

                        MouseAreaEx {
                            id: ma
                            acceptedButtons:Qt.RightButton
                            onPressAndHold: {
                                mcws.getTrackDetails(key, trk => logger.log('Track ' + key, trk))
                            }
                        }

                    }

                    // track details
                    ColumnLayout {
                        spacing: 0

                        // Track Name/duration
                        RowLayout {
                            PE.Heading {
                                id: tk
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                level: 4
                                fontSizeMode: Text.Fit
                                text: (mediatype === 'Audio'
                                      ? (track_ === undefined ? '' : track_ + '. ') + name
                                      : '%1 / %2'.arg(name).arg(mediatype))
                            }

                            PE.DescriptiveLabel {
                                text: {
                                    if (duration === undefined) {
                                        return ''
                                    }

                                    // if track is playing, display playing position
                                    let z = zoneView.currentZone
                                    if (z && +key === +z.filekey
                                            && (z.state !== PlayerState.Stopped)) {
                                        active = true
                                        return '(%1)'.arg(z.positiondisplay.replace(/ /g, ''))
                                    }
                                    else { // otherwise, track duration
                                        active = false
                                        return KCoreAddons.Format.formatDuration(duration*1000
                                            , duration*1000 >= 60*60*1000 ? 0 : KCoreAddons.FormatTypes.FoldHours)
                                    }
                                }
                            }
                        }

                        // artist
                        PComp.Label {
                            color: tk.color
                            visible: !abbrevTrackView || detDel.ListView.isCurrentItem
                                         elide: Text.ElideRight
                            Layout.fillWidth: true
                            text: {
                                if (!mediatype)
                                    return ''
                                else if (mediatype === 'Audio')
                                    return artist ?? ''
                                else if (mediatype === 'Video')
                                    return mediasubtype ?? ''
                                else return ''
                            }
                        }

                        // album/genre
                        RowLayout {
                            PE.DescriptiveLabel {
                                text: album ?? ''
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                visible: !abbrevTrackView || detDel.ListView.isCurrentItem
                            }

                            PE.DescriptiveLabel {
                                text: genre ?? ''
                                elide: Text.ElideRight
                                Layout.maximumWidth: Math.round(detDel.width/4)
                                visible: !abbrevTrackView || detDel.ListView.isCurrentItem
                            }
                        }

                    }
                }

            }

            // More Options
            Loader {
                active: expanded
                visible: active
                Layout.fillWidth: true

                sourceComponent: ColumnLayout {
                    spacing: 0

                    GroupSeparator{}

                    // album
                    RowLayout {
                        spacing: 0
                        ToolButton {
                            action: AlbumAction {
                                useAText: true
                                icon.name: 'media-playback-start'
                                method: 'play'
                            }
                            ToolTip { text: 'Play Album' }
                        }
                        Item { Layout.fillWidth: true }
                        ToolButton { action: AlbumAction { text: ''; method: 'addNext' } }
                        ToolButton { action: AlbumAction { text: ''; method: 'add' } }
                        ToolButton { action: AlbumAction { text: ''; method: 'show' } }
                    }

                    // artist
                    RowLayout {
                        spacing: 0
                        ToolButton {
                            action: ArtistAction {
                                shuffle: autoShuffle
                                method: 'play'
                                icon.name: 'media-playback-start'
                                useAText: true
                            }
                            ToolTip {
                                text: 'Play Artist'
                            }
                        }
                        Item { Layout.fillWidth: true }
                        ToolButton {
                            action: ArtistAction {
                                text: ''
                                method: 'addNext'
                                shuffle: autoShuffle
                            }

                        }
                        ToolButton {
                            action: ArtistAction {
                                text: ''
                                method: 'add'
                                shuffle: autoShuffle
                            }
                        }
                        ToolButton {
                            action: ArtistAction {
                                text: ''
                                method: 'show'
                                shuffle: autoShuffle
                            }
                        }
                    }

                    // genre
                    RowLayout {
                        spacing: 0
                        ToolButton {
                            action: GenreAction {
                                shuffle: autoShuffle
                                method: 'play'
                                icon.name: 'media-playback-start'
                                useAText: true
                            }
                            ToolTip {
                                text: 'Play Genre'
                            }
                        }
                        Item { Layout.fillWidth: true }
                        ToolButton {
                            action: GenreAction {
                                text: ''
                                method: 'addNext'
                                shuffle: autoShuffle
                            }

                        }
                        ToolButton {
                            action: GenreAction {
                                text: ''
                                method: 'add'
                                shuffle: autoShuffle
                            }
                        }
                        ToolButton {
                            action: GenreAction {
                                text: ''
                                method: 'show'
                                shuffle: autoShuffle
                            }
                        }
                    }

                    // Search/Playlist options
                    GroupSeparator { visible: trackView.searchMode }

                    // Search results
                    RowLayout {
                        spacing: 0
                        visible: trackView.searchMode & !trackView.showingPlaylist

                        ToolButton {
                            action: PlaySearchListAction { useAText: true }
                            ToolTip {
                                text: 'Play Search Results'
                            }
                        }

                        Item { Layout.fillWidth: true }

                        ToolButton {
                            action: AddSearchListAction {
                                text: ''
                                method: 'addNext'
                                shuffle: autoShuffle
                            }
                        }
                        ToolButton {
                            action: AddSearchListAction {
                                text: ''
                                shuffle: autoShuffle
                            }
                        }
                    }

                    // Playlist
                    RowLayout {
                        spacing: 0
                        visible: trackView.showingPlaylist

                        ToolButton {
                            id: pl
                            action: PlayPlaylistAction { useAText: true }
                            ToolTip {
                                text: 'Play ' + pl.text
                            }
                        }
                        Item { Layout.fillWidth: true }
                        ToolButton {
                            action: AddPlaylistAction {
                                text: ''
                                method: 'addNext'
                                shuffle: autoShuffle
                            }
                        }
                        ToolButton {
                            action: AddPlaylistAction {
                                text: ''
                                shuffle: autoShuffle
                            }
                        }
                    }

                }

            }
        }

    }
}
