import QtQuick 2.15
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.15
import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.plasma.components 3.0 as PComp
import org.kde.plasma.extras 2.0 as PE

import 'controls'
import 'actions'
import 'helpers'

ItemDelegate {
    id: detDel
    width: ListView.view.width
    height: rl.implicitHeight + PlasmaCore.Units.largeSpacing

    // track actions popup
    Component {
        id: trkPopup

        Popup {
            id: trkCmds
            focus: true
            padding: 2
            spacing: 0

            parent: Overlay.overlay

            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2)

            ColumnLayout {
                spacing: 0

                // album
                ToolButton {
                    action: AlbumAction {
                        useAText: true
                        icon.name: 'enjoy-music-player'
                        method: 'play'
                    }
                    ToolTip {
                        text: 'Play Album'
                    }
                }
                RowLayout {
                    spacing: 0
                    ToolButton { action: AlbumAction { method: 'addNext' } }
                    ToolButton { action: AlbumAction { method: 'add' } }
                    ToolButton { action: AlbumAction { method: 'show' } }
                }

                GroupSeparator{}

                // artist
                ToolButton {
                    action: ArtistAction {
                        shuffle: autoShuffle
                        method: 'play'
                        icon.name: 'enjoy-music-player'
                        useAText: true
                    }
                    ToolTip {
                        text: 'Play Artist'
                    }
                }
                RowLayout {
                    spacing: 0
                    ToolButton {
                        action: ArtistAction {
                            method: 'addNext'
                            shuffle: autoShuffle
                        }

                    }
                    ToolButton {
                        action: ArtistAction {
                            method: 'add'
                            shuffle: autoShuffle
                        }
                    }
                    ToolButton {
                        action: ArtistAction {
                            method: 'show'
                            shuffle: autoShuffle
                        }
                    }
                }

                GroupSeparator{}

                // genre
                ToolButton {
                    action: GenreAction {
                        shuffle: autoShuffle
                        method: 'play'
                        icon.name: 'enjoy-music-player'
                        useAText: true
                    }
                    ToolTip {
                        text: 'Play Genre'
                    }
                }
                RowLayout {
                    spacing: 0
                    ToolButton {
                        action: GenreAction {
                            method: 'addNext'
                            shuffle: autoShuffle
                        }

                    }
                    ToolButton {
                        action: GenreAction {
                            method: 'add'
                            shuffle: autoShuffle
                        }
                    }
                    ToolButton {
                        action: GenreAction {
                            method: 'show'
                            shuffle: autoShuffle
                        }
                    }
                }

                GroupSeparator { visible: trackView.searchMode }

                // Search results
                ToolButton {
                    action: PlaySearchListAction { useAText: true }
                    icon.name: 'enjoy-music-player'
                    visible: trackView.searchMode & !trackView.showingPlaylist
                    ToolTip {
                        text: 'Play Search Results'
                    }
                }
                RowLayout {
                    spacing: 0
                    visible: trackView.searchMode & !trackView.showingPlaylist

                    ToolButton {
                        action: AddSearchListAction {
                            method: 'addNext'
                            shuffle: autoShuffle
                        }
                    }
                    ToolButton {
                        action: AddSearchListAction {
                            shuffle: autoShuffle
                        }
                    }
                }

                // Playlist
                ToolButton {
                    action: PlayPlaylistAction { useAText: true }
                    icon.name: 'enjoy-music-player'
                    visible: trackView.showingPlaylist
                    ToolTip {
                        text: 'Play Search Results'
                    }
                }
                RowLayout {
                    spacing: 0
                    visible: trackView.showingPlaylist

                    ToolButton {
                        action: AddPlaylistAction {
                            method: 'addNext'
                            shuffle: autoShuffle
                        }
                    }
                    ToolButton {
                        action: AddPlaylistAction {
                            shuffle: autoShuffle
                        }
                    }
                }

            }
        }
    }

    function popupOptions() {
        var popup = trkPopup.createObject(detDel)
        popup.closed.connect(() => popup.destroy())
        popup.open()
    }

    background: TrackBackground {
        source: ti
    }

    signal contextClick(var index)

    function formatTime(s) {

        var pad = (n, z) => {
            z = z || 2;
            return ('00' + n).slice(-z);
        }

        var ms = s % 1000;
        s = (s - ms) / 1000;
        var secs = s % 60;
        s = (s - secs) / 60;
        var mins = s % 60;
        var hrs = (s - mins) / 60;

        return hrs === 0
                ? '%1:%2'.arg(pad(mins)).arg(pad(secs))
                : '%1:%2:%3'.arg(pad(hrs)).arg(pad(mins)).arg(pad(secs))
    }

    function animateTrack() {
        trkAni.start()
    }

    SequentialAnimation {
        id: trkAni
        loops: 2
        PropertyAnimation { target: detDel; property: "opacity"; to: 0; duration: 100 }
        PropertyAnimation { target: detDel; property: "opacity"; to: 1; duration: 500 }
    }

    contentItem: MouseAreaEx {
        id: mainMa
        acceptedButtons: Qt.RightButton | Qt.LeftButton
        onClicked: {
            trackView.currentIndex = index
            if (mouse.button === Qt.RightButton) {
                detDel.contextClick(index)
                popupOptions()
            }
        }

        // Track Box, shows on hover on the right side of coverart
        Rectangle {
            id: trkbox
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            width: Math.round(parent.width*.4)
            z: 1
            radius: 15
            implicitHeight: PlasmaCore.Units.iconSizes.medium
            color: PlasmaCore.ColorScope.backgroundColor
            opacity: mainMa.containsMouse ? .5 : 0
            Behavior on opacity {
                NumberAnimation { duration: 500 }
            }

        }

        // trk controls
        RowLayout {
            anchors.centerIn: trkbox
            z: 1
            opacity: mainMa.containsMouse ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: 500 }
            }

            // play track
            PlayButton {
                onClicked: {
                    if (trackView.searchMode)
                        zoneView.currentPlayer.playTrackByKey(key)
                    else
                        zoneView.currentPlayer.playTrack(index)
                }
            }

            // add TrackPosControl
            AddButton {
                onClicked: {
                    zoneView.currentPlayer.addTrack(key)
                }
            }

            // remove track
            ToolButton {
                icon.name: 'list-remove'
                ToolTip {
                    text: 'Remove Track'
                }
                onClicked: {
                    zoneView.currentPlayer.removeTrack(index)
                }
            }

            ToolButton {
                icon.name: 'configuration'
                ToolTip {
                    text: 'More Options'
                }
                onClicked: {
                    popupOptions()

                }
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
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onPressAndHold: {
                        if (mouse.button === Qt.RightButton) {
                            mcws.getTrackDetails(key, trk => logger.log('Track ' + key, trk))
                        }
                    }
                    onClicked: {
                        trackView.currentIndex = index
                        popupOptions()
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
                    PComp.Label {
                        color: tk.color
                        text: {
                            if (duration === undefined || duration === '') {
                                return ''
                            }

                            // if playing, display playing position
                            let cz = zoneView.currentZone
                            if (cz && +key === +cz.filekey
                                    && (cz.state === PlayerState.Playing || cz.state === PlayerState.Paused)) {
                                return '(%1)'.arg(cz.positiondisplay.replace(/ /g, ''))
                            }

                            // otherwise, track duration
                            return formatTime(duration*1000)
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
}
