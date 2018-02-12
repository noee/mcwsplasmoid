import QtQuick 2.8
import '..'

Item {
    property string mcwsFields: "Name,Artist,Album,Genre,Duration,Media Type,Media Sub Type"
    property string queryCmd: ''
    property var comms

    readonly property alias items: lm

    onQueryCmdChanged: {
        if (queryCmd === '')
            lm.clear()
    }

    function load(query) {
        if (comms === undefined) {
            console.log('TrackModel::load - Undefined comms connection')
            lm.resultsReady(0)
            return
        }

        lm.aboutToLoad()
        lm.clear()
        comms.loadModel(queryCmd + (query === undefined || query === '' ? '' : query)
                            + (mcwsFields !== '' ? '&Fields=' + mcwsFields : '&NoLocalFileNames=1')
                        , lm
                        , lm.resultsReady)
    }

    ListModel {
        id: lm

        signal aboutToLoad()
        signal resultsReady(var count)

        function findIndex(compare) {
            if (typeof compare !== 'function')
                return -1

            for (var i=0, len = lm.count; i<len; ++i) {
                if (compare(lm.get(i)))
                    return i
            }
            return -1
        }
        function find(compare) {
            if (typeof compare !== 'function')
                return undefined

            for (var i=0, len = lm.count; i<len; ++i) {
                if (compare(lm.get(i)))
                    return lm.get(i)
            }
            return undefined
        }
        function forEach(fun) {
            if (typeof fun !== 'function')
                return

            for (var i=0, len = lm.count; i<len; ++i) {
                fun(lm.get(i))
            }
        }

    }
}
