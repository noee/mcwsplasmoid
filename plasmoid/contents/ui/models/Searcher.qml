import QtQuick 2.8
import QtQuick.Controls 2.12
import '../helpers'
import '../helpers/utils.js' as Utils

Item {
    id: root
    property Reader comms
    property alias items: sfm

    // fields model, {field, sortable, searchable, mandatory}
    property BaseListModel mcwsFields
    onMcwsFieldsChanged: init()

    // return an object with all field names as role-proper properties (null string values)
    readonly property var defaultRecordLayout: {
        var ret = {key: ''}
        mcwsFields.forEach(fld => {
                if (fld.mandatory)
                    ret[Utils.toRoleName(fld.field)] = ''
        })
        return ret
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

    // Default MCWS search command
    // https://wiki.jriver.com/index.php/Search_Language#Comparison_Operators
    property string searchCmd: 'Files/Search'
                               + (autoShuffle ? '?Shuffle=1&' : '?')
                               + 'query='
    onSearchCmdChanged: {
        if (searchCmd === '')
            clear()
    }

    // MCWS searchable fields struct
    // {Artist: '', Album: '', etc...}
    property var    searchFields: ({})

    // Set this prop and call load or use search()
    property string constraintString: ''

    property bool   autoShuffle: false
    property bool   useFields: true
    property string logicalJoin: 'and'

    signal searchBegin()
    signal searchDone(var count)
    signal sortReset()
    signal debugLogger(var obj, var msg)

    // Initialize the search fields struct
    function init() {
        Utils.simpleClear(searchFields)
        mcwsFields.forEach(fld => {
                               if (fld.searchable)
                                   searchFields[fld.field] = ''
                           })
    }

    // Initiates the search after processing 'val'
    // Use this option or set the constraintString and call load
    function search(val) {
        var constraints = {}
        if (!Utils.isObject(val)) {
            for (var f in searchFields)
                constraints[f] = val
        }
        else
            constraints = val

        constraintString = ''
        if (Object.keys(constraints).length === 0)
            blm.clear()
        else {
            let list = []
            for(var k in constraints) {
                if (constraints[k] !== '')
                    list.push('[%1]=%2'.arg(k).arg(constraints[k]))
            }
            constraintString = list.join(' %1 '.arg(logicalJoin))
            load()
        }

    }

    function removeItem(index) {
        blm.remove(sfm.mapRowToSource(index))
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
            if (mcwsFields.count > 0) {
                fldstr = '&Fields='
                mcwsFields.forEach(fld => fldstr += fld.field + ',')
                fldstr = fldstr.replace(/#/g, '%23').slice(0,fldstr.length-1)
                // append a default record layout to define the model.
                // fixes the case where the first record returned by mcws
                // does not contain values for all of the fields in the constraintString
                blm.append(defaultRecordLayout)
            } else {
                fldstr = '&NoLocalFileNames=1'
            }
        }

        let cmd = searchCmd
            + (constraintString ?? '')
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
        blm.clear()
    }
}
