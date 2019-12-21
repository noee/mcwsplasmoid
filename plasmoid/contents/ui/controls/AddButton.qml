import QtQuick 2.8
import QtQuick.Controls 2.5

Button {
    icon.name: 'media-playlist-append'
    ToolTip.text: 'Add to Playing Now'
    ToolTip.visible: hovered
    ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
}
