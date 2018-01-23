import QtQuick.XmlListModel 2.0

BaseXml {
    property string queryField: 'artist'
    property string mediaType: 'audio'

    onQueryFieldChanged: reset()
    onHostUrlChanged: reset()
    onMediaTypeChanged: reset()

    function reset() {
        load("Library/Values?Field=%1%2".arg(queryField).arg(mediaType !== '' ? '&Files=[Media Type]=[%1]'.arg(mediaType) : ''))
    }

    XmlRole { name: "value"; query: "string()" }
}
