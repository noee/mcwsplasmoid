import QtQuick 2.12
import QtQuick.Controls 2.2
import org.kde.kirigami 2.12 as Kirigami

Item {
    id: root
    implicitWidth: img.width
    implicitHeight: img.height

    property alias color: shadowRectangle.color
    property alias radius: shadowRectangle.radius
    property alias shadow: shadowRectangle.shadow
    property alias border: shadowRectangle.border
    property alias corners: shadowRectangle.corners

    property alias animateLoad: img.animateLoad
    property alias sourceKey: img.sourceKey
    property alias source: img.source
    property alias sourceUrl: img.sourceUrl
    property alias opacityTo: img.opacityTo
    property alias sourceSize: img.sourceSize
    property alias fillMode: img.fillMode
    property alias duration: img.duration
    property alias cache: img.cache
    property alias mipmap: img.mipmap
    property alias thumbnail: img.thumbnail

    signal statusChanged()
    signal imageError()

    TrackImage {
        id: img
        onStatusChanged: {
            if (img.status === Image.Error)
                root.imageError()
            root.statusChanged()
        }
    }

    Kirigami.ShadowedTexture {
         id: shadowRectangle
         anchors.fill: parent

         radius: 2
         color: 'transparent'
         shadow.xOffset: 1
         shadow.yOffset: 3
         shadow.color: Qt.rgba(0, 0, 0, 0.6)
         shadow.size: Kirigami.Units.largeSpacing

         source: img.status === Image.Ready ? img : null
     }}
