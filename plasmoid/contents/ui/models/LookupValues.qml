import QtQuick 2.8
import QtQuick.Controls 2.12
import QtQuick.XmlListModel 2.0

Item {
    id: root

    property alias hostUrl: xlm.hostUrl
    readonly property alias items: xlm

    // list of lookups, based search fields
    property var searchActions: []
    property var mcwsFields: []

    property string queryField: ''
    property string queryFilter: ''
    property string mediaType: 'audio'

    onHostUrlChanged: queryField = ''

    onMcwsFieldsChanged: {
        if (searchActions.length > 0) {
            searchActions.forEach((item) => { item.destroy(100) })
            searchActions.length = 0
        }
        // Load actions
        mcwsFields.forEach((fld) => {
            if (fld.searchable)
                searchActions.push(lkpComp.createObject(root, { text: fld.field }))
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
