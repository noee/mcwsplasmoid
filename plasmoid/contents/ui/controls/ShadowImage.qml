import QtQuick 2.8
import QtQuick.Controls 2.2
import org.kde.kirigami 2.12 as Kirigami

Kirigami.ShadowedRectangle {
    implicitWidth: img.width
    implicitHeight: img.height
    radius: 2
    color: 'transparent' // Kirigami.Theme.backgroundColor
//        property color borderColor: Kirigami.Theme.textColor
//        border.color: Qt.rgba(borderColor.r, borderColor.g, borderColor.b, 0.3)
//        border.width: 1
    shadow.xOffset: 0
    shadow.yOffset: 4
    shadow.color: Qt.rgba(0, 0, 0, 0.6)
    shadow.size: 8

    property alias animateLoad: img.animateLoad
    property alias sourceKey: img.sourceKey
    property alias sourceUrl: img.sourceUrl
    property alias opacityTo: img.opacityTo
    property alias sourceSize: img.sourceSize
    property alias fillMode: img.fillMode

    TrackImage { id: img }
}
