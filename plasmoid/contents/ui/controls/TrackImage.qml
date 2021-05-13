import QtQuick 2.15
import '../helpers'

Image {
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
