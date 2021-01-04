import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.5
import org.kde.plasma.core 2.1 as PlasmaCore

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
        var i = list.model.findIndex(item => val === item[role].slice(0,1))
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
        delegate: CheckButton {
            text: btns.letters.slice(index,index+1)
            onClicked: scrollList(text)
            autoExclusive: true
            implicitWidth: PlasmaCore.Units.largeSpacing
        }
    }
}
