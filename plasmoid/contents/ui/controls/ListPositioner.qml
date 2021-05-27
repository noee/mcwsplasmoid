import QtQuick 2.8
import QtQuick.Layouts 1.12
import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.plasma.components 3.0 as PComp
import '..'

Item {
    implicitWidth: rl.width
    implicitHeight: PlasmaCore.Units.iconSizes.medium

    property bool horizontalList: false
    property Viewer list

    RowLayout {
        id: rl
        spacing: 0

        PComp.ToolButton {
            icon.name: horizontalList ? 'go-first' : 'go-top'
            onClicked: if (list) list.positionViewAtBeginning()

            PComp.ToolTip {
                text: 'Beginning of list'
            }
        }

        PComp.ToolButton {
            icon.name: horizontalList ? 'go-last' : 'go-bottom'
            onClicked: if (list) list.positionViewAtEnd()

            PComp.ToolTip {
                text: 'End of list'
            }
        }
    }
}

