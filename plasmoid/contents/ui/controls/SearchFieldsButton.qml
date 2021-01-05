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
    property Searcher target

    Popup {
        id: fldsPopup
        focus: true
        padding: 2
        spacing: 0

        parent: Overlay.overlay

        width: Math.round(parent.width/3)
        height: parent.height

        onAboutToShow: {
            fields.model = ''
            fields.model = target.mcwsFields
        }

        ColumnLayout {
            anchors.fill: parent
            GroupSeparator{
                text: 'Select Search Fields'
            }
            Repeater {
                id: fields
                clip: true
                Layout.fillHeight: true
                Layout.fillWidth: true

                delegate: ToolButton {
                    text: field
                    Layout.fillWidth: true
                    checkable: true
                    checked: target.searchFields.hasOwnProperty(field)
                    onClicked: {
                        if (checked)
                            target.searchFields[field] = ''
                        else
                            delete target.searchFields[field]
                    }
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
