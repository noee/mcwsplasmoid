import QtQuick 2.8
import QtQuick.XmlListModel 2.0

XmlListModel {
    id: xlm
    query: "/Response/Item"

    property string hostUrl
    property string mcwsFields: ''
    readonly property var fields: mcwsFields.split(',')
    property int roleOffset: 0

    signal resultsReady()

    function newRole(name, query) {
        return Qt.createQmlObject("import QtQuick.XmlListModel 2.0; XmlRole { name: \"%1\"; query: \"%2\" }".arg(name).arg(query), xlm);
    }
    function load(cmd) {
        source = hostUrl + cmd + (mcwsFields !== '' ? '&Fields=' + mcwsFields : '')
    }

    function findIndex(compare) {
        if (typeof compare !== 'function')
            return -1

        for (var i=0, len = xlm.count; i<len; ++i) {
            if (compare(xlm.get(i)))
                return i
        }
        return -1
    }
    function find(compare) {
        if (typeof compare !== 'function')
            return undefined

        for (var i=0, len = xlm.count; i<len; ++i) {
            if (compare(xlm.get(i)))
                return xml.get(i)
        }
        return undefined
    }
    function forEach(fun) {
        if (typeof fun !== 'function')
            return

        for (var i=0, len = xlm.count; i<len; ++i) {
            fun(xlm.get(i))
        }
    }

    onFieldsChanged: {
        roles.lenth = 0
        source = ""
        for(var i=0; i<fields.length; ++i)
        {
            roles.push(newRole(fields[i].replace(/ /g, ""), "Field[" + String(i+roleOffset+1) + "]/string()"))
        }
    }

    onStatusChanged: {
        if (status === XmlListModel.Ready)
            resultsReady()
    }
}
