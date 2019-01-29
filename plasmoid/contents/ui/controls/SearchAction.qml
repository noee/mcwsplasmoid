import QtQuick 2.9
import Qt.labs.platform 1.0

MenuItem {
    property bool shuffle: false
    property bool next: false

    function add(query) {
        zoneView.currentPlayer.searchAndAdd(query, next, shuffle)
    }
    function play(query) {
        zoneView.currentPlayer.searchAndPlayNow(query, shuffle)
    }
}
