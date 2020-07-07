import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.5
import org.kde.kirigami 2.8 as Kirigami

RowLayout {
    property bool showLabel: true
    property bool showSlider: true

    Label {
        visible: showSlider
        font.pointSize: Kirigami.Theme.defaultFont.pointSize - 2
        text: elapsedtimedisplay
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
                PropertyChanges { target: trackPos; value: positionms / 10000 }
            }
        ]

    }

    Label {
        visible: showSlider
        font.pointSize: Kirigami.Theme.defaultFont.pointSize - 2
        text: remainingtimedisplay
    }

    Label {
        visible: showLabel
        font.pointSize: Kirigami.Theme.defaultFont.pointSize - 2
        text: "[%1]".arg(playingnowpositiondisplay)
    }

    Timer {
        id: posTimer
        repeat: true
        interval: 100
        triggeredOnStart: true

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
