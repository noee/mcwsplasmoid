import QtQuick 2.8
import QtQuick.Layouts 1.3
import org.kde.plasma.components 2.0 as PlasmaComponents

RowLayout {
    property var list
    property var modelItem
    property string currentSelection: ''

    function scrollList(val) {
        var i = list.model.findIndex(function(item) { return val === item[modelItem].slice(0,1) })
        if (i !== -1) {
            list.positionViewAtIndex(i, ListView.Center)
            list.currentIndex = i
            currentSelection = val
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
