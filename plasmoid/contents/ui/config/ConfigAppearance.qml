import QtQuick 2.8
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import org.kde.kirigami 2.8 as Kirigami
import '../helpers'

Kirigami.FormLayout {
    id: root

    property alias cfg_showVolumeSlider: showVolSlider.checked
    property alias cfg_showTrackSplash: showTrackSplash.checked
    property alias cfg_animateTrackSplash: animateTrackSplash.checked
    property alias cfg_abbrevTrackView: abbrevTrackView.checked
    property alias cfg_advancedTrayView: advTrayView.checked
    property alias cfg_showStopButton: showStopButton.checked
    property alias cfg_hideControls: hideControls.checked
    property alias cfg_useImageIndicator: imgIndicator.checked
    property alias cfg_dropShadows: dropShadows.checked
    property alias cfg_thumbSize: thumbSize.value
    property alias cfg_highQualityThumbs: hqCoverArt.checked
    property alias cfg_rightJustify: rightJustify.checked
    property alias cfg_scrollTrack: scrollTrack.checked
    property alias cfg_bigPopup: bigPopup.checked
    property alias cfg_useTheme: useTheme.checked
    property alias cfg_themeName: theme.displayText
    property alias cfg_themeDark: themeDark.checked

    property alias cfg_trayViewSize: compactSize.value
    property alias cfg_useZoneCount: useZoneCount.checked

    Switch {
        id: advTrayView
        text: "Advanced Panel View (only in horizontal panels)"
        font.pointSize: Kirigami.Theme.defaultFont.pointSize + 3
    }

    FormSpacer {}
    ColumnLayout {
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
            columnSpacing: Kirigami.Units.largeSpacing
            rowSpacing: Kirigami.Units.largeSpacing
            Layout.topMargin: Kirigami.Units.smallSpacing

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
            CheckBox {
                id: rightJustify
                text: "Right Justify Panel"
            }
            CheckBox {
                id: scrollTrack
                text: "Scroll Long Track Names"
            }
        }

    }

    FormSpacer {}
    FormSeparator { text: 'General Display Options' }
    FormSpacer {}

    GridLayout {
        columns: 2
        columnSpacing: Kirigami.Units.largeSpacing
        rowSpacing: Kirigami.Units.largeSpacing

        CheckBox {
            id: useTheme
            text: "Use Color Scheme"
        }
        RowLayout {
            ComboBox {
                id: theme
                enabled: useTheme.checked
                textRole: 'name'
                model: JSON.parse(plasmoid.configuration.themes)
                onActivated: cfg_themeName = currentText
            }
            CheckBox {
                id: themeDark
                text: 'Dark'
                enabled: useTheme.checked
            }
        }

        FormSeparator { Layout.columnSpan: 2 }

        RowLayout {
            Label {
                text: 'Thumbnail Size'
            }
            Slider {
                id: thumbSize
                Layout.preferredWidth: Math.round(root.width /4)
                from: 32
                to: 128
            }
        }
        CheckBox {
            id: hqCoverArt
            text: 'High Quality Cover Art'
        }

        FormSeparator { Layout.columnSpan: 2 }

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
            id: abbrevTrackView
            text: "Abbreviated Track View"
        }
        CheckBox {
            id: bigPopup
            text: "Wide Popup"
        }
    }

}
