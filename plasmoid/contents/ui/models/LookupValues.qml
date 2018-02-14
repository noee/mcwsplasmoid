import QtQuick 2.8
import QtQuick.XmlListModel 2.0

Item {
    property alias hostUrl: xlm.hostUrl
    readonly property alias items: xlm

    property string queryField: ''
    property string queryFilter: ''
    property string mediaType: 'audio'

    onHostUrlChanged: queryField = ''

    signal dataReady(var count)

    BaseXml {
        id: xlm
        mcwsQuery: queryField !== ''
                   ? 'Library/Values?Field=' + queryField
                    + (queryFilter !== '' ? '&Filter=' + queryFilter : '')
                    + (mediaType !== '' ? '&Files=[Media Type]=[%1]'.arg(mediaType) : '')
                   : ''

        XmlRole { name: "field"; query: "@Name/string()" }
        XmlRole { name: "value"; query: "string()" }

        onResultsReady: dataReady(count)
    }
}
