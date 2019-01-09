import QtQuick 2.8
import QtQuick.Controls 2.4
import org.kde.plasma.components 3.0 as PlasmaComponents

PlasmaComponents.ToolButton {
    icon.name: "media-playback-start"
    flat: true
    ToolTip.text: 'Play Now'
    ToolTip.visible: hovered
    ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
}
