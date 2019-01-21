import QtQuick 2.8
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

Item {

    property alias cfg_showTrackSlider: showTrackSlider.checked
    property alias cfg_showVolumeSlider: showVolSlider.checked
    property alias cfg_showTrackSplash: showTrackSplash.checked
    property alias cfg_animateTrackSplash: animateTrackSplash.checked
    property alias cfg_abbrevZoneView: abbrevZoneView.checked
    property alias cfg_abbrevTrackView: abbrevTrackView.checked
    property alias cfg_advancedTrayView: advTrayView.checked
    property alias cfg_showStopButton: showStopButton.checked
    property alias cfg_hideControls: hideControls.checked
    property alias cfg_useImageIndicator: imgIndicator.checked
    property alias cfg_dropShadows: dropShadows.checked
    property alias cfg_thumbSize: thumbSize.value
    property alias cfg_rightJustify: rightJustify.checked
    property alias cfg_scrollTrack: scrollTrack.checked

    property alias cfg_trayViewSize: compactSize.value
    property alias cfg_useZoneCount: useZoneCount.checked

    ColumnLayout {

        spacing: 10
        GroupBox {
            label: Switch {
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

                CheckBox {
                    id: useZoneCount
                    text: "Size to Number of Zones"
                }
                RowLayout {
                    visible: !useZoneCount.checked
                    Label {
                        text: 'Absolute Size'
                    }

                    Slider {
                        id: compactSize
                        Layout.fillWidth: true
                        from: 15
                        to: 60
                    }
                }

                GridLayout {
                    columns: 2
                    Layout.topMargin: units.smallSpacing

                    CheckBox {
                        id: dropShadows
                        text: "Drop Shadows"
                    }
                    CheckBox {
                        id: imgIndicator
                        text: "Use Image as Playback Indicator"
                    }
                    CheckBox {
                        id: showStopButton
                        text: "Show Stop Button"
                    }
                    CheckBox {
                        id: hideControls
                        text: "Hide Controls"
                    }
                    Rectangle {
                        height: 1
                        Layout.margins: units.smallSpacing
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        color: theme.highlightColor
                    }
                    CheckBox {
                        id: rightJustify
                        text: "Always right justify panel"
                    }
                    CheckBox {
                        id: scrollTrack
                        text: "Scroll Long Track Names"
                    }
                }

            }
        }
        GroupBox {
            Layout.fillWidth: true
            background: Rectangle {
                      color: "transparent"
                      border.color: theme.highlightColor
                      radius: 2
            }
            GridLayout {
                columns: 2

                Label {
                    text: 'Thumbnail Size'
                    Layout.alignment: Qt.AlignRight
                }

                Slider {
                    id: thumbSize
                    Layout.fillWidth: true
                    from: 32
                    to: 128
                }

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
                    enabled: showTrackSplash.checked
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
            }
        }
    }
}
