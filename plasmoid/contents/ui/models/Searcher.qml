import QtQuick 2.8
import QtQuick.Controls 2.12
import '../helpers'
import '../helpers/utils.js' as Utils

Item {
    id: root
    property var comms
    property BaseListModel items: BaseListModel{}
    // array of field objs, {field, sortable, searchable, mandatory}
    property var mcwsFields: []
    // Array of sort Actions (sortable fields)
    property var sortActions: []
    // return an array of all field names
    readonly property var mcwsFieldList: {
        var ret = []
        mcwsFields.forEach((fld) => { ret.push(fld.field) })
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
    // return an object with all field names as properties (strings)
    readonly property var defaultRecordLayout: {
        var ret = {key: ''}
        mcwsFields.forEach((fld) => {
                ret[Utils.toRoleName(fld.field)] = ''
        })
        return ret
    }

    // Reset sort actions if field def changes
    onMcwsFieldsChanged: {
        if (sortActions.length > 0) {
            sortActions.forEach((item) => { item.destroy(100) })
            sortActions.length = 0
        }

        if (mcwsFields.length > 0) {
            sortActions.push(Qt.createQmlObject(
            'import QtQuick.Controls 2.12;
                Action { text: "No Sort";
                checkable: true;
                checked: sortField === "";
                onTriggered: sortField = "" }', root))

            mcwsFields.forEach((fld) => {
                if (fld.sortable)
                    sortActions.push(actComp.createObject(root, { text: fld.field }))
            })
        }
    }

    // Sort action triggers sort field
    Component {
        id: actComp
        Action {
            checkable: true
            checked: text === sortField
            onTriggered: sortField = text
        }
    }

    property string  sortField: ''
    onSortFieldChanged: {
        if (sortField === '') {
            load()
            sortReset()
        }
        else {
            _sort()
        }
    }

    // Use ThreadedModelSorter only if row count is high
    function _sort() {
        if (items.count >= 1500)
            sorter.sort(sortField)
        else {
            sortBegin()
            items.sort(sortField)
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
    // Setting constraint list will build the constraint String....
    property var    constraintList: ({})
    // ...or just set the constraint String
    property string constraintString: ''

    property bool   autoShuffle: false
    property bool   useFields: true

    // https://wiki.jriver.com/index.php/Search_Language#Comparison_Operators
    onConstraintListChanged: {
        constraintString = ''
        if (Object.keys(constraintList).length === 0)
            items.clear()
        else {
            let list = []
            for(var k in constraintList) {
                if (constraintList[k] !== '')
                    list.push('[%1]=%2'.arg(k).arg(constraintList[k]))
            }
            constraintString = list.join(' %1 '.arg(logicalJoin))
            load()
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

    function load() {
        if (comms === undefined) {
            console.warn('Searcher::load - Undefined comms connection')
            searchDone(0)
            return
        }
        searchBegin()
        items.clear()

        let fldstr = ''
        if (useFields) {
            if (mcwsFieldList.length > 0) {
                fldstr = '&Fields=' + mcwsFieldList.join(',').replace(/#/g, '%23')
                // append a default record layout to define the model.
                // fixes the case where the first record returned by mcws
                // does not contain values for all of the fields in the constraintString
                items.append(defaultRecordLayout)
            } else {
                fldstr = '&NoLocalFileNames=1'
            }
        }

        let cmd = searchCmd
            + (constraintString === undefined || constraintString === '' ? '' : constraintString)
            + fldstr

        comms.loadModel( cmd, items,
                        (cnt) =>
                        {
                            searchDone(cnt)
                            if (sortField !== '')
                                _sort()
                        } )
        debugLogger('Searcher::load', '\n\n' + cmd)
    }

    function clear() {
        Utils.simpleClear(constraintList)
        items.clear()
    }
}
