import QtQuick 2.8
import QtQuick.Controls 2.4
import org.kde.plasma.components 3.0 as PlasmaComponents

PlasmaComponents.ToolButton {
    icon.name: "list-add"
    flat: true
    ToolTip.text: 'Add to Playing Now'
    ToolTip.visible: hovered
    ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
}
