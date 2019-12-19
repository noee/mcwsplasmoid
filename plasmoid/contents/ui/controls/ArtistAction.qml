import QtQuick 2.9
import QtQuick.Controls 2.5

BaseAction {
    icon.name: 'view-media-artist'
    text: track ? i18n("Artist: \"%1\"".arg(track.artist)) : ''
    onTriggered: {
        if (method !== '') {
            if (method === 'show')
                call[method]({ artist: '[%1]'.arg(track.artist) })
            else
                call[method]("artist=[%1]".arg(track.artist))
        }
    }
}
