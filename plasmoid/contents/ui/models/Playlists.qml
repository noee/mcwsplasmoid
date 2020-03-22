import QtQuick 2.8
import QtQuick.Controls 2.12
import QtQuick.XmlListModel 2.0
import org.kde.kitemmodels 1.0

Item {

    property alias comms: tm.comms
    readonly property alias items: sf
    readonly property alias trackModel: tm

    property string filterType: ''
    readonly property var exclude: ['task', 'handheld', 'podcast', 'sidecar', 'image']

    property int        currentIndex: -1
    property string     currentID: ''
    property string     currentName: ''

    property list<Action> searchActions: [
        Action {
            text: 'All'
            checkable: true
            checked: text === filterType
            onTriggered: filterType = text
        },
        Action {
            text: 'Smartlists'
            checkable: true
            checked: text === filterType
            onTriggered: filterType = text
        },
        Action {
            text: 'Playlists'
            checkable: true
            checked: text === filterType
            onTriggered: filterType = text
        },
        Action {
            text: 'Groups'
            checkable: true
            checked: text === filterType
            onTriggered: filterType = text
        }
    ]

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

        filterRowCallback: (i, p) => {
            var pl = xlm.get(i)
            var searchStr = pl.name.toLowerCase()

            // check for "excluded" strings
            if (exclude.findIndex((exclStr) => { return searchStr.includes(exclStr) }) !== -1)
                return false

            return (filterType === "All")
                    ? pl.type !== "Group"
                    : filterType.toLowerCase().includes(pl.type.toLowerCase())
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
