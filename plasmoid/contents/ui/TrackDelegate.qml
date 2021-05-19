import QtQuick 2.15
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.15
import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.plasma.components 3.0 as PComp
import org.kde.plasma.extras 2.0 as PE
import org.kde.kcoreaddons 1.0 as KCoreAddons
import org.kde.kirigami 2.12 as Kirigami

import 'controls'
import 'actions'
import 'helpers'
import 'theme'

ItemDelegate {
    id: detDel
    implicitWidth: ListView.view.width
    implicitHeight: trkDetails.implicitHeight
            + PlasmaCore.Units.smallSpacing

    background: BaseBackground {
        theme: backgroundTheme
        source: ti
    }

    signal contextClick(var index)

    function toggleExpanded() {
        detDel.state = detDel.state === 'expanded' ? '' : 'expanded'
    }

    function animateTrack() {
        trkAni.start()
    }

    SequentialAnimation {
        id: trkAni
        PropertyAnimation { target: detDel; property: "opacity"; to: 0; duration: 100 }
        PropertyAnimation { target: detDel; property: "opacity"; to: 1; duration: 500 }
    }

    Timer {
        interval: PlasmaCore.Units.veryLongDuration
        running: mainMa.containsMouse
        onTriggered: {
            if (mainMa.containsMouse) {
                floatLoader.active = true
            }
        }
    }

    states: [
            State {
            name: 'expanded'
            PropertyChanges { target: optLoader; active: true }
        }
    ]

    contentItem: MouseAreaEx {
        id: mainMa
        acceptedButtons: Qt.RightButton | Qt.LeftButton

        onHoveredChanged: {
            if (!containsMouse)
                floatLoader.active = false
        }

        onClicked: {
            ListView.currentIndex = index
            if (mouse.button === Qt.RightButton) {
                detDel.contextClick(index)
                detDel.toggleExpanded()
            }
        }

        // Trk Info, floating box and controls, controls are separate item
        // so opacity can be different
        Loader {
            id: floatLoader
            active: false
            visible: active

            sourceComponent: Item {
                x: rl.x
                y: rl.y
                implicitWidth: trkDetails.width
                implicitHeight: rl.height
                visible: false
                Component.onCompleted: visible = true

                VisibleBehavior on visible {}

                Rectangle {
                    id: floatingBox
                    anchors.verticalCenter: parent.verticalCenter
                    x: parent.width/2 + PlasmaCore.Units.largeSpacing
                    implicitWidth: Math.round(parent.width*.4)
                    implicitHeight: PlasmaCore.Units.iconSizes.large
                    z: 1
                    radius: 15
                    color: PlasmaCore.ColorScope.backgroundColor
                    opacity: .4

                }

                RowLayout {
                    id: floatingControls
                    anchors.centerIn: floatingBox
                    z: 1

                    // play track
                    PlayButton {
                        action: TrackAction { method: 'play' }
                    }

                    // add track
                    AppendButton {
                        action: TrackAction { method: 'add' }
                    }

                    // remove track
                    PComp.ToolButton {
                        visible: !trackView.searchMode
                        action: TrackAction { method: 'remove' }
                        ToolTip { text: 'Remove Track from List' }
                    }

                    PComp.ToolButton {
                        id: expandBtn
                        icon.name: detDel.state === 'expanded' ? 'arrow-up' : 'arrow-down'
                        onClicked: detDel.toggleExpanded()
                        ToolTip { text: 'Artist/Album Options' }
                    }
                }
            }
        }

        ColumnLayout {
            id: trkDetails
            anchors.fill: parent

            // Trk info
            RowLayout {
                id: rl
//                    anchors.fill: parent

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

            // More Options
            Loader {
                id: optLoader
                active: false
                visible: active
                Layout.fillWidth: true

                VisibleBehavior on active {}

                sourceComponent: ColumnLayout {
                    spacing: 0

                    GroupSeparator{}

                    // album
                    RowLayout {
                        spacing: 0
                        Kirigami.BasicListItem {
                            id: liAlbum
                            separatorVisible: false
                            hoverEnabled: true
                            action: AlbumAction {
                                useAText: true
                                icon.name: 'media-playback-start'
                                method: 'play'
                            }
                            ToolTip {
                                text: 'Play Album'
                                visible: liAlbum.hovered
                            }

                        }
                        AddButton {
                            action: AlbumAction { method: 'addNext' }
                        }
                        AppendButton {
                            action: AlbumAction { method: 'add' }
                        }
                        ShowButton {
                            action: AlbumAction { method: 'show' }
                        }
                    }

                    // artist
                    RowLayout {
                        spacing: 0
                        Kirigami.BasicListItem {
                            id: liArtist
                            separatorVisible: false
                            hoverEnabled: true
                            action: ArtistAction {
                                shuffle: autoShuffle
                                method: 'play'
                                icon.name: 'media-playback-start'
                                useAText: true
                            }
                            ToolTip {
                                text: 'Play Artist'
                                visible: liArtist.hovered
                            }
                        }

                        AddButton {
                            action: ArtistAction {
                                method: 'addNext'
                                shuffle: autoShuffle
                            }

                        }
                        AppendButton {
                            action: ArtistAction {
                                method: 'add'
                                shuffle: autoShuffle
                            }
                        }
                        ShowButton {
                            action: ArtistAction {
                                method: 'show'
                                shuffle: autoShuffle
                            }
                        }
                    }

                    // genre
                    RowLayout {
                        spacing: 0
                        Kirigami.BasicListItem {
                            id: liGenre
                            separatorVisible: trackView.searchMode
                            hoverEnabled: true
                            action: GenreAction {
                                shuffle: autoShuffle
                                method: 'play'
                                icon.name: 'media-playback-start'
                                useAText: true
                            }
                            ToolTip {
                                text: 'Play Genre'
                                visible: liGenre.hovered
                            }
                        }

                        AddButton {
                            action: GenreAction {
                                method: 'addNext'
                                shuffle: autoShuffle
                            }

                        }
                        AppendButton {
                            action: GenreAction {
                                method: 'add'
                                shuffle: autoShuffle
                            }
                        }
                        ShowButton {
                            action: GenreAction {
                                method: 'show'
                                shuffle: autoShuffle
                            }
                        }
                    }

                    // Search results
                    RowLayout {
                        spacing: 0
                        visible: trackView.searchMode & !trackView.showingPlaylist

                        Kirigami.BasicListItem {
                            id: liSearch
                            action: PlaySearchListAction { useAText: true }
                            hoverEnabled: true
                            ToolTip {
                                text: 'Play Search Results'
                                visible: liSearch.hovered
                            }
                        }

                        AddButton {
                            action: AddSearchListAction {
                                method: 'addNext'
                                shuffle: autoShuffle
                            }
                        }
                        AppendButton {
                            action: AddSearchListAction {
                                shuffle: autoShuffle
                            }
                        }
                    }

                    // Playlist
                    RowLayout {
                        spacing: 0
                        visible: trackView.showingPlaylist

                        Kirigami.BasicListItem {
                            id: pl
                            action: PlayPlaylistAction { useAText: true }
                            hoverEnabled: true
                            ToolTip {
                                text: 'Play ' + pl.text
                                visible: pl.hovered
                            }
                        }

                        AddButton {
                            action: AddPlaylistAction {
                                method: 'addNext'
                                shuffle: autoShuffle
                            }
                        }
                        AppendButton {
                            action: AddPlaylistAction {
                                shuffle: autoShuffle
                            }
                        }
                    }

                }

            }
        }

    }
}
