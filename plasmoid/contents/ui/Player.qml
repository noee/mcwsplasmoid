import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2
import org.kde.plasma.components 2.0 as PlasmaComponents

ColumnLayout {
    spacing: 1
    Layout.margins: units.smallSpacing
    property bool showTrackSlider: false
    property bool showVolumeSlider: false
    // commands
    RowLayout {
        Layout.topMargin: 0
        spacing: 1
        // Config button
        PlasmaComponents.ToolButton {
            flat: false
            iconSource: "configure"
            onClicked: zoneMenu.showAt(this)
        }
        // prev track
        PlasmaComponents.ToolButton {
            iconSource: "media-skip-backward"
            flat: false
            enabled: playingnowposition !== "0"
            Layout.leftMargin: 15
            onClicked: pn.previous(lv.currentIndex)
        }
        // play/pause
        PlasmaComponents.ToolButton {
            iconSource: model.status === "Playing" ? "media-playback-pause" : "media-playback-start"
            flat: false
            onClicked: pn.play(lv.currentIndex)
        }
        // stop
        PlasmaComponents.ToolButton {
            iconSource: "media-playback-stop"
            flat: false
            onClicked: pn.stop(lv.currentIndex)
        }
        // next track
        PlasmaComponents.ToolButton {
            iconSource: "media-skip-forward"
            enabled: nextfilekey !== "-1"
            flat: false
            onClicked: pn.next(lv.currentIndex)
        }
        // volume
        PlasmaComponents.ToolButton {
            id: volButton
            visible: showVolumeSlider
            iconSource: mute ? "player-volume-muted" : "player-volume"
            flat: false
            onClicked: pn.toggleMute(lv.currentIndex)
        }
        Slider {
            id: control
            visible: showVolumeSlider
            padding: 0
            stepSize: 1
            from: 0
            to: 100
            value: volume * 100
            onMoved: pn.setVolume(value/100, lv.currentIndex)

            background: Rectangle {
                x: control.leftPadding
                y: control.topPadding + control.availableHeight / 2 - height / 2
                implicitWidth: 100
                implicitHeight: 4
                width: control.availableWidth
                height: implicitHeight
                radius: 2
                color: "#bdbebf"

                Rectangle {
                    width: control.visualPosition * parent.width
                    height: parent.height
                    color: "#0081c2"
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
        Text {
            visible: showVolumeSlider
            color: listTextColor
            font: defaultFont
            text: volumedisplay
        }
    }
    // track
    RowLayout {
        Layout.topMargin: 0
        Layout.alignment: Qt.AlignRight
        spacing: 1

        Text {
            visible: showTrackSlider
            color: listTextColor
            font: defaultFont
            text: "Track " + playingnowpositiondisplay
        }

        Slider {
            id: trackPos
            visible: showTrackSlider
            from: 0
            to: durationms / 10000
            value: positionms / 10000
            onMoved: pn.setPlayingPosition(value*10000, lv.currentIndex)
            background: Rectangle {
                id: sliderRect
                x: trackPos.leftPadding
                y: trackPos.topPadding + trackPos.availableHeight / 2 - height / 2
                implicitWidth: 200
                implicitHeight: 4
                width: trackPos.availableWidth
                height: implicitHeight
                radius: 2
                color: "#bdbebf"

                Rectangle {
                    width: trackPos.visualPosition * parent.width
                    height: parent.height
                    color: "#0081c2" //"#21be2b"
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
