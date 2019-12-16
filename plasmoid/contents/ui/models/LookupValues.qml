import QtQuick 2.8
import QtQuick.Controls 2.12
import QtQuick.XmlListModel 2.0
import '../helpers/utils.js' as Utils

Item {
    id: root

    property alias hostUrl: xlm.hostUrl
    readonly property alias items: xlm

    property var searchActions: []

    property string queryField: ''
    property string queryFilter: ''
    property string mediaType: 'audio'

    onHostUrlChanged: queryField = ''

    property var sourceModel: []
    onSourceModelChanged: {
        if (searchActions.length > 0) {
            searchActions.forEach((item) => { item.destroy(100) })
            searchActions.length = 0
        }
        // Load actions
        sourceModel.forEach((fld) => {
            searchActions.push(lkpComp.createObject(root, { text: fld }))
        })

    }

    Component {
        id: lkpComp
        Action {
            checkable: true
            checked: text === queryField
            onTriggered: queryField = text
        }
    }

    BaseXml {
        id: xlm
        mcwsQuery: queryField !== ''
                   ? 'Library/Values?Field=' + queryField.replace(/#/g, '%23')
                    + (queryFilter !== '' ? '&Filter=' + queryFilter : '')
                    + (mediaType !== '' ? '&Files=[Media Type]=[%1]'.arg(mediaType) : '')
                   : ''

        XmlRole { name: "field"; query: "@Name/string()" }
        XmlRole { name: "value"; query: "string()" }
    }
}
