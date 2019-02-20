import QtQuick 2.8
import QtQuick.Controls 2.4

Label {
    id: txt
    property string aText
    property int duration: 500
    property bool animate: true
    renderType: Text.NativeRendering
    color: theme.textColor

    onATextChanged: {
        if (animate)
            event.queueCall(seq.start)
        else
            text = aText
    }

    function fade() {
        seq.start()
    }

    SequentialAnimation {
        id: seq
        PropertyAnimation { target: txt; property: "opacity"; to: 0; duration: txt.duration }
        PropertyAction { target: txt; property: "text"; value: txt.aText }
        PropertyAnimation { target: txt; property: "opacity"; to: 1; duration: txt.duration }
    }
}
