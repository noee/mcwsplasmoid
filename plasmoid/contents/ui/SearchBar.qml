import QtQuick 2.8
import QtQuick.Layouts 1.3
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras

RowLayout {
    readonly property string letters: "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    property var list
    property var modelItem

    function scrollList(val)
    {
        var model = list.model
        for (var i=0; i<model.count; ++i) {
            var srch = model.get(i)[modelItem]
            if (val === srch.slice(0,1)) {
                list.positionViewAtIndex(i, ListView.Center)
                list.currentIndex = i
                break
            }
        }
    }

    PlasmaComponents.ButtonRow {
        spacing: 0
        Repeater {
            model: letters.length
            delegate:
            PlasmaComponents.Button {
                text: letters.slice(index,index+1)
                onClicked: scrollList(text)
                width: units.gridUnit
                font {
                    pointSize: theme.defaultFont.pointSize - 2
                }
            }
        }
    }
}
