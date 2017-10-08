import QtQuick 2.8
import QtQuick.XmlListModel 2.0

XmlListModel {
    id: xlm
    query: "/MPL/Item"
    property string hostUrl

    readonly property string mcwsFields: "name,artist,album,genre,media type"
    readonly property var fields: mcwsFields.split(',')

    function newRole() {
        return Qt.createQmlObject("import QtQuick.XmlListModel 2.0; XmlRole { }", xlm);
    }
    function setupRoles()
    {
        if (roles.length < fields.length) {
            for(var i=0; i<fields.length; ++i)
            {
                var role = newRole()
                role.name = fields[i].replace(/ /g, "")
                role.query = "Field[" + String(i+2) + "]/string()"
                roles.push(role)
            }
        }
    }

    function loadPlayingNow(zoneid)
    {
        setupRoles()
        source = ""
        source = hostUrl + "Playback/Playlist?Fields=" + mcwsFields + "&Zone=" + zoneid
    }

    function loadSearch(search)
    {
        setupRoles()
        source = ""
        source = hostUrl + "Files/Search?Fields=" + mcwsFields + "&Shuffle=1&query=" + search
    }

    // Filekey (mcws: Key) will always be the first field returned
    XmlRole { name: "filekey";  query: "Field[1]/string()" }

}
