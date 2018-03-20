import QtQuick 2.8
import '..'

Item {
    property string mcwsFields: "Name,Artist,Album,Genre,Duration,Media Type,Media Sub Type"
    property string queryCmd: ''
    property var comms

    readonly property BaseListModel items: BaseListModel{}

    signal aboutToLoad()
    signal resultsReady(var count)

    onQueryCmdChanged: {
        if (queryCmd === '')
            items.clear()
    }

    function load(query) {
        if (comms === undefined) {
            console.log('TrackModel::load - Undefined comms connection')
            resultsReady(0)
            return
        }
        aboutToLoad()
        items.clear()

        // append an obj with all fields present to define the lm.
        // fixes the case where the first record returned by mcws
        // does not contain values for all of the fields in the query
        var obj = {}
        var flds = mcwsFields.toLowerCase().replace(/ /g, '').split(',')
        flds.forEach(function(fld) { obj[fld] = '' })
        items.append(obj)
        items.remove(0)

        comms.loadModel(queryCmd + (query === undefined || query === '' ? '' : query)
                            + (mcwsFields !== '' ? '&Fields=' + mcwsFields : '&NoLocalFileNames=1')
                        , items
                        , resultsReady)
    }
}
