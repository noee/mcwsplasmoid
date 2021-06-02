import QtQuick 2.8
import QtQuick.Layouts 1.12
import org.kde.plasma.core 2.0 as PC

// playback controls for use in a delegate
Item {
    id: root
    implicitHeight: rl.height

    property bool showVolumeSlider: true
    property bool showStopButton: true

    RowLayout {
        id: rl
        width: root.width
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

        Item {id: spacer; visible: showVolumeSlider; Layout.fillWidth: true }

        VolumeControl {
            Layout.fillWidth: true
            showSlider: showVolumeSlider
        }
    }
}

