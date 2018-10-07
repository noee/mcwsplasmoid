import QtQuick 2.9
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.4
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras

import 'controls'

ItemDelegate {
    id: detDel
    anchors.left: parent.left
    anchors.right: parent.right
    height: rl.implicitHeight

    RowLayout {
        id: rl
        width: trackView.width

        TrackImage {
            sourceKey: key
            height: thumbSize
        }
        ColumnLayout {
            spacing: 0
            Rectangle {
                height: 1
                Layout.fillWidth: true
                visible: index > 0 && !abbrevTrackView
                color: theme.highlightColor
            }

            PlasmaExtras.Heading {
                Layout.fillWidth: true
                level: detDel.ListView.isCurrentItem ? 4 : 5
                text: "%1%2 / %3".arg(detDel.ListView.isCurrentItem
                                      ? trackView.formatDuration(duration)
                                      : "").arg(name).arg(mediatype === 'Audio' ? genre : mediatype)
                font.italic: true
            }
            PlasmaComponents.Label {
                visible: !abbrevTrackView || detDel.ListView.isCurrentItem
                Layout.leftMargin: units.smallSpacing
                font.italic: true
                text: {
                    if (mediatype === 'Audio')
                        return "from '%1' (Trk# %3)\nby %2".arg(album).arg(artist).arg(track_)
                    else if (mediatype === 'Video')
                        return genre + '\n' + mediasubtype
                    else return ''
                }
            }
        }
    }

}
