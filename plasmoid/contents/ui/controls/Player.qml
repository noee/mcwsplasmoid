import QtQuick 2.8
import QtQuick.Layouts 1.3

// playback controls for use in a delegate
RowLayout {
    spacing: 1
    property bool showVolumeSlider: true
    property bool showStopButton: true
    property bool showShuffle: true
    property bool showRepeat: true

    PrevButton {}
    PlayPauseButton {}
    StopButton { visible: showStopButton }
    NextButton {}
    VolumeControl { showSlider: showVolumeSlider }
    ShuffleButton { visible: showShuffle }
    RepeatButton { visible: showRepeat }
}
