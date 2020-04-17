import QtQuick 2.8
import QtQuick.Controls 2.12
import '../helpers'
import '../helpers/utils.js' as Utils

Item {
    id: root
    property Reader comms
    property alias items: sfm
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
    // Array of search field actions (searchable fields)
    property var searchFieldActions: []
    // return an object with all field names as properties (strings)
    readonly property var defaultRecordLayout: {
        var ret = {key: ''}
        mcwsFields.forEach((fld) => {
                if (fld.mandatory)
                    ret[Utils.toRoleName(fld.field)] = ''
        })
        return ret
    }

    // Rebuild sort/search actions lists
    onMcwsFieldsChanged: {

        if (sortActions.length > 0) {
            sortActions.forEach((item) => { item.destroy(100) })
            sortActions.length = 0
        }
        if (searchFieldActions.length > 0) {
            searchFieldActions.forEach((item) => { item.destroy(100) })
            searchFieldActions.length = 0
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

                searchFieldActions.push(searchFieldComp.createObject(root, { text: fld.field, checked: fld.searchable }))
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
    // Searchfield action
    Component {
        id: searchFieldComp
        Action {
            checkable: true
        }
    }

    BaseListModel {
        id: blm
    }
    BaseSortFilterModel {
        id: sfm
        sortRole: Utils.toRoleName(sortField)
    }

    property string sortField: ''
    onSortFieldChanged: Qt.callLater(sortReset)

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
            blm.clear()
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
    signal sortReset()
    signal debugLogger(var obj, var msg)

    function setConstraintList(str) {
        let obj = {}
        searchFieldActions.forEach((act) => { if (act.checked) obj[act.text] = str })
        constraintList = obj
    }

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
        sfm.sourceModel = null
        blm.clear()

        let fldstr = ''
        if (useFields) {
            if (mcwsFieldList.length > 0) {
                fldstr = '&Fields=' + mcwsFieldList.join(',').replace(/#/g, '%23')
                // append a default record layout to define the model.
                // fixes the case where the first record returned by mcws
                // does not contain values for all of the fields in the constraintString
                blm.append(defaultRecordLayout)
            } else {
                fldstr = '&NoLocalFileNames=1'
            }
        }

        let cmd = searchCmd
            + (constraintString === undefined || constraintString === '' ? '' : constraintString)
            + fldstr

        comms.loadModelJSON(cmd + '&action=JSON', blm,
                        (cnt) =>
                        {
                            sfm.sourceModel = blm
                            searchDone(cnt)
                        } )
        debugLogger('Searcher::load', '\n\n' + cmd)
    }

    function clear() {
        Utils.simpleClear(constraintList)
        blm.clear()
    }
}
