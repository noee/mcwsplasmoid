import QtQuick 2.8
import org.kde.plasma.core 2.0 as PlasmaCore

Item {
    property var comms
    readonly property alias items: sfModel

    property string       mcwsFields: "Name,Artist,Album,Genre,Duration,Media Type,Media Sub Type"
    readonly property var mcwsFieldList: mcwsFields.split(',')

    property alias  sortField: sfModel.sortRole

    property string searchCmd: 'Files/Search'
                               + (autoShuffle ? '?Shuffle=1&' : '?')
                               + 'query='
    property string logicalJoin: 'and'
    property var    constraintList: ({})
    property string constraintString: ''
    property bool   autoShuffle: false

    // https://wiki.jriver.com/index.php/Search_Language#Comparison_Operators
    onConstraintListChanged: {
        constraintString = ''
        if (Object.keys(constraintList).length === 0)
            tm.clear()
        else {
            var constraints = Object.assign({}, { name: ''
                                                ,artist: ''
                                                ,album: ''
                                                ,genre: '' }, constraintList)
            var list = []
            for(var k in constraints) {
                if (constraints[k] !== '')
                    list.push('[%1]=%2'.arg(k).arg(constraints[k]))
            }
            constraintString = list.join(' %1 '.arg(logicalJoin))
            load(constraintString)
        }
    }
    onSearchCmdChanged: {
        if (searchCmd === '')
            tm.clear()
    }

    signal searchBegin()
    signal searchDone(var count)

    function load(query) {
        if (comms === undefined) {
            console.log('TrackModel::load - Undefined comms connection')
            searchDone(0)
            return
        }
        searchBegin()
        tm.clear()

        // append an obj with all fields present to define the lm.
        // fixes the case where the first record returned by mcws
        // does not contain values for all of the fields in the query
        var obj = {}
        mcwsFieldList.forEach(function(fld) { obj[fld.toLowerCase().replace(/ /g, '')] = '' })
        tm.append(obj)
        tm.remove(0)

        comms.loadModel(searchCmd + (query === undefined || query === '' ? '' : query)
                            + (mcwsFields !== '' ? '&Fields=' + mcwsFields : '&NoLocalFileNames=1')
                        , tm
                        , searchDone)
    }

    PlasmaCore.SortFilterModel {
        id: sfModel
        sourceModel: tm

        function forEach(fun) {
            tm.forEach(fun)
        }
        function findIndex(fun) {
            return tm.findIndex(fun)
        }
        function find(fun) {
            return tm.find(fun)
        }
        function filter(fun) {
            return tm.filter(fun)
        }

    }

    BaseListModel {
        id: tm
    }
}
