import QtQuick 2.5
import QtQuick.Layouts 1.12
import org.kde.plasma.core 2.1 as PlasmaCore

PlasmaCore.IconItem {
    id: root
    source: 'go-bottom'

    Layout.preferredWidth: PlasmaCore.Units.iconSizes.small
    Layout.preferredHeight: PlasmaCore.Units.iconSizes.small

    signal clicked()

    MouseAreaEx {
        tipText: 'Bottom'
        onClicked: root.clicked()
    }
}

