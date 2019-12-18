import QtQuick 2.9
import QtQuick.Controls 2.5

MenuItem {
    property bool shuffle: false
    property var track: ({})

    property string method: ''

    property var call: ({
        play: (query) => { zoneView.currentPlayer.searchAndPlayNow(query, shuffle) },

        add: (query) => { zoneView.currentPlayer.searchAndAdd(query, false, shuffle) },

        addNext: (query) => { zoneView.currentPlayer.searchAndAdd(query, true, shuffle) },

        show: (query) => { trackView.search(query) }
    })
}
