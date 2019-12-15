import QtQuick 2.8
import '../helpers'
import '../helpers/utils.js' as Utils

Item {
    id: root
    property var comms
    property BaseListModel items: BaseListModel{}
    // array of field objs, {field, sortable, searchable, mandatory}
    property var mcwsFields: []
    // return an array of all field names
    readonly property var mcwsFieldList: {
        var ret = []
        mcwsFields.forEach((fld) => { ret.push(fld.field) })
        return ret
    }
    // return an array of field names that you can sort on
    readonly property var mcwsSortFields: {
        var ret = []
        mcwsFields.forEach((fld) => {
            if (fld.sortable)
                ret.push(fld.field)
        })
        return ret
    }
    // return an array of field names that you can search on
    readonly property var mcwsSearchFields: {
        var ret = []
        mcwsFields.forEach((fld) => {
            if (fld.searchable)
                ret.push(fld.field)
        })
        return ret
    }
    // return an object with searchable field names as properties
    readonly property var mcwsSearchObject: {
        var ret = {}
        mcwsFields.forEach((fld) => {
            if (fld.searchable)
                ret[Utils.toRoleName(fld.field)] = ''
        })
        return ret
    }
    // return an object with all field names as properties (strings)
    readonly property var defaultRecordLayout: {
        var ret = {key: ''}
        mcwsFields.forEach((fld) => {
                ret[Utils.toRoleName(fld.field)] = ''
        })
        return ret
    }

    property string  sortField: ''
    onSortFieldChanged: {
        if (sortField === '') {
            load(constraintString)
            sortReset()
        }
        else {
            _sort()
        }
    }

    function _sort() {
        if (items.count >= 500)
            sorter.sort(sortField)
        else {
            sortBegin()
            items.sort((item1, item2) => {
                           let role = Utils.toRoleName(sortField)
                           if (item1[role] < item2[role])
                              return -1
                           if (item1[role] > item2[role])
                              return 1
                           else
                              return 0
                       })
            sortDone()
        }
    }

    ThreadedModelSorter {
        id: sorter
        model: items

        onStart: sortBegin()
        onDone: sortDone()
    }

    property string searchCmd: 'Files/Search'
                               + (autoShuffle ? '?Shuffle=1&' : '?')
                               + 'query='
    property string logicalJoin: 'and'
    property var    constraintList: ({})
    property string constraintString: ''
    property bool   autoShuffle: false
    property bool   useFields: true

    // https://wiki.jriver.com/index.php/Search_Language#Comparison_Operators
    onConstraintListChanged: {
        constraintString = ''
        if (Object.keys(constraintList).length === 0)
            items.clear()
        else {
            var constraints = Object.assign({}, mcwsSearchObject, constraintList)
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
    signal sortBegin()
    signal sortDone()
    signal sortReset()
    signal debugLogger(var obj, var msg)

    function addField(fldObj) {
        if (typeof fldObj !== 'object')
            return false

        var newFld = Object.assign({}, {field: '', sortable: false, searchable: false, mandatory: false}, fldObj)
        if (newFld.field === '')
            return false

        mcwsFields.push(newFld)
        return true
    }

    function setFieldProperty(name, prop, val) {
        var obj = mcwsFields.find((fld) => { return fld.field.toLowerCase() === name.toLowerCase() })
        if (obj) {
            obj[prop] = val
            return true
        }
        return false
    }

    function removeField(name) {
        var ndx = mcwsFields.findIndex((fld) => { return fld.field.toLowerCase === name.toLowerCase() & !fld.mandatory })
        if (ndx !== -1) {
            mcwsFields.splice(ndx,1)
            return true
        }
        return false
    }

    function load(query) {
        if (comms === undefined) {
            console.warn('Searcher::load - Undefined comms connection')
            searchDone(0)
            return
        }
        searchBegin()
        items.clear()

        var fldstr = ''
        if (useFields) {
            if (mcwsFieldList.length > 0) {
                fldstr = '&Fields=' + mcwsFieldList.join(',').replace(/#/g, '%23')
                // append a default record layout to define the model.
                // fixes the case where the first record returned by mcws
                // does not contain values for all of the fields in the query
                items.append(defaultRecordLayout)
            } else {
                fldstr = '&NoLocalFileNames=1'
            }
        }
        comms.loadModel(searchCmd
                            + (query === undefined || query === '' ? '' : query)
                            + fldstr
                        , items
                        , (cnt) => { searchDone(cnt); if (sortField !== '') _sort() } )

        debugLogger('Searcher::load', searchCmd
                    + (query === undefined || query === '' ? '' : query)
                    + fldstr)
    }

    function clear() {
        constraintList = {}
        items.clear()
    }
}
