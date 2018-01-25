import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2 as QtControls
import org.kde.plasma.components 2.0 as PlasmaComponents
import "controls"

GridLayout {
    columns: 2
    rowSpacing: 0
    Layout.margins: units.smallSpacing
    Layout.preferredWidth: parent.width

    property bool showTrackSlider: false
    property bool showVolumeSlider: false
    // Config button
    PlasmaComponents.ToolButton {
        flat: false
        iconSource: "configure"
        onClicked: zoneMenu.showAt(this)
    }
    // playback controls
    RowLayout {
        spacing: 1

        PrevButton { Layout.leftMargin: 15 }
        PlayPauseButton {}
        StopButton {}
        NextButton {}

        // volume controls
        MuteButton { visible: showVolumeSlider }
        QtControls.Slider {
            id: control
            visible: showVolumeSlider
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
            visible: showVolumeSlider
            text: volumedisplay
        }
    }
    // track pos
    RowLayout {
        spacing: 1
        Layout.columnSpan: 2

        PlasmaComponents.Label {
            visible: showTrackSlider
            text: "Track " + playingnowpositiondisplay
        }

        QtControls.Slider {
            id: trackPos
            visible: showTrackSlider
            Layout.fillWidth: true
            from: 0
            to: durationms / 10000
            value: positionms / 10000
            onMoved: mcws.setPlayingPosition(index, value*10000)
            background: Rectangle {
                id: sliderRect
                x: trackPos.leftPadding
                y: trackPos.topPadding + trackPos.availableHeight / 2 - height / 2
                implicitWidth: 200
                implicitHeight: 4
                width: trackPos.availableWidth
                height: implicitHeight
                radius: 2

                Rectangle {
                    width: trackPos.visualPosition * parent.width
                    height: parent.height
                    color: "dark grey"
                    radius: 2
                }
            }
            handle: Rectangle {
                x: trackPos.leftPadding + trackPos.visualPosition * (trackPos.availableWidth - width)
                y: trackPos.topPadding + trackPos.availableHeight / 2 - height / 2
                implicitWidth: 15
                implicitHeight: 15
                radius: 13
                color: trackPos.pressed ? "#f0f0f0" : "#f6f6f6"
                border.color: "#bdbebf"
            }
        }
    }

}
