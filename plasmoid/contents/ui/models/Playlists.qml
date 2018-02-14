import QtQuick 2.8
import QtQuick.XmlListModel 2.0
import org.kde.plasma.core 2.1 as PlasmaCore

Item {

    property alias comms: tm.comms
    readonly property alias items: sf
    readonly property alias tracks: tm.items

    property string filterType: ''
    property int currentIndex: -1

    property string currentID: ''
    property string currentName: ''
    readonly property var exclude: ['task', 'handheld', 'podcast', 'sidecar']

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
            tm.items.clear()
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

    PlasmaCore.SortFilterModel {
        id: sf
        sourceModel: xlm
        filterCallback: function(i)
        {
            var pl = xlm.get(i)
            var searchStr = pl.name.toLowerCase()

            // check for "excluded" strings
            if (exclude.findIndex(function(exclStr) { return searchStr.indexOf(exclStr) !== -1 }) !== -1)
                return false

            return (filterType === "all")
                    ? pl.type === "Group" ? false : true
                    : filterType.indexOf(pl.type.toLowerCase()) !== -1
        }
    }

    // the list of playlists
    BaseXml {
        id: xlm
        hostUrl: tm.comms.hostUrl
        mcwsQuery: 'Playlists/List'

        XmlRole { name: "id";   query: "Field[1]/string()" }
        XmlRole { name: "name"; query: "Field[2]/string()" }
        XmlRole { name: "path"; query: "Field[3]/string()" }
        XmlRole { name: "type"; query: "Field[4]/string()" }
    }
    // the list of tracks for the current playlist (currentIndex)
    TrackModel {
        id: tm
        queryCmd: 'Playlist/Files?playlist='

        onAboutToLoad: loadTracksBegin()
        onResultsReady: loadTracksDone(count)
    }
}
