import QtQuick 2.8
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3
import org.kde.kirigami 2.5 as Kirigami
import "../helpers"

ColumnLayout {
    property alias cfg_defaultFields: lm.outputStr

    // defn: { "field": "Name", "sortable": true, "searchable": true, "mandatory": true }
    ConfigListModel {
        id: lm
        configKey: 'defaultFields'
    }

    // NOT USED: add field
    RowLayout {
        visible: false
        TextField {
            id: newField
            placeholderText: 'MCWS Field Name'
        }

        ToolButton {
            enabled: newField.text !== ''
            icon.name: 'list-add'
            onClicked: {
                lm.items.append({ field: newField.text, sortable: false, searchable: false, mandatory: false })
            }
        }
    }

    ListView {
        id: fields
        spacing: 5
        model: lm.items
        delegate: RowLayout {
            width: parent.width * 0.75
            Kirigami.Heading {
                text: field
                level: 3
                Layout.fillWidth: true
            }
            CheckBox {
                text: 'Sortable'
                checked: sortable
                onClicked: {
                    lm.items.setProperty(index, 'sortable', checked)
                    lm.items.save()
                }
            }
            CheckBox {
                text: 'Searchable'
                checked: searchable
                onClicked: {
                    lm.items.setProperty(index, 'searchable', checked)
                    lm.items.save()
                }
            }
            ToolButton {
                visible: !mandatory
                icon.name: 'delete'
                onClicked: {
                    lm.items.remove(index)
                    lm.items.save()
                }
            }

        }
        Layout.fillHeight: true
        Layout.fillWidth: true
    }
}
