import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras

Item {

    property alias cfg_autoShuffle: autoShuffle.checked
    property alias cfg_forceDisplayView: forceDisplayView.checked
    property alias cfg_shuffleSearch: shuffleSearch.checked

    ColumnLayout {
        GroupBox {
            label: PlasmaExtras.Heading {
                level: 4
                text: 'Audio'
            }
            Layout.fillWidth: true
            ColumnLayout {
                PlasmaComponents.CheckBox {
                    id: autoShuffle
                    text: "Shuffle when adding or playing"
                }
                PlasmaComponents.CheckBox {
                    id: shuffleSearch
                    text: "Shuffle search results"
                }
            }
        }
        GroupBox {
            label: PlasmaExtras.Heading {
                level: 4
                text: 'Video'
            }
            Layout.fillWidth: true
            ColumnLayout {
                PlasmaComponents.CheckBox {
                    id: forceDisplayView
                    text: "Force Display View (Fullscreen) when playing"
                }
                PlasmaComponents.Label {
                    text: 'You might have to disable MC Setting:\n"Options/General/Behavior/JumpOnPlay(video)" for this work properly'
                    color: theme.buttonHoverColor
                    font.pointSize: theme.defaultFont.pointSize - 1
                }
            }
        }
    }
}
