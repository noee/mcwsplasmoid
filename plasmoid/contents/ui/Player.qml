import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.5
import "controls"

// playback controls
RowLayout {
    spacing: 3
    property bool showVolumeSlider: true
    property bool showStopButton: true

    ToolButton {
        icon.name: 'configure'
        onClicked: zoneMenu.open(this)
    }
    Item { Layout.fillWidth: true }
    PrevButton {}
    PlayPauseButton {}
    StopButton { visible: showStopButton }
    NextButton {}
    Item { Layout.fillWidth: true }
    VolumeControl { showSlider: showVolumeSlider }
}
