import QtQuick 2.8
import org.kde.plasma.components 2.0 as PlasmaComponents

PlasmaComponents.Label {
    id: txt
    property string aText
    property int duration: 500

    onATextChanged: event.singleShot(10, function(){ seq.start() })
    SequentialAnimation {
        id: seq
            NumberAnimation { target: txt; property: "opacity"; to: 0; duration: txt.duration }
            PropertyAction { target: txt; property: "text"; value: txt.aText }
            NumberAnimation { target: txt; property: "opacity"; to: 1; duration: txt.duration }
    }
}
