import QtQuick 2.9
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.4
import org.kde.kirigami 2.4 as Kirigami

import 'controls'

ItemDelegate {
    id: detDel
    anchors.left: parent.left
    anchors.right: parent.right
    height: rl.implicitHeight

    RowLayout {
        id: rl
        width: parent.width

        TrackImage {
            sourceKey: key
            sourceSize.height: Math.max(thumbSize/2, 24)
        }
        ColumnLayout {
            spacing: 0
            Rectangle {
                height: 1
                Layout.fillWidth: true
                Layout.bottomMargin: 5
                visible: index > 0 && !abbrevTrackView
                color: theme.highlightColor
            }
            // Track/duration
            RowLayout {
                Kirigami.Heading {
                    id: tk
                    Layout.fillWidth: true
                    level: detDel.ListView.isCurrentItem ? 2 : 5
                    text: mediatype === 'Audio'
                          ? (track_ === undefined ? '' : track_ + '. ') + '%1 (%2)'.arg(name).arg(genre)
                          : '%1 / %2'.arg(name).arg(mediatype)
                    font.italic: detDel.ListView.isCurrentItem
                }
                Kirigami.Heading {
                    text: trackView.formatDuration(duration)
                    level: tk.level
                    font.italic: tk.font.italic
                }
            }
            // artist/album
            Label {
                visible: !abbrevTrackView || detDel.ListView.isCurrentItem
                Layout.leftMargin: units.smallSpacing
                font.italic: tk.font.italic
                text: {
                    if (mediatype === 'Audio')
                        return "from '%1'\nby %2".arg(album).arg(artist)
                    else if (mediatype === 'Video')
                        return genre + '\n' + mediasubtype
                    else return ''
                }
            }
        }
    }

}
