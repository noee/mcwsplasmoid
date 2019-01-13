import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.4
import org.kde.plasma.components 3.0 as PC

RowLayout {
    property bool showButton: true
    property bool showSlider: true
    property bool showLabel: true

    PC.ToolButton {
        icon.name: mute ? "player-volume-muted" : "player-volume"
        visible: showButton
        onClicked: player.setMute(!mute)
    }
    Slider {
        id: control
        visible: showSlider
        padding: 0
        stepSize: 1
        from: 0
        to: 100
        value: volume * 100
        onMoved: player.setVolume(value/100)
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
    Label {
        text: volumedisplay
        visible: showLabel
    }
}
