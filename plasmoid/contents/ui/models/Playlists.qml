import QtQuick 2.8
import QtQuick.Controls 2.12
import QtQuick.XmlListModel 2.0
import '../helpers'

Item {
    id: root
    property alias comms: tm.comms
    readonly property alias items: sf
    property alias filterString: sf.filterString
    readonly property alias trackModel: tm

    property string filterType: 'All'

    property list<Action> searchActions: [
        Action {
            text: 'All'
            checkable: true
            icon.name: root.icon(text)
            checked: text === filterType
            onTriggered: filterType = text
        },
        Action {
            text: 'Smartlist'
            checkable: true
            icon.name: root.icon(text)
            checked: text === filterType
            onTriggered: filterType = text
        },
        Action {
            text: 'Playlist'
            checkable: true
            icon.name: root.icon(text)
            checked: text === filterType
            onTriggered: filterType = text
        },
        Action {
            text: 'Group'
            checkable: true
            icon.name: root.icon(text)
            checked: text === filterType
            onTriggered: filterType = text
        }
    ]

    signal debugLogger(var title, var msg, var obj)

    function icon(type) {
        switch (type.toLowerCase()) {
            case 'playlist':    return 'view-media-playlist'
            case 'smartlist':   return 'source-smart-playlist'
            case 'group':       return 'edit-group'
            default:            return 'show-all-effects'
        }
    }

    // load the Playlists from the mcws host
    function load() {
        clear()
        xlm.load()
    }

    // load tracks for the playlist plID
    function loadTracks(plID) {
        tm.constraintString = 'playlist=' + plID
        tm.load()
    }

    function clear() {
        tm.clear()
        xlm.source = ''
    }

    onFilterTypeChanged: {
        if (filterType === '') {
            filterType = 'All'
        }
        if (xlm.count === 0)
            xlm.load()
        else
            sf.invalidateFilter()
    }

    BaseSortFilterModel {
        id: sf
        sourceModel: xlm
        property var exclude: ['task --', 'handheld --', 'sidecar', 'image &', ' am', ' pm']

        filterRowCallback: function (i, p) {
            var pl = xlm.get(i)

            // check playlist name for "excluded" strings
            if (exclude.some(ex => pl.name.toLowerCase().includes(ex)))
                return false

            if (filterString.length > 0) {
                if (!pl.name.toLowerCase().includes(filterString.toLowerCase()))
                   return false
            }

            return (filterType === "All")
                    ? pl.type !== "Group"
                    : filterType === pl.type
        }
    }

    // Playlists Model
    BaseXml {
        id: xlm
        hostUrl: tm.comms.hostUrl
        onHostUrlChanged: root.clear()
        mcwsQuery: 'Playlists/List'

        XmlRole { name: "id";   query: "Field[1]/string()" }
        XmlRole { name: "name"; query: "Field[2]/string()" }
        XmlRole { name: "path"; query: "Field[3]/string()" }
        XmlRole { name: "type"; query: "Field[4]/string()" }

    }

    // Tracklist Model for the current playlist (currentIndex)
    Searcher {
        id: tm
        searchCmd: 'Playlist/Files?'
        onDebugLogger: root.debugLogger(title, msg, obj)
    }
}
