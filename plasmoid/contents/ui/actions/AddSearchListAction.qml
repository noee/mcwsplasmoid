import QtQuick 2.9
import QtQuick.Controls 2.5

BaseAction {
    text: 'Current Search'
    icon.name: 'media-playlist-append'
    method: 'add'
    enabled: trackView.searchMode & trackView.viewer.count > 0
    onTriggered: {
        if (method !== '')
            call[method](trackView.mcwsQuery)
    }
}

