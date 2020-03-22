import QtQuick 2.9
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.4
import org.kde.kirigami 2.4 as Kirigami

import 'controls'

ItemDelegate {
    id: detDel
    width: ListView.view.width
    height: rl.implicitHeight

    background: Rectangle {
        width: parent.width
        height: 1
        color: Kirigami.Theme.disabledTextColor
        opacity: !abbrevTrackView
        anchors.bottom: parent.bottom
    }

    RowLayout {
        id: rl
        width: parent.width
        TrackImage {
            id: ti
            sourceKey: key
            sourceSize.height: Math.max(thumbSize/2, 24)
        }
        ColumnLayout {
            spacing: 0
            width: parent.width - ti.width
            Layout.bottomMargin: 5
            // Track/duration
            RowLayout {
                width: parent.width
                Kirigami.BasicListItem {
                    id: tk
                    reserveSpaceForIcon: false
                    separatorVisible: false
                    padding: 0

                    text: (mediatype === 'Audio'
                          ? (track_ === undefined ? '' : track_ + '. ') + '%1 (%2)'.arg(name).arg(genre)
                          : '%1 / %2'.arg(name).arg(mediatype))
                    font.bold: detDel.ListView.isCurrentItem
                    font.italic: detDel.ListView.isCurrentItem
                }

                Label {
                    text: {
                        if (duration === undefined) {
                            return ''
                        }

                        let num = duration.split('.')[0]
                        return "%1:%2".arg(Math.floor(num / 60)).arg(String((num % 60) + '00').substring(0,2))
                    }

                    font.pointSize: tk.font.pointSize
                    font.italic: tk.font.italic
                }
            }
            // artist/album
            Kirigami.BasicListItem {
                reserveSpaceForIcon: false
                separatorVisible: false
                padding: 0

                visible: !abbrevTrackView || detDel.ListView.isCurrentItem
                Layout.leftMargin: Kirigami.Units.smallSpacing
                font.italic: tk.font.italic
                text: {
                    if (mediatype === 'Audio')
                        return "from '%1'".arg(album)
                    else if (mediatype === 'Video')
                        return genre
                    else return ''
                }
            }
            Kirigami.BasicListItem {
                reserveSpaceForIcon: false
                separatorVisible: false
                padding: 0

                visible: !abbrevTrackView || detDel.ListView.isCurrentItem
                Layout.leftMargin: Kirigami.Units.smallSpacing
                font.italic: tk.font.italic
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
