import QtQuick 2.9
import QtQuick.Controls 2.5

BaseAction {
    aText: 'Current Search Results'
    defaultIcon: 'media-playlist-append'
    method: 'add'
    enabled: trackView.searchMode & trackView.count > 0
    onTriggered: {
        if (method !== '')
            call[method](trackView.mcwsQuery)
    }
}

