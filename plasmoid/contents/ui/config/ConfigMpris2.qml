import QtQuick 2.8
import QtQuick.Layouts 1.3
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.core 2.0 as PlasmaCore

Item {
    property alias cfg_mprisConfig: lm.outputStr

    // obj def: {host, accessKey, zones, enabled}
    ConfigListModel {
        id: lm
        configKey: 'mprisConfig'
    }

    ColumnLayout {

        width: parent.width
        height: parent.height

        PlasmaComponents.Label {
            text: 'MCWSMpris2 lib is not available.  MPRIS2 will be disabled.'
            color: theme.negativeTextColor
            visible: plasmoid.file("", "libs/mcwsmpris2") === ''
        }

        RowLayout {
            PlasmaComponents.TextField {
                id: newField
                clearButtonShown: true
                placeholderText: 'host;accesskey;zone index list ("0,1" - * = all zones)'
                Layout.fillWidth: true
                Layout.topMargin: 15
            }

            PlasmaComponents.ToolButton {
                enabled: newField.text !== ''
                iconName: 'list-add'
                onClicked: {
                    var sl = newField.text.split(';')
                    if (lm.items.findIndex(function(item) { return item.host === sl[0] }) === -1)
                        lm.items.append({ host: sl[0], accessKey: sl[1], zones: sl[2], enabled: false })
                }
            }
        }
        ListView {
            model: lm.items
            Layout.fillHeight: true
            Layout.fillWidth: true
            spacing: 5
            clip: true

            delegate: RowLayout {
                width: parent.width

                PlasmaCore.IconItem {
                    source: 'server-database'
                    usesPlasmaTheme: true
                }
                PlasmaComponents.Label {
                    text: '%1: %2 -- Zones: [%3]'.arg(host).arg(accessKey).arg(zones)
                    Layout.fillWidth: true
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            newField.text = host + ';' + accessKey + ';' + zones
                        }
                    }
                }
                PlasmaComponents.CheckBox {
                    text: 'Enable'
                    checked: model.enabled
                    onClicked: lm.setEnabled(index, checked)
                }

                PlasmaComponents.ToolButton {
                    iconName: 'list-remove'
                    onClicked: {
                        lm.items.remove(index)
                    }
                }
            }
        }

    }
}
