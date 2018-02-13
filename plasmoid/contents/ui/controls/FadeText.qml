import QtQuick 2.8

Text {
    id: txt
    property string aText
    property int duration: 500

    color: theme.textColor

    onATextChanged: Qt.callLater(seq.start)

    SequentialAnimation {
        id: seq
        PropertyAnimation { target: txt; property: "opacity"; to: 0; duration: txt.duration }
        PropertyAction { target: txt; property: "text"; value: txt.aText }
        PropertyAnimation { target: txt; property: "opacity"; to: 1; duration: txt.duration }
    }
}
