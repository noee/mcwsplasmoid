import QtQuick 2.8
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import org.kde.kirigami 2.8 as Kirigami
import '../helpers'

Kirigami.FormLayout {

    property alias cfg_autoShuffle: autoShuffle.checked
    property alias cfg_forceDisplayView: forceDisplayView.checked
    property alias cfg_shuffleSearch: shuffleSearch.checked
    property alias cfg_showPlayingTrack: showPlayingTrack.checked
    property alias cfg_allowDebug: allowDebug.checked
    property alias cfg_showTrackSplash: showTrackSplash.checked
    property alias cfg_animateTrackSplash: animateTrackSplash.checked
    property alias cfg_fullscreenTrackSplash: fsTrackSplash.checked
    property alias cfg_splashDuration: splashDuration.value

    FormSeparator { text: 'Audio' }
    CheckBox {
        id: autoShuffle
        text: "Shuffle when Adding or Playing"
    }

    FormSeparator { text: 'Video' }
    CheckBox {
        id: forceDisplayView
        text: "Force Display View (Fullscreen) when playing"
    }
    Label {
        text: 'You might have to disable MC Setting:\n"Options/General/Behavior/JumpOnPlay(video)" for this work properly'
        color: theme.buttonHoverColor
        font.pointSize: theme.defaultFont.pointSize - 1
    }

    FormSeparator { text: 'Search' }
    CheckBox {
        id: shuffleSearch
        text: "Shuffle Search Results"
    }

    CheckBox {
        id: showPlayingTrack
        text: "Highlight Current Track in Search Results (incl Playlists)"
    }

    FormSeparator { text: 'Other' }
    GridLayout {
        columns: 2
        columnSpacing: Kirigami.Units.largeSpacing*4
        Switch {
            id: showTrackSplash
            text: "Show Track Splash"
        }

        RowLayout {
            enabled: showTrackSplash.checked
            Label {
                text: i18n('Duration:')
            }
            FloatSpinner {
                id: splashDuration
                decimals: 1
            }
        }

        CheckBox {
            id: fsTrackSplash
            enabled: showTrackSplash.checked
            text: "Fullscreen"
            onClicked: {
                if (checked)
                    animateTrackSplash.checked = false
            }
        }

        CheckBox {
            id: animateTrackSplash
            enabled: showTrackSplash.checked && !fsTrackSplash.checked
            text: "Animate"
        }

        Item {
            Layout.preferredHeight: Kirigami.Units.largeSpacing*4
            Layout.columnSpan: 2
        }
        CheckBox {
            id: allowDebug
            text: 'Show Debug Logging'
        }
    }
}
