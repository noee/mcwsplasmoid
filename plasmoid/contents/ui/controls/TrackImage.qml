import QtQuick 2.8
/**
* Image with animation option on opacity
* If animated, when sourceKey changes
* Ani opacity to 0, when that finishes, set the source
* then ani opacity back to opacityTo
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
            fadeOutIn.start()
        else
            __setSource()
    }

    signal animationStart()
    signal animationEnd()

    // Seq ani guarantees the image "reappears", however,
    // there can be a delay in image loading from mcws.
    // So, pause the ani a bit before fade in.
    SequentialAnimation {
        id: fadeOutIn

        OpacityAnimator {
            target: img
            from: opacityTo; to: 0
            duration: img.duration
        }

        ScriptAction { script: __setSource() }

        PauseAnimation { duration: 100 }

        OpacityAnimator {
            target: img
            from: 0; to: opacityTo
            duration: img.duration
        }

        onStarted: animationStart()
        onStopped: animationEnd()
    }

    onStatusChanged: {
        if (status === Image.Error) {
            imageErrorKeys[sourceKey] = true
            source = defaultImage
        }
    }

}
