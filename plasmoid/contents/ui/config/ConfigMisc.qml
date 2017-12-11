import QtQuick 2.2
import QtQuick.Controls 1.3
import QtQuick.Layouts 1.3
import "../"
import "../../code/utils.js" as Utils

Item {

    property alias cfg_updateInterval: updateIntervalSpinBox.value
    property alias cfg_hostList: hostlist.text

    Version {
        anchors {
            bottom: parent.bottom
            right: parent.right
        }
    }
    ColumnLayout {

        GridLayout {
            Layout.fillWidth: true
            columns: 2

            Label {
                text: i18n('Host List:\n(\';\' delimited)')
                Layout.alignment: Qt.AlignRight
            }
            TextArea {
                id: hostlist
                selectByMouse: true
                implicitHeight: 60
            }

            Label {
                text: i18n('Update interval:')
                Layout.alignment: Qt.AlignRight
            }
            SpinBox {
                id: updateIntervalSpinBox
                decimals: 1
                stepSize: 0.1
                minimumValue: 0.1
                suffix: i18nc('Abbreviation for seconds', 's')
            }

            Label{Layout.columnSpan: 2}
        }

        Button {
            text: "Next Host"
            onClicked: {
                var list = hostlist.text.split(';')
                if (serverCtr === list.length)
                    serverCtr = 0
                getServerInfo(list[serverCtr++])
            }
        }

        Repeater {
            id: serverInfo
            RowLayout {
                Layout.fillWidth: true
                Label {
                    text: modelData.field
                    Layout.minimumWidth: 100 * units.devicePixelRatio
                }
                Label {
                    text: modelData.value
                }
            }
        }
    }

    property var info: []
    property int serverCtr: 0

    function getServerInfo(host) {
        reader.currentHost = host + ":52199"
        info.length = 0
        info.push({"field": "MCWS info for", "value": reader.currentHost})
        serverInfo.model = info
        reader.getResponseObject("Alive", function(data)
        {
            for(var prop in data)
                info.push({"field": prop, "value": data[prop]})
            serverInfo.model = info
        })
    }

    Component.onCompleted: {
        Qt.callLater(function() { getServerInfo(hostlist.text.split(';')[serverCtr++]) })
    }

    SingleShot {
        id: event
    }

    Reader {
        id: reader
    }
}
