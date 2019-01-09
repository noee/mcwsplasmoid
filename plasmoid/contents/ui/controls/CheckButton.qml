import QtQuick 2.8
import QtQuick.Controls 2.4

ToolButton {
    id: control
    checkable: true
    hoverEnabled: true

    ToolTip.visible: ToolTip.text && hovered
    ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval

    background: Rectangle {
        anchors.fill: parent
        color: Qt.darker(theme.highlightColor, control.enabled && (control.checked || control.highlighted) ? 1.5 : 1.0)
        opacity: enabled ? 1 : 0.3
        visible: control.down || (control.enabled && (control.checked || control.highlighted))
    }
}
