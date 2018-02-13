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
    readonly property var exclude: ['Task', 'Handheld', 'Podcast']

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
      reset the sourceModel to force a reload, using callback to filter.
    */
    onFilterTypeChanged: {
        if (filterType !== '') {
            xlm.source = ''
            xlm.load('Playlists/List')
        }
    }

    PlasmaCore.SortFilterModel {
        id: sf
        sourceModel: xlm
        filterCallback: function(i,str)
        {
            var pl = xlm.get(i)

            if (exclude.findIndex(function(str) { return pl.name.indexOf(str) !== -1 }) !== -1)
                return false

            return (filterType.toLowerCase() === "all")
                    ? pl.type === "Group" ? false : true
                    : filterType.toLowerCase().indexOf(pl.type.toLowerCase()) !== -1
        }
    }

    BaseXml {
        id: xlm
        hostUrl: comms.hostUrl

        XmlRole { name: "id";   query: "Field[1]/string()" }
        XmlRole { name: "name"; query: "Field[2]/string()" }
        XmlRole { name: "path"; query: "Field[3]/string()" }
        XmlRole { name: "type"; query: "Field[4]/string()" }
    }

    TrackModel {
        id: tm
        queryCmd: 'Playlist/Files?playlist='
        Component.onCompleted: {
            aboutToLoad.connect(loadTracksBegin)
            resultsReady.connect(loadTracksDone)
        }
    }
}
