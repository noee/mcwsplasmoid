import QtQuick 2.2
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.0
import org.kde.plasma.components 2.0 as PlasmaComponents

Item {

    property alias cfg_showTrackSlider: showTrackSlider.checked
    property alias cfg_showVolumeSlider: showVolSlider.checked
    property alias cfg_showTrackSplash: showTrackSplash.checked
    property alias cfg_animateTrackSplash: animateTrackSplash.checked
    property alias cfg_abbrevZoneView: abbrevZoneView.checked
    property alias cfg_autoShuffle: autoShuffle.checked
    property alias cfg_advancedTrayView: advTrayView.checked

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
                height: 1
                Layout.columnSpan: 2
                Layout.fillWidth: true
            }

            Label{Layout.columnSpan: 2}

            CheckBox {
                id: advTrayView
                Layout.columnSpan: 2
                text: "Show Advanced Panel View (only in horizontal panels)"
            }
            PlasmaComponents.ButtonRow {
                Layout.columnSpan: 2
                PlasmaComponents.RadioButton {
                    id: normalSize
                    enabled: advTrayView.checked
                    text: "Normal View"
                    onClicked: cfg_trayViewSize = 25
                }
                PlasmaComponents.RadioButton {
                    id: wideSize
                    enabled: advTrayView.checked
                    text: "Wide View"
                    onClicked: cfg_trayViewSize = 60
                }
                PlasmaComponents.RadioButton {
                    id: extraWideSize
                    enabled: advTrayView.checked
                    text: "Ludicrous Wide View"
                    onClicked: cfg_trayViewSize = 110
                }
            }
            Label{Layout.columnSpan: 2}
            Rectangle {
                height: 1
                Layout.columnSpan: 2
                Layout.fillWidth: true
            }
            Label{Layout.columnSpan: 2}
            CheckBox {
                id: autoShuffle
                text: "Shuffle when adding or playing"
            }

        }
    }
}
