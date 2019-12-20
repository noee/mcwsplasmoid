import QtQuick 2.9
import QtQuick.Controls 2.5

Action {
    property bool shuffle: false
    property string method: ''

    property var call: ({
        play: (query) => { zoneView.currentPlayer.searchAndPlayNow(query, shuffle) },

        add: (query) => { zoneView.currentPlayer.searchAndAdd(query, false, shuffle) },

        addNext: (query) => { zoneView.currentPlayer.searchAndAdd(query, true, shuffle) },

        show: (query) => { trackView.search(query) }
    })
}
