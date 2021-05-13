import QtQuick 2.15
import org.kde.kirigami 2.15 as Kirigami

TrackImage {

    property alias color: shadowRectangle.color
    property alias radius: shadowRectangle.radius
    property alias shadow: shadowRectangle.shadow
    property alias border: shadowRectangle.border
    property alias corners: shadowRectangle.corners
    property alias shadowSize: shadowRectangle.shadow.size
    property alias shadowColor: shadowRectangle.shadow.color

    Kirigami.ShadowedTexture {
        id: shadowRectangle
        anchors.fill: parent
        radius: 2
        color: 'transparent'
        shadow.xOffset: 1
        shadow.yOffset: 3
        shadow.color: Qt.rgba(0, 0, 0, 0.6)
        shadow.size: Kirigami.Units.largeSpacing
     }
}
