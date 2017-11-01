import QtQuick 2.8

Text {
    id: txt
    property string aText
    property int duration: 500

    color: theme.textColor

    onATextChanged: event.singleShot(0, function(){ seq.start() })
    SequentialAnimation {
        id: seq
            NumberAnimation { target: txt; property: "opacity"; to: 0; duration: txt.duration }
            PropertyAction { target: txt; property: "text"; value: txt.aText }
            NumberAnimation { target: txt; property: "opacity"; to: 1; duration: txt.duration }
    }
}
