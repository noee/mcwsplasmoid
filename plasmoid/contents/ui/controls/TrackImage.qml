import QtQuick 2.8

Image {
    id: img

    property bool animateLoad: true
    property string sourceKey: ''
    property string sourceUrl: ''
    property real opacityTo: 1.0

    onSourceKeyChanged: {
        if (animateLoad)
            Qt.callLater(seq.start)
        else {
            img.source = mcws.imageUrl(sourceKey, sourceSize.height)
        }
    }
    onSourceUrlChanged: {
        if (animateLoad)
            Qt.callLater(seq2.start)
        else {
            img.source = sourceUrl
        }
    }

    SequentialAnimation {
        id: seq
        PropertyAnimation { target: img; property: "opacity"; to: 0; duration: 500 }
        PropertyAction { target: img; property: "source"; value: mcws.imageUrl(sourceKey, sourceSize.height) }
        PropertyAnimation { target: img; property: "opacity"; to: opacityTo; duration: 500 }
    }
    SequentialAnimation {
        id: seq2
        PropertyAnimation { target: img; property: "opacity"; to: 0; duration: 500 }
        PropertyAction { target: img; property: "source"; value: sourceUrl }
        PropertyAnimation { target: img; property: "opacity"; to: opacityTo; duration: 500 }
    }

    onStatusChanged: {
        if (status === Image.Error) {
            source = 'default.png'
            mcws.setImageError(sourceKey)
        }
    }
}
