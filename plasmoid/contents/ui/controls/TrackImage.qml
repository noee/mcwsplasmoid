import QtQuick 2.8
/**
* Image with animation option on opacity
* If animated, when sourceKey changes
* Start opacity to 0, when that finishes, set the source
* On image ready, if animateLoad, Start opacity back to 1
*/
Image {
    id: img

    mipmap: true

    property bool animateLoad: true
    property bool thumbnail: true
    property string sourceKey: ''
    property real opacityTo: 1.0
    property int duration: 500

    // mcws command to retrieve image
    property string __imageQuery: {
        mcws.isConnected
        ?   mcws.comms.hostUrl + 'File/GetImage?'
            + (thumbnail
                ? 'ThumbnailSize=' + (plasmoid.configuration.highQualityThumbs ? 'Large' : 'Small')
                : 'Type=Full')
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
                        ? __imageQuery + '&file=' + sourceKey
                        : defaultImage
    }

    onSourceKeyChanged: {
        if (animateLoad)
            opOff.start()
        else
            __setSource()
    }

    signal animationStart()
    signal animationEnd()

    OpacityAnimator {
        id: opOff
        target: img
        from: opacityTo; to: 0
        duration: img.duration
        onStarted: animationStart()
        onStopped: __setSource()
    }
    OpacityAnimator {
        id: opOn
        target: img
        from: 0; to: opacityTo
        duration: img.duration
        onStopped: animationEnd()
    }

    onStatusChanged: {
        if (status === Image.Ready) {
            if (animateLoad) {
                opOn.start()
            }
        } else if (status === Image.Error) {
            imageErrorKeys[sourceKey] = true
            source = defaultImage
        }
    }

}
