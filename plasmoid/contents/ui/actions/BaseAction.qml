import QtQuick 2.9
import QtQuick.Controls 2.5

Action {
    property bool shuffle: false
    property string method: ''
    property string defaultIcon: ''
    property string aText: ''
    property bool useAText: false

    text: {
        if (useAText)
            return aText

        switch (method) {
            case 'add'      : return 'Append'
            case 'addNext'  : return 'Add Next'
            case 'show'     : return 'Show'
            case 'play'     : return 'Play'
            default         : '<unknown>'
        }
    }

    icon.name: {
        switch (method) {
            case 'add'      : return 'view-sort-descending'
            case 'addNext'  : return 'media-playlist-append'
            case 'show'     : return 'search'
            default         : defaultIcon || 'media-playback-start'
        }
    }

    property var call: ({
        play: (query) =>
              { trkCmds.close(); zoneView.currentPlayer.searchAndPlayNow(query, shuffle) },

        add: (query) =>
             { trkCmds.close(); zoneView.currentPlayer.searchAndAdd(query, false, shuffle) },

        addNext: (query) =>
                 { trkCmds.close(); zoneView.currentPlayer.searchAndAdd(query, true, shuffle) },

        show: (query) =>
              { trkCmds.close()
                event.queueCall(300, () => { trackView.search(query) })
              }
    })
}
