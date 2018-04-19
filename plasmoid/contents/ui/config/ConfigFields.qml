import QtQuick 2.8
import QtQuick.Layouts 1.3
import org.kde.plasma.components 2.0 as PlasmaComponents
import '../libs'

Item {
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

    ColumnLayout {
        width: parent.width
        height: parent.height

        RowLayout {
            visible: false
            PlasmaComponents.TextField {
                id: newField
                placeholderText: 'MCWS Field Name'
            }

            PlasmaComponents.ToolButton {
                enabled: newField.text !== ''
                iconName: 'list-add'
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
                PlasmaComponents.Label {
                    text: field
                    Layout.minimumWidth: 100 * units.devicePixelRatio
                }
                PlasmaComponents.CheckBox {
                    text: 'Sortable'
                    checked: sortable
                    onClicked: {
                        lm.setProperty(index, 'sortable', checked)
                        lm.save()
                    }
                }
                PlasmaComponents.CheckBox {
                    text: 'Searchable'
                    checked: searchable
                    onClicked: {
                        lm.setProperty(index, 'searchable', checked)
                        lm.save()
                    }
                }
    //            PlasmaComponents.CheckBox {
    //                text: 'Mandatory'
    //                enabled: false
    //                checked: mandatory
    //            }
                PlasmaComponents.ToolButton {
                    visible: !mandatory
                    iconName: 'list-remove'
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
}
