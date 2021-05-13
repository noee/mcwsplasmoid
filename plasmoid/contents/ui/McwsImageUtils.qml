import QtQuick 2.15
import org.kde.kirigami 2.15 as Kirigami
import 'helpers'

// Interface helpers for error lookups and getter
QtObject {

    property string hostUrl
    property string thumbnailSize: 'Large'
    property var __imageErrorKeys: ({'-1': true})

    // required by TrackImage
    readonly property string defaultImage: 'default.png'

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
}

