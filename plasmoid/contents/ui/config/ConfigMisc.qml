import QtQuick 2.8
import QtQuick.Controls 1.3
import QtQuick.Layouts 1.3
import org.kde.plasma.components 2.0 as PlasmaComponents
import "../"

ColumnLayout {

    property alias cfg_updateInterval: updateIntervalSpinBox.value
    property alias cfg_hostList: hosts.items
    property alias cfg_defaultPort: defPort.text
    property bool cfg_configChange

    function getServerInfo(host) {
        reader.currentHost = host.indexOf(':') === -1 ? host + ':' + defPort.text : host
        info.clear()
        info.append({ key: reader.currentHost, value: '--not available--'})
        reader.loadKVModel("Alive", info, function(cnt)
        {
            info.get(0).value = 'connected!'
        })
    }

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
        configKey: 'hostList'
        placeHolder: "Host:Port"
        Layout.alignment: Qt.AlignTop
        Layout.maximumHeight: parent.height * .4

        onItemClicked: getServerInfo(item)
        onConfigChanged: cfg_configChange = !cfg_configChange
    }

    Rectangle {
        color: theme.highlightColor
        Layout.fillWidth: true
        Layout.topMargin: 10
        height: 1
    }

    ListView {
        id: serverInfo
        model: ListModel { id: info }
        delegate: RowLayout {
            Layout.fillWidth: true
            PlasmaComponents.Label {
                text: key
                Layout.minimumWidth: 100 * units.devicePixelRatio
            }
            PlasmaComponents.Label {
                text: value
                color: info.count === 1 ? theme.negativeTextColor : theme.positiveTextColor
            }
            PlasmaComponents.ToolButton {
                iconName: 'mediacontrol'
                visible: key === 'AccessKey'
                onClicked: {
                    // first, get configs for other hosts, if any
                    var cfgArr = []
                    if (plasmoid.configuration.mprisConfig !== '') {
                        cfgArr = JSON.parse(plasmoid.configuration.mprisConfig).filter(function(cfg) {
                            return cfg.host !== reader.currentHost })
                    }
                    // add a cfg for this host
                    cfgArr.push({ host: reader.currentHost, accessKey: value, zones: '*', enabled: false })
                    // save cfg
                    plasmoid.configuration.mprisConfig = JSON.stringify(cfgArr)
                }
            }
            PlasmaComponents.Label {
                text: '<-- Reset MPRIS2 for this host'
                visible: key === 'AccessKey'
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
