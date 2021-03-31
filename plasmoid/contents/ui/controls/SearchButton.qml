import QtQuick 2.12
import QtQuick.Controls 2.12

ToolButton {
    icon.name: 'search'
    checkable: true
    ToolTip.text: 'Show Details'
    ToolTip.visible: hovered
    ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
}
