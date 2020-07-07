import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.5
import org.kde.kirigami 2.8 as Kirigami

RowLayout {
    property bool showButton: true
    property bool showSlider: true
    property bool showLabel: true
    spacing: 1

    CheckButton {
        icon.name: mute ? "player-volume-muted" : "player-volume"
        visible: showButton
        flat: true
        onClicked: player.setMute(!mute)
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
