import QtQuick.XmlListModel 2.0

BaseXml {
    property string queryField

    onQueryFieldChanged: load("Library/Values?Files=[Media Type]=[Audio]&Field=" + queryField)

    onHostUrlChanged: queryFieldChanged()

    XmlRole { name: "value"; query: "string()" }
}
