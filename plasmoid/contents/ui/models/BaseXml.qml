import QtQuick 2.8
import QtQuick.XmlListModel 2.0

XmlListModel {
    id: xlm
    query: "/Response/Item"

    property string hostUrl
    property string mcwsFields
    readonly property var fields: mcwsFields.split(',')

    onFieldsChanged: {
        roles.lenth = 0
        source = ""
        for(var i=0; i<fields.length; ++i)
        {
            roles.push(newRole(fields[i].replace(/ /g, ""), "Field[" + String(i+2) + "]/string()"))
        }
    }

    function newRole(name, query) {
        return Qt.createQmlObject("import QtQuick.XmlListModel 2.0; XmlRole { name: \"%1\"; query: \"%2\" }".arg(name).arg(query), xlm);
    }
    function load(cmd) {
        source = hostUrl + cmd
    }
}
