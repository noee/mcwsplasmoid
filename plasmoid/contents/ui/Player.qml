import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.4
import org.kde.plasma.components 3.0 as PC
import "controls"

ColumnLayout {
    spacing: 1
    Layout.margins: units.smallSpacing
    Layout.preferredWidth: parent.width

    property bool showTrackSlider: true
    property bool showVolumeSlider: true
    property bool showStopButton: true
    // playback controls
    RowLayout {
        spacing: 1

        PC.ToolButton {
            icon.name: 'configure'
            onClicked: zoneMenu.open(this)
        }

        PrevButton { Layout.leftMargin: 15 }
        PlayPauseButton {}
        StopButton { visible: showStopButton }
        NextButton {}
        VolumeControl { showSlider: showVolumeSlider }
    }
    // track pos
    TrackPosControl {
        showSlider: showTrackSlider
        showLabel: showTrackSlider
    }
}
