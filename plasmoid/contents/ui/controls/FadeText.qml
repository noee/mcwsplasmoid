import QtQuick 2.8

Text {
    id: txt
    property string aText
    property int duration: 500

    color: theme.textColor

    onATextChanged: Qt.callLater(function(){ seq.start() })

    SequentialAnimation on opacity {
        id: seq
        PropertyAnimation { to: 0; duration: txt.duration }
        PropertyAction { target: txt; property: "text"; value: txt.aText }
        PropertyAnimation { to: 1; duration: txt.duration }
    }
}
