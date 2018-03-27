import QtQuick 2.8
import org.kde.plasma.core 2.0 as PlasmaCore
import '../code/utils.js' as Utils

Item {
    property var comms
    readonly property alias items: sfModel

    property var allFields: []
    readonly property var mcwsFieldList: []
    readonly property var mcwsSortFields: []

    property alias  sortField: sfModel.sortRole

    property string searchCmd: 'Files/Search'
                               + (autoShuffle ? '?Shuffle=1&' : '?')
                               + 'query='
    property string logicalJoin: 'and'
    property var    constraintList: ({})
    property string constraintString: ''
    property bool   autoShuffle: false
    property bool   useFields: true

    Component.onCompleted: d.init()

    QtObject {
        id: d

        property var mcwsSearchFields: ({})

        function init() {
            mcwsFieldList.length = 0
            mcwsSortFields.length = 0
            mcwsSearchFields = {}

            allFields.forEach(function(fld) {
                mcwsFieldList.push(fld.field)
                if (fld.sortable)
                    mcwsSortFields.push(fld.field)
                if (fld.searchable)
                    mcwsSearchFields[Utils.toRoleName(fld.field)] = ''
            })
        }

    }

    // https://wiki.jriver.com/index.php/Search_Language#Comparison_Operators
    onConstraintListChanged: {
        constraintString = ''
        if (Object.keys(constraintList).length === 0)
            tm.clear()
        else {
            var constraints = Object.assign({}, d.mcwsSearchFields, constraintList)
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
            clear()
    }

    signal searchBegin()
    signal searchDone(var count)

    function addField(fldObj) {
        if (typeof fldObj !== 'object')
            return false

        var newFld = Object.assign({}, {field: '', sortable: false, searchable: false, mandatory: false}, fldObj)
        if (newFld.field === '')
            return false

        allFields.push(newFld)
        d.init()
        return true
    }
    function setFieldProperty(name, prop, val) {
        var obj = allFields.find(function(fld) { return fld.field.toLowerCase() === name.toLowerCase() })
        if (obj) {
            obj[prop] = val
            d.init()
            return true
        }
        return false
    }

    function removeField(name) {
        var ndx = allFields.findIndex(function(fld) { return fld.field.toLowerCase === name.toLowerCase() & !fld.mandatory })
        if (ndx !== -1) {
            allFields.splice(ndx,1)
            d.init()
            return true
        }
        return false
    }

    function load(query) {
        if (comms === undefined) {
            console.log('Searcher::load - Undefined comms connection')
            searchDone(0)
            return
        }
        searchBegin()
        tm.clear()

        var fldstr = ''
        if (useFields) {
            if (mcwsFieldList.length > 0) {
                fldstr = '&Fields=' + mcwsFieldList.join(',').replace(/#/g, '%23')
                // append an obj with all fields present to define the lm.
                // fixes the case where the first record returned by mcws
                // does not contain values for all of the fields in the query
                var obj = {}
                mcwsFieldList.forEach(function(fld) { obj[Utils.toRoleName(fld)] = '' })
                tm.append(obj)
                tm.remove(0)
            } else {
                fldstr = '&NoLocalFileNames=1'
            }
        }
        comms.loadModel(searchCmd
                            + (query === undefined || query === '' ? '' : query)
                            + fldstr
                        , tm
                        , searchDone)
    }
    function clear() {
        constraintList = {}
        tm.clear()
    }

    PlasmaCore.SortFilterModel {
        id: sfModel
        sourceModel: tm

        function forEach(fun) {
            tm.forEach(fun)
        }
        function findIndex(fun) {
            return mapRowFromSource(tm.findIndex(fun))
        }
        function find(fun) {
            return tm.find(fun)
        }
        function filter(fun) {
            var ret = []
            tm.filter(fun).forEach(function(ndx) { ret.push(mapRowFromSource(ndx)) })
            return ret
        }
    }

    BaseListModel {
        id: tm
    }
}
