import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2
import org.kde.kirigami 2.4 as Kirigami

ColumnLayout {

    property alias cfg_autoShuffle: autoShuffle.checked
    property alias cfg_forceDisplayView: forceDisplayView.checked
    property alias cfg_shuffleSearch: shuffleSearch.checked
    property alias cfg_showPlayingTrack: showPlayingTrack.checked
    property alias cfg_allowDebug: allowDebug.checked

    GroupBox {
        label: Kirigami.Heading {
            level: 3
            text: 'Audio'
        }
        Layout.fillWidth: true
        ColumnLayout {
            CheckBox {
                id: autoShuffle
                text: "Shuffle when Adding or Playing"
            }
        }
    }
    GroupBox {
        label: Kirigami.Heading {
            level: 3
            text: 'Video'
        }
        Layout.fillWidth: true
        ColumnLayout {
            CheckBox {
                id: forceDisplayView
                text: "Force Display View (Fullscreen) when playing"
            }
            Label {
                text: 'You might have to disable MC Setting:\n"Options/General/Behavior/JumpOnPlay(video)" for this work properly'
                color: theme.buttonHoverColor
                font.pointSize: theme.defaultFont.pointSize - 1
            }
        }
    }
    GroupBox {
        label: Kirigami.Heading {
            level: 3
            text: 'Search'
        }
        Layout.fillWidth: true
        Layout.fillHeight: true
        ColumnLayout {
            CheckBox {
                id: shuffleSearch
                text: "Shuffle Search Results"
            }
            CheckBox {
                id: showPlayingTrack
                text: "Highlight Playing Track in Search Results (incl Playlists)"
            }
        }
    }
    CheckBox {
        id: allowDebug
        text: 'Show Debug Logging'
    }
}
