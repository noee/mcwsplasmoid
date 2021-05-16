import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.5

RowLayout {
    spacing: 1
    property bool showButton: true
    property bool showSlider: true
    property bool showLabel: true

    ToolButton {
        icon.name: mute ? "volume-level-muted" : "volume-level-high"
        visible: showButton
        flat: true
        onClicked: player.setMute(!mute)
        checkable: true
        checked: mute

        ToolTip.text: mute ?  'Volume is muted' : 'Mute'
        ToolTip.visible: hovered
        ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
    }

    Slider {
        id: control
        visible: showSlider
        padding: 0
        value: volume
        Layout.fillWidth: true

        onMoved: player.setVolume(value)

        ToolTip {
            visible: showLabel && control.pressed
            text: Math.round(control.value*100) + '%'
            delay: 0
        }
    }
}

