import QtQuick.XmlListModel 2.0

BaseXml {

    function load(field) {
        source = hostUrl + "Library/Values?Field=" + field + "&Files=[Media Type]=audio"
    }

    XmlRole { name: "value"; query: "string()" }
}
