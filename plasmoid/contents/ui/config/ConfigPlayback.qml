import QtQuick 2.8
import QtQuick.Controls 2.5
import org.kde.kirigami 2.8 as Kirigami
import '../helpers'

Kirigami.FormLayout {

    property alias cfg_autoShuffle: autoShuffle.checked
    property alias cfg_forceDisplayView: forceDisplayView.checked
    property alias cfg_shuffleSearch: shuffleSearch.checked
    property alias cfg_showPlayingTrack: showPlayingTrack.checked
    property alias cfg_allowDebug: allowDebug.checked

    FormSpacer {}
    FormSeparator { text: 'Audio' }
    CheckBox {
        id: autoShuffle
        text: "Shuffle when Adding or Playing"
    }

    FormSpacer {}
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

    FormSpacer {}
    FormSeparator { text: 'Search' }
    CheckBox {
        id: shuffleSearch
        text: "Shuffle Search Results"
    }

    CheckBox {
        id: showPlayingTrack
        text: "Highlight Current Track in Search Results (incl Playlists)"
    }

    FormSpacer {}
    FormSeparator { text: 'Other' }
    CheckBox {
        id: allowDebug
        text: 'Show Debug Logging'
    }
}
