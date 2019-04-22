import QtQuick 2.8
import QtQuick.Controls 2.5

CheckButton {
    icon.name: 'search'
    ToolTip.text: 'Show Details'
    ToolTip.visible: hovered
    ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
}
