import QtQuick 2.8
import QtQuick.Controls 2.5

ToolButton {
    icon.name: 'search'
    checkable: true
    ToolTip.text: 'Show Details'
    ToolTip.visible: hovered
    ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
}
