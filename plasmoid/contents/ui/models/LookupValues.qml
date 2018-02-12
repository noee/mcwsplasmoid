import QtQuick 2.8
import QtQuick.XmlListModel 2.0

Item {
    property alias hostUrl: xlm.hostUrl
    readonly property alias items: xlm

    property string queryField: ''
    property string queryFilter: ''
    property string mediaType: 'audio'

    onQueryFieldChanged: reload()
    onMediaTypeChanged: reload()
    onQueryFilterChanged: reload()

    onHostUrlChanged: queryField = ''

    signal dataReady()

    function reload() {
        xlm.load('Library/Values?Field=' + queryField
                 + (queryFilter !== '' ? '&Filter=' + queryFilter : '')
                 + (mediaType !== '' ? '&Files=[Media Type]=[%1]'.arg(mediaType) : ''))
    }

    BaseXml {
        id: xlm
        XmlRole { name: "field"; query: "@Name/string()" }
        XmlRole { name: "value"; query: "string()" }
        onResultsReady: dataReady()
    }
}
