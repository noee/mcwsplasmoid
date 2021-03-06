import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.12
import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.plasma.components 3.0 as PComp

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
        delegate: PComp.ToolButton {
            text: btns.letters.slice(index,index+1)
            onClicked: scrollList(text)
            checkable: true
            autoExclusive: true
            height: PlasmaCore.Units.smallSpacing
            width:  PlasmaCore.Units.smallSpacing
        }
    }
}
