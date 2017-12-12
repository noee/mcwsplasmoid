import QtQuick 2.8
import QtQuick.Controls 1.3
import QtQuick.Layouts 1.3
import org.kde.plasma.components 2.0 as PlasmaComponents
import "../"

ColumnLayout {

    property alias cfg_updateInterval: updateIntervalSpinBox.value
    property alias cfg_hostList: hosts.items
    property alias cfg_defaultPort: defPort.text

    function getServerInfo(host) {
        reader.currentHost = host.indexOf(':') === -1 ? host + ':' + defPort.text : host
        info.clear()
        info.append({"field": reader.currentHost, "value": '--not connected--'})
        reader.getResponseObject("Alive", function(data)
        {
            info.clear()
            info.append({"field": reader.currentHost, "value": 'connected!'})
            info.append({"field": '', "value": ''})
            for(var prop in data)
                info.append({"field": prop, "value": data[prop]})
        })
    }

    ListModel { id: info }
    Reader { id: reader }

    RowLayout {
        PlasmaComponents.Label {
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
        PlasmaComponents.Label {
            text: i18n('Default Port:')
            Layout.alignment: Qt.AlignRight
        }
        PlasmaComponents.TextField {
            id: defPort
        }

    }

    ConfigList {
        id: hosts
        list: plasmoid.configuration.hostList
        placeHolder: "Host:Port"
        Layout.alignment: Qt.AlignTop
        Layout.maximumHeight: parent.height * .4

        onItemClicked: getServerInfo(item)
    }

    Rectangle {
        color: theme.highlightColor
        Layout.fillWidth: true
        Layout.topMargin: 10
        height: 1
    }

    ListView {
        id: serverInfo
        model: info
        delegate: RowLayout {
            Layout.fillWidth: true
            PlasmaComponents.Label {
                text: field
                Layout.minimumWidth: 100 * units.devicePixelRatio
            }
            PlasmaComponents.Label {
                text: value
                color: info.count === 1 ? theme.negativeTextColor : theme.positiveTextColor
            }
        }
        Layout.fillHeight: true
        anchors.bottom: parent.bottom
    }

    Version {
        anchors {
            bottom: parent.bottom
            right: parent.right
        }
    }

}
