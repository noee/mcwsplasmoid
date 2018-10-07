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
    property alias cfg_rightJustify: rightJustify.checked
    property alias cfg_scrollTrack: scrollTrack.checked

    property alias cfg_trayViewSize: compactSize.value
    property alias cfg_useZoneCount: useZoneCount.checked

    ColumnLayout {

        spacing: 10
        GroupBox {
            label: PlasmaComponents.CheckBox {
                id: advTrayView
                text: "Advanced Panel View (only in horizontal panels)"
            }
            Layout.fillWidth: true
            background: Rectangle {
                      color: "transparent"
                      border.color: theme.highlightColor
                      radius: 2
                      visible: advTrayView.checked
            }
            ColumnLayout {

                visible: advTrayView.checked
                enabled: advTrayView.checked

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

                GridLayout {
                    columns: 2
                    Layout.topMargin: units.smallSpacing

                    PlasmaComponents.CheckBox {
                        id: dropShadows
                        text: "Drop Shadows"
                    }
                    PlasmaComponents.CheckBox {
                        id: imgIndicator
                        text: "Use Image as Playback Indicator"
                    }
                    PlasmaComponents.CheckBox {
                        id: showStopButton
                        text: "Show Stop Button"
                        Layout.columnSpan: 2
                    }
                    Rectangle {
                        height: 1
                        Layout.margins: units.smallSpacing
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        color: theme.highlightColor
                    }
                    PlasmaComponents.CheckBox {
                        id: rightJustify
                        text: "Always right justify panel"
                    }
                    PlasmaComponents.CheckBox {
                        id: scrollTrack
                        text: "Scroll Long Track Names"
                    }
                }

            }
        }
        GroupBox {
            title: 'Popup View Options'
            Layout.fillWidth: true
            background: Rectangle {
                      color: "transparent"
                      border.color: theme.highlightColor
                      radius: 2
            }
            GridLayout {
                columns: 2

                PlasmaComponents.CheckBox {
                    id: showTrackSlider
                    text: "Show Track Slider"
                }
                PlasmaComponents.CheckBox {
                    id: showTrackSplash
                    text: "Show Track Splash"
                }
                PlasmaComponents.CheckBox {
                    id: showVolSlider
                    text: "Show Volume Slider"
                }
                PlasmaComponents.CheckBox {
                    id: animateTrackSplash
                    text: "Animate Track Splash"
                }
                Rectangle {
                    height: 1
                    Layout.margins: units.smallSpacing
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                    color: theme.highlightColor
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
