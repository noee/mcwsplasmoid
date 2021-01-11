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

    onSourceKeyChanged: {
        if (sourceKey === undefined || sourceKey.length === 0) {
            sourceKey = '-1'
            return
        }

        if (animateLoad)
            Qt.callLater(seq.start)
        else
            img.source = mcws.imageUrl({filekey: img.sourceKey
                                       , thumbnail: img.thumbnail
                                       , size: { width: img.sourceSize.width
                                                , height: img.sourceSize.height }
                                       })
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
            value: mcws.imageUrl({filekey: img.sourceKey
                                     , thumbnail: img.thumbnail
                                     , size: { width: img.sourceSize.width
                                              , height: img.sourceSize.height }
                                     })
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
        if (status === Image.Error)
            source = mcws.setImageError(sourceKey)
    }

}
