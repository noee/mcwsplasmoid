import QtQuick 2.8
import QtQuick.Layouts 1.3
import org.kde.plasma.components 2.0 as PlasmaComponents

RowLayout {
    property var list
    property var modelItem
    property string currentSelection: ''

    function scrollList(val) {
        var model = list.model
        for (var i=0, len=model.count; i<len; ++i) {
            if (val === model.get(i)[modelItem].slice(0,1)) {
                list.positionViewAtIndex(i, ListView.Center)
                list.currentIndex = i
                currentSelection = val
                break
            }
        }
    }
    function scrollCurrent() {
        if (currentSelection !== '')
            scrollList(currentSelection)
    }

    PlasmaComponents.ButtonRow {
        id: br
        spacing: 0
        readonly property string letters: "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

        Repeater {
            model: br.letters.length
            delegate:
            PlasmaComponents.Button {
                text: br.letters.slice(index,index+1)
                onClicked: scrollList(text)
                width: units.gridUnit
                font {
                    pointSize: theme.defaultFont.pointSize - 2
                }
            }
        }
    }
}
