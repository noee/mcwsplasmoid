import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import org.kde.plasma.components 2.0 as PlasmaComponents

ColumnLayout {
    id: cfgList

    property var items: []
    property var list
    property alias placeHolder: txtField.placeholderText

    Component.onCompleted: load()

    signal itemClicked(var item)

    function load() {
        items.length = 0
        for(var i in list) {
            addItem( {"item": list[i]} )
        }
        txtField.forceActiveFocus()
    }

    function addItem(object) {
        lm.append(object)
        items.push(object.item)
    }

    function removeItem(index) {
        if(lm.count > 0) {
            lm.remove(index)
            items.splice(index, 1)
        }
    }

    ListModel { id: lm }

    RowLayout {
        id: layout
        Layout.fillWidth: true
        width: parent.width

        PlasmaComponents.TextField {
            id: txtField
            Layout.fillWidth: true
            onAccepted: addItem.clicked()
        }

        PlasmaComponents.ToolButton {
            id: add
            iconName: "list-add"
            enabled: txtField.text.length > 0
            onClicked: {
                addItem({'item': txtField.text})
                txtField.text = ""
                txtField.forceActiveFocus()
            }
        }
    }

    ListView {
        Layout.fillHeight: true
        Layout.fillWidth: true
        model: lm

        delegate: RowLayout {
            width: parent.width

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: item
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        txtField.text = item
                        cfgList.itemClicked(item)
                    }
                }
            }

            PlasmaComponents.ToolButton {
                iconName: "list-remove"
                onClicked: removeItem(index)
            }
        }
    }
}
