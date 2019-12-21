import QtQuick 2.9
import QtQuick.Controls 2.5

BaseAction {
    text: 'Current Search'
    icon.name: 'media-playback-start'
    method: 'play'
    enabled: trackView.searchMode & trackView.viewer.count > 0
    onTriggered: {
        if (method !== '')
            call[method](trackView.mcwsQuery)
    }
}

