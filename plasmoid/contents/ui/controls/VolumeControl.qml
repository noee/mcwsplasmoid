import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2 as QtControls
import org.kde.plasma.components 2.0 as PlasmaComponents

RowLayout {
    property bool showButton: true
    property bool showSlider: true
    property bool showLabel: true

    PlasmaComponents.ToolButton {
        iconSource: mute ? "player-volume-muted" : "player-volume"
        flat: false
        visible: showButton
        onClicked: mcws.setMute(index, !mute)
    }
    QtControls.Slider {
        id: control
        visible: showSlider
        padding: 0
        stepSize: 1
        from: 0
        to: 100
        value: volume * 100
        onMoved: mcws.setVolume(index, value/100)
        background: Rectangle {
            x: control.leftPadding
            y: control.topPadding + control.availableHeight / 2 - height / 2
            implicitWidth: 100
            implicitHeight: 4
            width: control.availableWidth
            height: implicitHeight
            radius: 2

            Rectangle {
                width: control.visualPosition * parent.width
                height: parent.height
                color: "dark grey"
                radius: 2
            }
        }
        handle: Rectangle {
            x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
            y: control.topPadding + control.availableHeight / 2 - height / 2
            implicitWidth: 15
            implicitHeight: 15
            radius: 13
            color: control.pressed ? "#f0f0f0" : "#f6f6f6"
            border.color: "#bdbebf"
        }
    }
    PlasmaComponents.Label {
        text: volumedisplay
        visible: showLabel
    }
}
