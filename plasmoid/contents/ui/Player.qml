import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.5
import "controls"

// playback controls
RowLayout {
    spacing: 3
    property bool showVolumeSlider: true
    property bool showStopButton: true

    PrevButton {}
    PlayPauseButton {}
    StopButton { visible: showStopButton }
    NextButton {}
    VolumeControl { showSlider: showVolumeSlider }
    Item { Layout.fillWidth: true}
    ToolButton {
        icon.name: 'configure'
        onClicked: zoneMenu.open(this)
    }
}
