import QtQuick 2.8
import QtQuick.Controls 2.12
import QtQuick.XmlListModel 2.0
import org.kde.kitemmodels 1.0

Item {
    id: root
    property alias comms: tm.comms
    readonly property alias items: sf
    readonly property alias trackModel: tm

    property string filterType: ''

    property int        currentIndex: -1
    property string     currentID: ''
    property string     currentName: ''

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

    function icon(type) {
        switch (type.toLowerCase()) {
            case 'playlist':    return 'view-media-playlist'
            case 'smartlist':   return 'source-smart-playlist'
            case 'group':       return 'edit-group'
            default:            return 'show-all-effects'
        }
    }

    onCurrentIndexChanged: {
        if (currentIndex !== -1) {
            let mi = sf.mapToSource(sf.index(currentIndex, 0))
            currentID = xlm.get(mi.row).id
            currentName = xlm.get(mi.row).name
            tm.constraintString = 'playlist=' + currentID
        } else {
            currentID = ''
            currentName = ''
            filterType = ''
            tm.clear()
        }
    }

    onFilterTypeChanged: {
        if (filterType === '') {
            filterType = 'All'
        }
        if (xlm.count === 0)
            xlm.load()
        else
            sf.invalidate()
    }

    KSortFilterProxyModel {
        id: sf
        sourceModel: xlm
        property var exclude: ['task --', 'handheld --', 'sidecar', 'image &', ' am', ' pm']

        filterRowCallback: (i, p) => {
            var pl = xlm.get(i)
            // check playlist name for "excluded" strings
            if (exclude.some((exclStr) => { return pl.name.toLowerCase().includes(exclStr) }))
                return false

            return (filterType === "All")
                    ? pl.type !== "Group"
                    : filterType === pl.type
        }
    }

    // Playlists Model
    BaseXml {
        id: xlm
        hostUrl: tm.comms.hostUrl
        mcwsQuery: 'Playlists/List'

        XmlRole { name: "id";   query: "Field[1]/string()" }
        XmlRole { name: "name"; query: "Field[2]/string()" }
        XmlRole { name: "path"; query: "Field[3]/string()" }
        XmlRole { name: "type"; query: "Field[4]/string()" }

        onStatusChanged: {
            if (status === XmlListModel.Ready)
                currentIndex = 0
        }
    }

    // Tracklist Model for the current playlist (currentIndex)
    Searcher {
        id: tm
        searchCmd: 'Playlist/Files?'
        onDebugLogger: logger.log(obj, msg)
    }
}
