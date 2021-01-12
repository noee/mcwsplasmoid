import QtQuick 2.8

Image {
    id: img

    mipmap: true

    property bool animateLoad: true
    property bool thumbnail: true
    property string sourceKey: ''
    property string sourceUrl: ''
    property real opacityTo: 1.0
    property int duration: 500

    // mcws command to retrieve image
    property string __imageQuery: {
        mcws.isConnected
        ?   mcws.comms.hostUrl + 'File/GetImage?'
            + (thumbnail
                ? 'ThumbnailSize=' + (plasmoid.configuration.highQualityThumbs ? 'Large' : 'Small')
                : 'Type=Full')
            + '&file=' + sourceKey
        :   ''
    }

    function __setSource() {
        // Guard the sourceKey
        if (sourceKey === undefined
                || sourceKey.length === 0
                || sourceKey === '-1') {
            img.source = defaultImage
        }
        else
            img.source = !imageErrorKeys[sourceKey]
                        ? __imageQuery
                        : defaultImage
    }

    onSourceKeyChanged: {
        if (animateLoad)
            Qt.callLater(seq.start)
        else
            __setSource()
    }

    onSourceUrlChanged: {
        if (animateLoad)
            Qt.callLater(seq2.start)
        else
            img.source = sourceUrl
    }

    SequentialAnimation {
        id: seq
        PropertyAnimation { target: img; property: "opacity"; to: 0; duration: img.duration }
        PropertyAction {
            target: img
            property: "source"
            value: __setSource()
        }
        PropertyAnimation { target: img; property: "opacity"; to: opacityTo; duration: img.duration }
    }

    SequentialAnimation {
        id: seq2
        PropertyAnimation { target: img; property: "opacity"; to: 0; duration: img.duration }
        PropertyAction { target: img; property: "source"; value: sourceUrl }
        PropertyAnimation { target: img; property: "opacity"; to: opacityTo; duration: img.duration }
    }

    onStatusChanged: {
        if (status === Image.Error) {
            imageErrorKeys[sourceKey] = true
            source = defaultImage
        }
    }

}
