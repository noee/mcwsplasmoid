import QtQuick 2.2
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.0

Item {

    property alias cfg_showTrackSlider: showTrackSlider.checked
    property alias cfg_showVolumeSlider: showVolSlider.checked
    property alias cfg_showTrackSplash: showTrackSplash.checked
    property alias cfg_animateTrackSplash: animateTrackSplash.checked
    property alias cfg_abbrevZoneView: abbrevZoneView.checked
    property alias cfg_autoShuffle: autoShuffle.checked

    GroupBox {
        flat: true

        width: parent.width
        height: parent.height

        GridLayout {
            columns: 2
            anchors.left: parent.left
            anchors.leftMargin: units.largeSpacing

            CheckBox {
                id: showTrackSlider
                text: "Show Track Slider"
            }
            CheckBox {
                id: showTrackSplash
                text: "Show Track Splash"
            }
            CheckBox {
                id: showVolSlider
                text: "Show Volume Slider"
            }
            CheckBox {
                id: animateTrackSplash
                text: "Animate Track Splash"
            }

            CheckBox {
                id: abbrevZoneView
                text: "Abbreviated Zone View"
                Layout.columnSpan: 2
            }
            Label{Layout.columnSpan: 2}
            Rectangle {
                height: 3
                Layout.columnSpan: 2
                Layout.fillWidth: true
            }
            Label{Layout.columnSpan: 2}
            CheckBox {
                id: autoShuffle
                text: "Shuffle when adding or playing"
                Layout.columnSpan: 2
            }

        }
    }
}
