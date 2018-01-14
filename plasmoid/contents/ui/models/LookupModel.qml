import QtQuick.XmlListModel 2.0

BaseXml {
    property string queryField
    property string mediaType: 'audio'

    onQueryFieldChanged: reset()
    onHostUrlChanged: reset()
    onMediaTypeChanged: reset()

    function reset() {
        load("Library/Values?Field=%1&Files=[Media Type]=[%2]".arg(queryField).arg(mediaType))
    }

    XmlRole { name: "value"; query: "string()" }
}
