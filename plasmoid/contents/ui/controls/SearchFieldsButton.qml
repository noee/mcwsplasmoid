import QtQuick 2.8
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import org.kde.plasma.extras 2.0 as Extras
import '../models'
import '../helpers'

Item {
    implicitWidth: button.width
    implicitHeight: button.height

    // fields list source from the searcher model
    property Searcher sourceModel

    Popup {
        id: fldsPopup
        focus: true
        padding: 2
        spacing: 0

        parent: Overlay.overlay

        onAboutToShow: gv.model = searcher.searchFieldActions

        width: Math.round(parent.width/2)
        height: Math.round(parent.height/2)

        ColumnLayout {
            anchors.fill: parent
            Extras.Heading {
                text: 'Select Search Fields'
                level: 2
            }

            GroupSeparator{}
            ListView {
                id: gv
                clip: true
                Layout.fillHeight: true
                Layout.fillWidth: true

                delegate: CheckBox {
                    action: modelData
                }
            }
        }
    }

    Button {
        id: button
        icon.name: "question"
        onClicked: fldsPopup.open(button)

        hoverEnabled: true

        ToolTip.text: 'Select Search Fields'
        ToolTip.visible: hovered
        ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval

    }

}
