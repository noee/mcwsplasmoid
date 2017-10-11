import QtQuick.XmlListModel 2.0

BaseXml {

    onHostUrlChanged: load("Playlists/List")

    XmlRole { name: "id";   query: "Field[1]/string()" }
    XmlRole { name: "name"; query: "Field[2]/string()" }
    XmlRole { name: "path"; query: "Field[3]/string()" }
    XmlRole { name: "type"; query: "Field[4]/string()" }
}
