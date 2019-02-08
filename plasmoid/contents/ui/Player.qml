import QtQuick 2.8
import QtQuick.Layouts 1.3
import org.kde.plasma.components 3.0 as PC
import "controls"

// playback controls
RowLayout {
    property bool showVolumeSlider: true
    property bool showStopButton: true

    spacing: 0

    PC.ToolButton {
        icon.name: 'configure'
        onClicked: zoneMenu.open(this)
    }
    PrevButton {}
    PlayPauseButton {}
    StopButton { visible: showStopButton }
    NextButton {}
    VolumeControl { showSlider: showVolumeSlider }
}
