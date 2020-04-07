import QtQuick 2.9
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.5
import org.kde.kirigami 2.4 as Kirigami

import 'controls'

ItemDelegate {
    id: detDel
    width: ListView.view.width
    height: rl.implicitHeight + Kirigami.Units.largeSpacing

    background: Rectangle {
        id: bkrect
        color: 'transparent'
        anchors.fill: parent
        states: [
            State {
                name: "playing"
                PropertyChanges {
                    target: bkrect
                    color: '#007700'
                }
            }
        ]

        transitions: Transition {
            ColorAnimation { duration: 2000 }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Kirigami.Theme.disabledTextColor
            opacity: !abbrevTrackView
            anchors.top: parent.top
        }
    }

    onClicked: {
        ListView.view.currentIndex = index
    }

    contentItem: RowLayout {
        id: rl
        width: parent.width
        // cover art
        ShadowImage {
            id: ti
            animateLoad: false
            sourceKey: key
            sourceSize.height: Math.max(thumbSize/2, 24)
            MouseAreaEx {
                onPressAndHold: {
                    trackView.viewer.currentIndex = index
                    mcws.getTrackDetails(key, (ti) => {
                        logger.log(ti)
                    })
                }
                onClicked: {
                    trackView.viewer.currentIndex = index
                    trkCmds.open()
                }
            }
        }
        // track controls
        ColumnLayout {
            visible: !abbrevTrackView || detDel.ListView.isCurrentItem
            // play track
            Kirigami.Icon {
                source: 'media-playback-start'
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
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
            Kirigami.Icon {
                source: 'list-add'
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                MouseAreaEx {
                    tipText: 'Add track'
                    onClicked: {
                        zoneView.currentPlayer.addTrack(key)
                    }
                }
            }
            // remove track
            Kirigami.Icon {
                source: 'process-stop'
                visible: !trackView.searchMode & !trackView.isSorted
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
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
            width: parent.width - ti.width
            // Track/duration
            RowLayout {
                width: parent.width
                Label {
                    id: tk
                    padding: 0
                    Layout.fillWidth: true
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
                            bkrect.state = ''
                            return ''
                        }

                        // if playing, playing position
                        let cz = zoneView.currentZone
                        if (+key === +cz.filekey
                                && (cz.state === PlayerState.Playing || cz.state === PlayerState.Paused)) {
                            bkrect.state = 'playing'
                            return '(%1)'.arg(cz.positiondisplay.replace(/ /g, ''))
                        }

                        // otherwise, just track duration
                        let num = duration.split('.')[0]
                        bkrect.state = ''
                        return "%1:%2".arg(Math.floor(num / 60)).arg(String((num % 60) + '00').substring(0,2))
                    }
                    font.pointSize: tk.font.pointSize
                    font.italic: tk.font.italic
                }
            }
            // album
            Label {
                padding: 0

                visible: !abbrevTrackView || detDel.ListView.isCurrentItem
                Layout.leftMargin: Kirigami.Units.smallSpacing
                font.italic: tk.font.italic
                elide: Text.ElideRight
                Layout.fillWidth: true
                text: {
                    if (mediatype === 'Audio')
                        return "from '%1'".arg(album)
                    else if (mediatype === 'Video')
                        return genre
                    else return ''
                }
            }
            // artist
            Label {
                padding: 0

                visible: !abbrevTrackView || detDel.ListView.isCurrentItem
                Layout.leftMargin: Kirigami.Units.smallSpacing
                font.italic: tk.font.italic
                elide: Text.ElideRight
                Layout.fillWidth: true
                text: {
                    if (mediatype === 'Audio')
                        return "by %2".arg(artist)
                    else if (mediatype === 'Video')
                        return mediasubtype
                    else return ''
                }
            }
        }
    }

}
