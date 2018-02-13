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
        comms.loadModel(queryCmd + (query === undefined || query === '' ? '' : query)
                            + (mcwsFields !== '' ? '&Fields=' + mcwsFields : '&NoLocalFileNames=1')
                        , items
                        , resultsReady)
    }
}
