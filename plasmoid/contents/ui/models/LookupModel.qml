import QtQuick.XmlListModel 2.0

BaseXml {
    property string queryField

    onQueryFieldChanged: load("Library/Values?Field=" + queryField + "&Files=[Media Type]=audio")

    onHostUrlChanged: queryFieldChanged()

    XmlRole { name: "value"; query: "string()" }
}
