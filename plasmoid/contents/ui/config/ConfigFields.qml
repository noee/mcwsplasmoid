import QtQuick 2.8
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3
import org.kde.kirigami 2.4 as Kirigami
import '../helpers'

ColumnLayout {
    property alias cfg_defaultFields: lm.loader

    SingleShot {
        id: event
    }

    ListModel {
        id: lm

        property string loader

        function save() {
            event.queueCall(500, function() {
                var arr = []
                for (var i=0; i<count; ++i)
                    arr.push(get(i))
                loader = JSON.stringify(arr)
            })
        }

        function load() {
            var obj = JSON.parse(loader)
            obj.forEach(function(fld) {
                lm.append(fld)
            })
        }
    }

    Component.onCompleted: event.queueCall(0, lm.load)

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
                lm.append({ field: newField.text, sortable: false, searchable: false, mandatory: false })
            }
        }
    }
    ListView {
        id: fields
        spacing: 5
        model: lm
        delegate: RowLayout {
            spacing: 10
            width: parent.width
            Kirigami.Heading {
                text: field
                level: 3
                Layout.fillWidth: true
            }
            CheckBox {
                text: 'Sortable'
                checked: sortable
                onClicked: {
                    lm.setProperty(index, 'sortable', checked)
                    lm.save()
                }
            }
            CheckBox {
                text: 'Searchable'
                checked: searchable
                onClicked: {
                    lm.setProperty(index, 'searchable', checked)
                    lm.save()
                }
            }
            ToolButton {
                visible: !mandatory
                icon.name: 'list-remove'
                onClicked: {
                    lm.remove(index)
                    lm.save()
                }
            }

        }
        Layout.fillHeight: true
        Layout.fillWidth: true
    }
}
