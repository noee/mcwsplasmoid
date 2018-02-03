import QtQuick.XmlListModel 2.0

BaseXml {
    property string queryField: 'artist'
    property string mediaType: 'audio'

    onQueryFieldChanged: reload()
    onHostUrlChanged: reload()
    onMediaTypeChanged: reload()

    function reload() {
        load("Library/Values?Field=%1%2".arg(queryField).arg(mediaType !== '' ? '&Files=[Media Type]=[%1]'.arg(mediaType) : ''))
    }

    XmlRole { name: "value"; query: "string()" }
}
