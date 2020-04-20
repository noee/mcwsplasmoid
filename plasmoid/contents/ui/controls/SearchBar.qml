import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.5
import org.kde.kirigami 2.8 as Kirigami

RowLayout {
    spacing: 0

    property ListView list
    property string role: ''
    property string currentSelection: ''

    function reset() {
        currentSelection = ''
        list.positionViewAtBeginning()
    }

    function scrollList(val) {
        var i = list.model.findIndex((item) => { return val === item[role].slice(0,1) })
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
            font.pointSize: Kirigami.Theme.defaultFont.pointSize
            implicitWidth: font.pointSize + 5
        }
    }
}
