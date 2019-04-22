import QtQuick 2.8
import QtQuick.Controls 2.5

Button {
    checkable: true
    hoverEnabled: true

    ToolTip.visible: ToolTip.text && hovered
    ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
}
