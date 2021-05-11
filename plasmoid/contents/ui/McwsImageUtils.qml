import QtQuick 2.15
import org.kde.kirigami 2.15 as Kirigami
import 'helpers'

QtObject {
    // Interface helpers for error lookups and getter
    property string hostUrl
    property string thumbnailSize: 'Large'
    property var __imageErrorKeys: ({'-1': true})

    // required by TrackImage
    readonly property string defaultImage: 'controls/default.png'

    readonly property string imgQuery: hostUrl + 'File/GetImage?file=%1&%2'
    readonly property string imgFull: 'Type=Full'
    readonly property string imgThumb: 'ThumbnailSize=' + thumbnailSize

    onHostUrlChanged: clearErrorKeys()

    function clearErrorKeys() {
        __imageErrorKeys = {'-1': true}
    }

    // required by TrackImage
    function setImageError(key) {
        __imageErrorKeys[key] = true
    }

    // required by TrackImage
    function getImageUrl(key, thumbnail) {
        return !__imageErrorKeys[key]
                ? imgQuery.arg(key).arg(thumbnail ? imgThumb : imgFull)
                : defaultImage

    }

    component TrackImage: Image {
        id: ti

        property bool animateLoad: true
        property string sourceKey: ''
        property int duration: 750
        property bool thumbnail: false

        // Interface helper component
        property var imageUtils

        fillMode: Image.PreserveAspectFit
        mipmap: true

        onSourceKeyChanged: {
            // Guard the sourceKey
            if (sourceKey === undefined
                    || sourceKey.length === 0
                    || sourceKey === '-1') {
                ti.source = imageUtils.defaultImage
            } else {
                ti.source = imageUtils.getImageUrl(sourceKey, thumbnail)
            }
        }

        signal animationStart()
        signal animationEnd()

        FadeBehavior on sourceKey {
            enabled: ti.animateLoad
            fadeDuration: ti.duration
            onAnimationStart: ti.animationStart()
            onAnimationEnd: ti.animationEnd()
        }

        onStatusChanged: {
            if (status === Image.Error) {
                if (typeof imageUtils.setImageError === 'function')
                    imageUtils.setImageError(sourceKey)
                source = imageUtils.defaultImage
            }
        }

    }

    component ShadowImage: TrackImage {

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
}

