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

    property alias cfg_useMultiScreen: ssMultiScreen.checked
    property alias cfg_transparentPanels: ssTransparent.checked
    property alias cfg_animatePanels: ssAnimate.checked
    property alias cfg_useCoverArtBackground: ssUseCoverArt.checked

    CheckBox {
        id: autoShuffle
        text: "Shuffle when Adding or Playing"
        Kirigami.FormData.label: 'Audio:'
    }
    FormSpacer {}
    CheckBox {
        id: forceDisplayView
        text: "Force Display View (Fullscreen) when playing"
        Kirigami.FormData.label: 'Video:'
    }
    Label {
        text: 'You might have to disable MC Setting:\n"Options/General/Behavior/JumpOnPlay(video)" for this work properly'
        color: Kirigami.Theme.linkColor
        font.pointSize: Kirigami.Theme.defaultFont.pointSize - 1
    }
    FormSpacer {}

    CheckBox {
        id: shuffleSearch
        text: "Shuffle Search Results"
        Kirigami.FormData.label: 'Search:'
    }

    CheckBox {
        id: showPlayingTrack
        text: "Highlight Current Track in Search Results (incl Playlists)"
    }

    FormSeparator {}
    Switch {
        id: showTrackSplash
        text: "Enable"
        Kirigami.FormData.label: 'Track Splash:'
    }

    GridLayout {
        columnSpacing: Kirigami.Units.largeSpacing*2

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
    }

    FormSeparator {}
    Label {
        text: 'Mode (enable on popup menu)'
        Kirigami.FormData.label: 'Screensaver'
    }

    GridLayout {
        columns: 2
        columnSpacing: Kirigami.Units.largeSpacing*2

        CheckBox {
            id: ssMultiScreen
            text: 'Use Multiple Screens'
        }

        CheckBox {
            id: ssUseCoverArt
            text: 'Use Cover Art Background'
        }

        CheckBox {
            id: ssTransparent
            text: 'Transparent Panels'
        }

        CheckBox {
            id: ssAnimate
            text: 'Animate Panels'
        }

    }

    FormSeparator {}
    CheckBox {
        id: allowDebug
        text: 'Show Debug Logging'
        Kirigami.FormData.label: 'Other:'
    }

}
