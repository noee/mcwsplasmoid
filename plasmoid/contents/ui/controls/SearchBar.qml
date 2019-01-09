import QtQuick 2.8
import QtQuick.Layouts 1.3
import org.kde.plasma.components 3.0 as PlasmaComponents

RowLayout {
    spacing: 1

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


    Repeater {
        id: btns
        readonly property string letters: "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        model: letters.length
        delegate:PlasmaComponents.Button {
            text: btns.letters.slice(index,index+1)
            onClicked: scrollList(text)
            font.pointSize: theme.defaultFont.pointSize
            implicitWidth: font.pointSize + 5
        }
    }
}
