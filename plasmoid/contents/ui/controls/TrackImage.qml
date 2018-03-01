import QtQuick 2.8
import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0

Item {
    width: height

    property bool animateLoad: false
    property string sourceKey: ''

    onSourceKeyChanged: {
        if (animateLoad)
            event.singleShot(0, seq.start)
        else
            img.source = mcws.imageUrl(sourceKey)
    }

    Image {
        id: img
        // Qt caches images based on source string, which is
        // different for every track as it's based on filekey.
        // So, if true, caching stores multiple copies of the same
        // image because filekey is different.
        cache: false

        sourceSize.height: parent.height
        sourceSize.width: parent.width
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 2
            verticalOffset: 2
            color: "#80000000"
        }

        SequentialAnimation {
            id: seq
            PropertyAnimation { target: img; property: "opacity"; to: 0; duration: 500 }
            PropertyAction { target: img; property: "source"; value: mcws.imageUrl(sourceKey) }
            PropertyAnimation { target: img; property: "opacity"; to: 1; duration: 500 }
        }

        onStatusChanged: {
            if (status === Image.Error) {
                source = 'default.png'
                mcws.setImageError(sourceKey)
            }
        }
    }
}
