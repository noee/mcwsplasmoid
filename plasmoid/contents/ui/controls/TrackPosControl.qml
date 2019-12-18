import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.3
import org.kde.kirigami 2.4 as Kirigami

RowLayout {
    property bool showLabel: true
    property bool showSlider: true

    Label {
        visible: showLabel
        font.pointSize: theme.defaultFont.pointSize - 2
        text: "Track " + playingnowpositiondisplay
    }

    Slider {
        id: trackPos
        visible: showSlider
        from: 0
        to: durationms / 10000
        value: positionms / 10000
        Layout.fillWidth: true

        onMoved: {
            if (!posTimer.running) {
                posTimer.start()
                trackPos.state = 'moving'
            }
            posTimer.val = position*to*10000
        }

        states: [
            State {
                name: 'moving'
                PropertyChanges { target: trackPos; value: -1 }
            }
        ]

        background: Rectangle {
            x: trackPos.leftPadding
            y: trackPos.topPadding + trackPos.availableHeight / 2 - height / 2
            implicitWidth: trackPos.availableWidth
            implicitHeight: Kirigami.Units.iconSizes.small/3
            radius: 2
            Rectangle {
                width: trackPos.visualPosition * parent.width
                height: parent.height
                color: Kirigami.Theme.backgroundColor
                radius: 2
            }
        }
    }

    Timer {
        id: posTimer
        repeat: true
        interval: 100

        property int val

        onTriggered: {
            if (!trackPos.pressed) {
                stop()
                player.setPlayingPosition(val)
                event.queueCall(500, () => { trackPos.state = '' })
            }
        }
    }
}
