import QtQuick 2.8
import QtQuick.Controls 2.12
import QtQuick.XmlListModel 2.0
import '../helpers'

Item {
    id: root

    property alias hostUrl: xlm.hostUrl
    readonly property alias items: sfm

    property string queryField: ''
    property string queryFilter: ''
    property string mediaType: 'audio'

    onMediaTypeChanged: {
        xlm.mcwsQuery = buildQuery()
    }

    onQueryFilterChanged: {
        if (queryFilter === '')
            return

        queryField = ''
        xlm.mcwsQuery = buildQuery()
    }

    onQueryFieldChanged: {
        if (queryField === '')
            return

        queryFilter = ''
        xlm.mcwsQuery = buildQuery()
    }

    function clear() {
        queryField = ''
        queryFilter = ''
        xlm.mcwsQuery = ''
    }

    function buildQuery() {
        xlm.queryType = 0
        var str = 'Library/Values?'
        if (queryField !== '') {
            str += 'Field=' + queryField.replace(/#/g, '%23')
        } else if (queryFilter !== '') {
            str += 'Filter=' + queryFilter
            xlm.queryType = 1
        } else {
            return ''
        }

        str += (mediaType !== '' ? '&Files=[Media Type]=[%1]'.arg(mediaType) : '')
        return str
    }

    function icon(field, val) {
        switch (field.toLowerCase()) {
        case 'name':      return 'view-media-track'
        case 'album artist':
        case 'composer':
        case 'artist':    return 'view-media-artist'
        case 'album':     return 'view-media-album-cover'
        case 'genre':     return 'view-media-genre'
        case 'comment':   return 'edit-comment'
        case 'file type': return 'audio-' + val.toLowerCase()
        case 'compression': return 'application-x-compress'
        case 'publisher': return 'view-media-publisher'
        case 'keywords':  return 'view-media-publisher'
        default:          return 'audio-x-generic'
        }

    }

    onHostUrlChanged: queryField = ''

    BaseSortFilterModel {
        id: sfm
        sourceModel: xlm
        sortRole: 'field'
    }

    // type: 0 = field query, 1 = filter query
    signal resultsReady(var type, var count)

    BaseXml {
        id: xlm
        XmlRole { name: "field"; query: "@Name/string()" }
        XmlRole { name: "value"; query: "string()" }

        property int queryType: 0
        onResultsReady: root.resultsReady(queryType, count)
    }
}
