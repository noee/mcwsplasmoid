import QtQuick 2.2
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.0
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras

Item {

    property alias cfg_showTrackSlider: showTrackSlider.checked
    property alias cfg_showVolumeSlider: showVolSlider.checked
    property alias cfg_showTrackSplash: showTrackSplash.checked
    property alias cfg_animateTrackSplash: animateTrackSplash.checked
    property alias cfg_abbrevZoneView: abbrevZoneView.checked
    property alias cfg_abbrevTrackView: abbrevTrackView.checked
    property alias cfg_autoShuffle: autoShuffle.checked
    property alias cfg_advancedTrayView: advTrayView.checked
    property alias cfg_showStopButton: showStopButton.checked
    property alias cfg_useImageIndicator: imgIndicator.checked

    property int cfg_trayViewSize

    onCfg_trayViewSizeChanged: {
          switch (cfg_trayViewSize) {
          case 25:
              normalSize.checked = true;
              break;
          case 60:
              wideSize.checked = true;
              break;
          case 110:
              extraWideSize.checked = true;
              break;
          default:
          }
    }

    GroupBox {
        flat: true

        width: parent.width
        height: parent.height

        GridLayout {
            columns: 2
            anchors.left: parent.left
            anchors.leftMargin: units.largeSpacing

            Rectangle {
                height: 1
                Layout.columnSpan: 2
                Layout.fillWidth: true
            }
            PlasmaExtras.Heading {
                text: "Popup View"
                level: 4
                Layout.columnSpan: 2
            }
            CheckBox {
                id: showTrackSlider
                text: "Show Track Slider"
                Layout.topMargin: 10
            }
            CheckBox {
                id: showTrackSplash
                text: "Show Track Splash"
                Layout.topMargin: 10
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
            }
            CheckBox {
                id: abbrevTrackView
                text: "Abbreviated Track View"
            }
            Rectangle {
                height: 1
                Layout.columnSpan: 2
                Layout.fillWidth: true
                Layout.topMargin: 10
            }


            PlasmaExtras.Heading {
                text: "Advanced Panel View"
                level: 4
            }

            CheckBox {
                id: advTrayView
                Layout.alignment: Qt.AlignRight
                text: "Enable (only in horizontal panels)"
            }
            PlasmaComponents.ButtonRow {
                Layout.columnSpan: 2
                Layout.topMargin: 10
                PlasmaComponents.RadioButton {
                    id: normalSize
                    enabled: advTrayView.checked
                    text: "Normal"
                    onClicked: cfg_trayViewSize = 25
                }
                PlasmaComponents.RadioButton {
                    id: wideSize
                    enabled: advTrayView.checked
                    text: "Wide"
                    onClicked: cfg_trayViewSize = 60
                }
                PlasmaComponents.RadioButton {
                    id: extraWideSize
                    enabled: advTrayView.checked
                    text: "Ludicrous Wide"
                    onClicked: cfg_trayViewSize = 110
                }
            }
            CheckBox {
                id: showStopButton
                text: "Show Stop Button"
                enabled: advTrayView.checked
            }
            CheckBox {
                id: imgIndicator
                text: "Use Image as Playback Indicator"
                enabled: advTrayView.checked
            }

            Rectangle {
                height: 1
                Layout.columnSpan: 2
                Layout.fillWidth: true
                Layout.topMargin: 10
            }
            PlasmaExtras.Heading {
                text: "Playback Options"
                level: 4
                Layout.columnSpan: 2
            }
            CheckBox {
                id: autoShuffle
                text: "Shuffle when adding or playing"
                Layout.topMargin: 10
            }

        }
    }
}
