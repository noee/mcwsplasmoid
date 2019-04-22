import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.5

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
        delegate:ToolButton {
            text: btns.letters.slice(index,index+1)
            onClicked: scrollList(text)
            font.pointSize: theme.defaultFont.pointSize
            implicitWidth: font.pointSize + 5
        }
    }
}
