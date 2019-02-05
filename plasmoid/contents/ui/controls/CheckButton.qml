import QtQuick 2.8
import QtQuick.Controls 2.4

Button {
    id: control
    checkable: true
    hoverEnabled: true

    ToolTip.visible: ToolTip.text && hovered
    ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
}
