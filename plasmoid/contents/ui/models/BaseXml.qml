import QtQuick 2.11
import QtQuick.XmlListModel 2.0
import '../helpers/utils.js' as Utils

XmlListModel {
    id: xlm
    query: "/Response/Item"

    property string hostUrl
    property string mcwsFields: ''
    property string mcwsQuery: ''

    signal aboutToLoad()
    signal resultsReady(var count)

    onSourceChanged: {
        if (source.toString() !== '')
            aboutToLoad()
    }

    onMcwsQueryChanged: load()

    onHostUrlChanged: source = ''

    onMcwsFieldsChanged: {
        roles.length = 0
        source = ''
        mcwsFields.split(',').forEach(function(fld)
        {
            roles.push(
                Qt.createQmlObject('import QtQuick.XmlListModel 2.0;
                                    XmlRole { name: "%1";
                                    query: "Field[@Name=\'%2\']/string()" }'.arg(fld.replace(/ /g, "").toLowerCase()).arg(fld), xlm))
        })
    }

    onStatusChanged: {
        if (status === XmlListModel.Ready)
            resultsReady(count)
    }

    function load(resetSource) {
        if (resetSource !== undefined & resetSource)
            source = ''
        if (mcwsQuery !== '')
            source = hostUrl + mcwsQuery + (mcwsFields !== '' ? '&Fields=' + mcwsFields : '')
    }

    function findIndex(compare) {
        if (!Utils.isFunction(compare))
            return -1

        for (var i=0, len = xlm.count; i<len; ++i) {
            if (compare(xlm.get(i)))
                return i
        }
        return -1
    }
    function find(compare) {
        if (!Utils.isFunction(compare))
            return undefined

        for (var i=0, len = xlm.count; i<len; ++i) {
            if (compare(xlm.get(i)))
                return xml.get(i)
        }
        return undefined
    }
    function forEach(fun) {
        if (!Utils.isFunction(compare))
            return

        for (var i=0, len = xlm.count; i<len; ++i) {
            fun(xlm.get(i))
        }
    }

}
