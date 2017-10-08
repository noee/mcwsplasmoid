import QtQuick 2.8
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.0

RowLayout {
    readonly property string letters: "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    property var model
    property var list

    function scrollList(link) {
        var val = link.split("//")[1]
        for (var i=0; i<model.count; ++i) {
            var srch = model.get(i).value
            if (val === srch.slice(0,1)) {
                list.positionViewAtIndex(i, ListView.Visible)
                break
            }
        }
    }
    Layout.margins: 5
    Repeater {
        model: letters.length
        delegate: Text {
            text: "<a href=\"cmd://" + letters.slice(index,index+1) + "\">" + letters.slice(index,index+1) + "</a>"
            onLinkActivated: scrollList(link)
        }
    }
}
