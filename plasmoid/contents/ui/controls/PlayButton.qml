import QtQuick 2.8
import QtQuick.Controls 2.5

Button {
    icon.name: "media-playback-start"
    ToolTip.text: 'Play Now'
    ToolTip.visible: hovered
    ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval

}
