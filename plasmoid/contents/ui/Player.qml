import QtQuick 2.8
import QtQuick.Layouts 1.3
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
}
