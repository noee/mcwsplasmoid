import QtQuick 2.8
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import org.kde.plasma.core 2.1 as PlasmaCore
import '..'

Item {
    implicitWidth: rl.width
    implicitHeight: PlasmaCore.Units.iconSizes.medium

    property bool horizontalList: false
    property Viewer list

    RowLayout {
        id: rl
        spacing: 0

        ToolButton {
            icon.name: horizontalList ? 'go-first' : 'go-top'
            onClicked: if (list) list.positionViewAtBeginning()

            ToolTip {
                text: 'Beginning of list'
            }
        }

        ToolButton {
            icon.name: horizontalList ? 'go-last' : 'go-bottom'
            onClicked: if (list) list.positionViewAtEnd()

            ToolTip {
                text: 'End of list'
            }
        }
    }
}

