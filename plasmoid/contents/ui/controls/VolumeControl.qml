import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.5
import org.kde.kirigami 2.4 as Kirigami

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
        stepSize: 0.01
        value: volume
        onMoved: player.setVolume(value)

        Layout.fillWidth: true

        ToolTip {
            parent: control
            visible: showLabel && control.pressed
            text: Math.round(control.value*100) + '%'
            delay: 0
        }
        background: Rectangle {
            x: control.leftPadding
            y: control.topPadding + control.availableHeight / 2 - height / 2
            implicitWidth: control.availableWidth
            implicitHeight: Kirigami.Units.iconSizes.small/3
            radius: 2
            Rectangle {
                width: control.visualPosition * parent.width
                height: parent.height
                color: Kirigami.Theme.backgroundColor
                radius: 2
            }
        }
        handle: Rectangle {
            x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
            y: control.topPadding + control.availableHeight / 2 - height / 2
            implicitWidth: Kirigami.Units.iconSizes.small
            implicitHeight: implicitWidth
            radius: 13
            color: control.pressed ? Kirigami.Theme.backgroundColor : "#f6f6f6"
            border.color: Kirigami.Theme.backgroundColor
        }
    }
}
