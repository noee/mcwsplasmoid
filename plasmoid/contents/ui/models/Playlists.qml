import QtQuick 2.8
import QtQuick.XmlListModel 2.0
import org.kde.plasma.core 2.1 as PlasmaCore

Item {

    property alias hostUrl: xlm.hostUrl
    readonly property alias model: sf
    property string filterType: ""

    function clear() {
        sf.sourceModel = null
        xlm.source = ""
        filterType = ""
    }

    /* HACK: Use of the SortFilterModel::filterCallback.  It doesn't really
      support xmllistmodel filterRole/String, so instead of invalidate(),
      reset the sourceModel to force a reload, using callback to filter.
    */
    onFilterTypeChanged: {
        if (filterType !== "") {
            sf.sourceModel = null
            xlm.source = ""
            xlm.load("Playlists/List")
            sf.sourceModel = xlm
        }
    }

    PlasmaCore.SortFilterModel {
        id: sf
        filterCallback: function(i,str)
        {
            return (filterType.toLowerCase() === "all")
                    ? xlm.get(i).type === "Group" ? false : true
                    : filterType.toLowerCase().indexOf(xlm.get(i).type.toLowerCase()) !== -1
        }
    }

    BaseXml {
        id: xlm

        XmlRole { name: "id";   query: "Field[1]/string()" }
        XmlRole { name: "name"; query: "Field[2]/string()" }
        XmlRole { name: "path"; query: "Field[3]/string()" }
        XmlRole { name: "type"; query: "Field[4]/string()" }

    }
}
