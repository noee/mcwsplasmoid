import QtQuick 2.8
import QtQuick.Controls 2.3
import org.kde.plasma.components 2.0 as PlasmaComponents

PlasmaComponents.ToolButton {
    iconSource: "media-playback-start"
    flat: true
    ToolTip.text: 'Play Now'
    ToolTip.visible: hovered
    ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
}
