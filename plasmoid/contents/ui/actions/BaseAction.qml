import QtQuick 2.9
import QtQuick.Controls 2.5

Action {
    property bool shuffle: false
    property string method: ''
    property string defaultIcon: ''
    property string aText: ''
    property bool useAText: false
    property bool useDefaultText: false

    text: {
        if (useAText)
            return aText

        if (!useDefaultText)
            return ''

        switch (method) {
            case 'add'      : return 'Append'
            case 'addNext'  : return 'Add Next'
            case 'show'     : return 'Show'
            case 'play'     : return 'Play'
            case 'remove'   : return 'Remove'
            default         : '<unknown>'
        }
    }

    icon.name: {
        if (defaultIcon.length > 0)
            return defaultIcon

        switch (method) {
            case 'add'      : return 'media-playlist-append'
            case 'addNext'  : return 'media-playlist-consecutive-symbolic'
            case 'show'     : return 'search'
            case 'remove'   : return 'list-remove'
            // play is default
            default         : return 'media-playback-start'
        }
    }

    property var call: ({
        play: query => zoneView.currentPlayer.searchAndPlayNow(query, shuffle)
        , add: query => zoneView.currentPlayer.searchAndAdd(query, false, shuffle)
        , addNext: query => zoneView.currentPlayer.searchAndAdd(query, true, shuffle)
        , show: query => event.queueCall(trackView.search, query)
    })
}
