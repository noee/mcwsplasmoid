import QtQuick 2.8
import QtQuick.Layouts 1.12
import org.kde.plasma.core 2.0 as PC

// playback controls for use in a delegate
Item {
    implicitHeight: rl.height

    property bool showVolumeSlider: true
    property bool showStopButton: true
    property bool showShuffle: true
    property bool showRepeat: true

    RowLayout {
        id: rl
        spacing: 3

        PrevButton {}

        PlayPauseButton {
            icon.width: PC.Units.iconSizes.medium
            icon.height: PC.Units.iconSizes.medium
        }

        StopButton {
            visible: showStopButton
            icon.width: PC.Units.iconSizes.medium
            icon.height: PC.Units.iconSizes.medium
        }

        NextButton {}

        VolumeControl {
            showSlider: showVolumeSlider
        }
    }
}

