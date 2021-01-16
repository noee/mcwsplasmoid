import QtQuick 2.8
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.12
import org.kde.kirigami 2.8 as Kirigami
import "../helpers"

ColumnLayout {
    property alias cfg_defaultFields: lm.outputStr

    // defn: { "field": "Name", "sortable": true, "searchable": true, "mandatory": true }
    ConfigListModel {
        id: lm
        configKey: 'defaultFields'
    }

    function moveItem(from,to) {
        lm.items.move(from,to,1)
        fields.currentIndex = to
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
        model: lm.items
        Layout.fillHeight: true
        Layout.fillWidth: true

        delegate: Kirigami.BasicListItem {
            separatorVisible: false
            icon: 'tools'
            text: field

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
                icon.name: "arrow-up"
                enabled: index !== 0
                onClicked: moveItem(index, index-1)
            }
            ToolButton {
                icon.name: "arrow-down"
                enabled: index !== lm.items.count-1
                onClicked: moveItem(index, index+1)
            }
            ToolButton {
                enabled: !mandatory
                icon.name: mandatory ? 'folder-locked' : 'delete'
                onClicked: lm.items.remove(index)
            }
        }
    }
}
