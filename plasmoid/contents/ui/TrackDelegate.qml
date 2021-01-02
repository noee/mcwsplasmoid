import QtQuick 2.9
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.5
import org.kde.plasma.core 2.1 as PlasmaCore

import 'controls'

ItemDelegate {
    id: detDel
    width: ListView.view.width
    height: rl.implicitHeight + PlasmaCore.Units.largeSpacing

    background: BackgroundHue {
        source: ti
    }

    signal contextClick(var index)

    function formatTime(s) {

        function pad(n, z) {
          z = z || 2;
          return ('00' + n).slice(-z);
        }

        var ms = s % 1000;
        s = (s - ms) / 1000;
        var secs = s % 60;
        s = (s - secs) / 60;
        var mins = s % 60;
        var hrs = (s - mins) / 60;

        return hrs !== 0 ? pad(hrs) + ':' : '' + pad(mins) + ':' + pad(secs)
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

    contentItem: MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton | Qt.LeftButton
        onClicked: {
            trackView.currentIndex = index
            if (mouse.button === Qt.RightButton)
                detDel.contextClick(index)
        }

        RowLayout {
            id: rl
            anchors.fill: parent

            // cover art
            ShadowImage {
                id: ti
                animateLoad: false
                sourceKey: key
                sourceSize.height: Math.max(thumbSize/2, 24)
                opacityTo: .8

                MouseAreaEx {
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onPressAndHold: {
                        if (mouse.button === Qt.RightButton) {
                            trackView.viewer.currentIndex = index
                            mcws.getTrackDetails(key, (ti) => {
                                logger.log(ti, 'Track Detail')
                            })
                        }
                    }
                    onClicked: {
                        trackView.currentIndex = index
                        trkCmds.open()
                    }
                }
            }
            // track controls
            ColumnLayout {
                visible: !abbrevTrackView || detDel.ListView.isCurrentItem
                // play track
                PlasmaCore.IconItem {
                    source: 'enjoy-music-player'
                    Layout.preferredWidth: PlasmaCore.Units.iconSizes.small
                    Layout.preferredHeight: PlasmaCore.Units.iconSizes.small
                    MouseAreaEx {
                        tipText: 'Play Now'
                        onClicked: {
                            if (trackView.searchMode)
                                zoneView.currentPlayer.playTrackByKey(key)
                            else
                                zoneView.currentPlayer.playTrack(index)
                        }
                    }
                }
                // add TrackPosControl
                PlasmaCore.IconItem {
                    source: 'list-add'
                    Layout.preferredWidth: PlasmaCore.Units.iconSizes.small
                    Layout.preferredHeight: PlasmaCore.Units.iconSizes.small
                    MouseAreaEx {
                        tipText: 'Add track'
                        onClicked: {
                            zoneView.currentPlayer.addTrack(key)
                        }
                    }
                }
                // remove track
                PlasmaCore.IconItem {
                    source: 'list-remove'
                    visible: !trackView.searchMode & !trackView.isSorted
                    Layout.preferredWidth: PlasmaCore.Units.iconSizes.small
                    Layout.preferredHeight: PlasmaCore.Units.iconSizes.small
                    MouseAreaEx {
                        tipText: 'Remove track'
                        onClicked: {
                            zoneView.currentPlayer.removeTrack(index)
                        }
                    }
                }
            }
            // track details
            ColumnLayout {
                spacing: 0
                width: rl.width

                // Track Name/duration
                RowLayout {
                    Label {
                        id: tk
                        Layout.fillWidth: true
                        padding: 0
                        elide: Text.ElideRight
                        text: (mediatype === 'Audio'
                              ? (track_ === undefined ? '' : track_ + '. ') + '%1 (%2)'.arg(name).arg(genre)
                              : '%1 / %2'.arg(name).arg(mediatype))
                        font.bold: detDel.ListView.isCurrentItem
                        font.italic: detDel.ListView.isCurrentItem
                    }
                    Label {
                        text: {
                            if (duration === undefined || duration === '') {
                                return ''
                            }

                            // if playing, display playing position
                            let cz = zoneView.currentZone
                            if (+key === +cz.filekey
                                    && (cz.state === PlayerState.Playing || cz.state === PlayerState.Paused)) {
                                return '(%1)'.arg(cz.positiondisplay.replace(/ /g, ''))
                            }

                            // otherwise, track duration
                            return formatTime(duration*1000)
                        }
                        font.pointSize: tk.font.pointSize
                        font.italic: tk.font.italic
                    }
                }

                // album
                Label {
                    padding: 0

                    visible: !abbrevTrackView || detDel.ListView.isCurrentItem
                    Layout.leftMargin: PlasmaCore.Units.smallSpacing
                    font.italic: tk.font.italic
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    text: {
                        if (mediatype === 'Audio')
                            return "'%1'".arg(album)
                        else if (mediatype === 'Video')
                            return genre
                        else return ''
                    }
                }
                // artist
                Label {
                    padding: 0

                    visible: !abbrevTrackView || detDel.ListView.isCurrentItem
                    Layout.leftMargin: PlasmaCore.Units.smallSpacing
                    font.italic: tk.font.italic
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    text: {
                        if (mediatype === 'Audio')
                            return artist
                        else if (mediatype === 'Video')
                            return mediasubtype
                        else return ''
                    }
                }
            }
        }
    }
}
