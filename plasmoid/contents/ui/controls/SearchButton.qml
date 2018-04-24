import QtQuick 2.8
import QtQuick.Controls 2.3
import org.kde.plasma.components 2.0 as PlasmaComponents

PlasmaComponents.ToolButton {
    iconSource: 'search'
    flat: true
    ToolTip.text: 'Show Details'
    ToolTip.visible: hovered
    ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
}
