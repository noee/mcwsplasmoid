import QtQuick 2.8
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras

Item {

    property alias cfg_showTrackSlider: showTrackSlider.checked
    property alias cfg_showVolumeSlider: showVolSlider.checked
    property alias cfg_showTrackSplash: showTrackSplash.checked
    property alias cfg_animateTrackSplash: animateTrackSplash.checked
    property alias cfg_abbrevZoneView: abbrevZoneView.checked
    property alias cfg_abbrevTrackView: abbrevTrackView.checked
    property alias cfg_advancedTrayView: advTrayView.checked
    property alias cfg_showStopButton: showStopButton.checked
    property alias cfg_useImageIndicator: imgIndicator.checked
    property alias cfg_dropShadows: dropShadows.checked

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

    ColumnLayout {

        GroupBox {
            label: PlasmaComponents.CheckBox {
                id: advTrayView
                text: "Advanced Panel View (only in horizontal panels)"
            }
            Layout.fillWidth: true
            Layout.topMargin: 10

            GridLayout {
                columns: 2
                enabled: advTrayView.checked
                PlasmaComponents.ButtonRow {
                    Layout.columnSpan: 2
                    Layout.topMargin: 10
                    PlasmaComponents.RadioButton {
                        id: normalSize
                        text: "One-item View"
                        onClicked: cfg_trayViewSize = 25
                    }
                    PlasmaComponents.RadioButton {
                        id: wideSize
                        text: "Wide View"
                        onClicked: cfg_trayViewSize = 60
                    }
                    PlasmaComponents.RadioButton {
                        id: extraWideSize
                        text: "Ludicrous Wide"
                        onClicked: cfg_trayViewSize = 110
                    }
                }

                PlasmaComponents.CheckBox {
                    id: dropShadows
                    text: "Drop Shadows"
                }
                PlasmaComponents.CheckBox {
                    id: showStopButton
                    text: "Show Stop Button"
                }
                PlasmaComponents.CheckBox {
                    id: imgIndicator
                    text: "Use Image as Playback Indicator"
                }
            }
        }
        GroupBox {
            label: PlasmaExtras.Heading {
                level: 4
                text: "Popup View Options"
            }
            Layout.topMargin: 10
            Layout.fillWidth: true
            GridLayout {
                columns: 2

                PlasmaComponents.CheckBox {
                    id: showTrackSlider
                    text: "Show Track Slider"
                    Layout.topMargin: 10
                }
                PlasmaComponents.CheckBox {
                    id: showTrackSplash
                    text: "Show Track Splash"
                    Layout.topMargin: 10
                }
                PlasmaComponents.CheckBox {
                    id: showVolSlider
                    text: "Show Volume Slider"
                }
                PlasmaComponents.CheckBox {
                    id: animateTrackSplash
                    text: "Animate Track Splash"
                }
                PlasmaComponents.CheckBox {
                    id: abbrevZoneView
                    text: "Abbreviated Zone View"
                }
                PlasmaComponents.CheckBox {
                    id: abbrevTrackView
                    text: "Abbreviated Track View"
                }
            }
        }
    }
}
