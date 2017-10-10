import QtQuick 2.2
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.0

Item {

    property alias cfg_listTextColor: listTextColorChoice.chosenColor
    property alias cfg_highlightColor: highlightColorChoice.chosenColor
    property alias cfg_showTrackSlider: showTrackSlider.checked
    property alias cfg_showVolumeSlider: showVolSlider.checked
    property alias cfg_showTrackSplash: showTrackSplash.checked
    property alias cfg_animateTrackSplash: animateTrackSplash.checked
    property alias cfg_abbrevZoneView: abbrevZoneView.checked

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

            Label{Layout.columnSpan: 2}
            CheckBox {
                id: abbrevZoneView
                text: "Abbreviated Zone View"
                Layout.columnSpan: 2
            }


            Label{Layout.columnSpan: 2}
            Label {
                text: i18n("List Text:")
                Layout.alignment: Qt.AlignRight
            }
            ColorChoice { id: listTextColorChoice }

            Label {
                text: i18n("List Highlight:")
                Layout.alignment: Qt.AlignRight
            }
            ColorChoice { id: highlightColorChoice }

        }
    }
}
