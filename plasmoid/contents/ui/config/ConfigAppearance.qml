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
    property alias cfg_highQualityThumbs: highQualityThumbs.checked

    property alias cfg_trayViewSize: compactSize.value
    property alias cfg_useZoneCount: useZoneCount.checked

    ColumnLayout {

        GroupBox {
            label: PlasmaComponents.CheckBox {
                id: advTrayView
                text: "Advanced Panel View (only in horizontal panels)"
            }
            Layout.fillWidth: true

            ColumnLayout {

                PlasmaComponents.CheckBox {
                    id: useZoneCount
                    text: "Size to Number of Zones"
                }
                RowLayout {
                    visible: !useZoneCount.checked
                    PlasmaComponents.Label {
                        text: 'Absolute Size'
                    }

                    PlasmaComponents.Slider {
                        id: compactSize
                        Layout.fillWidth: true
                        stepSize: 1
                        minimumValue: 25
                        maximumValue: 200
                    }
                }
                PlasmaComponents.CheckBox {
                    id: dropShadows
                    text: "Drop Shadows"
                    Layout.topMargin: 15
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
        PlasmaComponents.CheckBox {
            id: highQualityThumbs
            text: "Use High Quality Thumbnails"
            Layout.topMargin: 10
        }
    }
}
