import QtQuick 2.8
import org.kde.plasma.core 2.1 as PlasmaCore
import QtQuick.XmlListModel 2.0

Item {

    property alias comms: tm.comms
    readonly property alias items: sf
    readonly property alias trackModel: tm

    property string filterType: ''
    property int currentIndex: -1

    property string currentID: ''
    property string currentName: ''
    readonly property var exclude: ['task', 'handheld', 'podcast', 'sidecar', 'image']

    signal loadTracksBegin()
    signal loadTracksDone(var count)

    onCurrentIndexChanged: {
        if (currentIndex !== -1) {
            currentID = sf.get(currentIndex).id
            currentName = sf.get(currentIndex).name
            tm.load(currentID)
        } else {
            currentID = ''
            currentName = ''
            filterType = ''
            tm.clear()
        }
    }

    /* HACK: Use of the SortFilterModel::filterCallback.  It doesn't really
      support xmllistmodel filterRole/String, so instead of invalidate(),
      force a reload, using sfm callback to filter.
    */
    onFilterTypeChanged: {
        if (filterType !== '') {
            filterType = filterType.toLowerCase()
            xlm.load(true)
        }
    }

    // Filter for the Playlists Model, see note above
    PlasmaCore.SortFilterModel {
        id: sf
        sourceModel: xlm
        filterCallback: (i) => {
            var pl = xlm.get(i)
            var searchStr = pl.name.toLowerCase()

            // check for "excluded" strings
            if (exclude.findIndex((exclStr) => { return searchStr.includes(exclStr) }) !== -1)
                return false

            return (filterType === "all")
                    ? pl.type === "Group" ? false : true
                    : filterType.indexOf(pl.type.toLowerCase()) !== -1
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
    }

    // Tracklist Model for the current playlist (currentIndex)
    Searcher {
        id: tm
        searchCmd: 'Playlist/Files?playlist='
        onSearchBegin: loadTracksBegin()
        onSearchDone:  loadTracksDone(count)
    }
}
