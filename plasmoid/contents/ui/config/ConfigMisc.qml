import QtQuick 2.8
import QtQuick.Controls 1.3
import QtQuick.Layouts 1.3
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import ".."
import '../models'
import '../controls'

ColumnLayout {

    anchors.fill: parent

    property alias cfg_updateInterval: updateIntervalSpinBox.value
    property alias cfg_hostList: hosts.items
    property bool cfg_configChange

    function getServerInfo(host) {
        reader.currentHost = host.indexOf(':') === -1
                ? host + ':' + plasmoid.configuration.defaultPort
                : host
        info.clear()
        mprisButton.visible = false
        info.append({ key: reader.currentHost, value: '--not found--'})
        reader.loadKVModel('Alive', info, function(cnt)
        {
            if (cnt > 1) {
                info.get(0).value = 'connected!'
                mprisButton.visible =
                        info.findIndex(function(item) { return item.key === 'accesskey' }) !== -1
            }
        })
    }

    Reader { id: reader }

    RowLayout {
        PlasmaComponents.Label {
            text: i18n('MCWS Host:')
            Layout.alignment: Qt.AlignRight
        }
        PlasmaComponents.TextField {
            id: mcwshost
            placeholderText: 'host:port'
            clearButtonShown: true
            Layout.fillWidth: true
            onTextChanged: {
                if (text === '') {
                    info.clear()
                    mprisButton.visible = false
                }
            }
        }
        PlasmaComponents.ToolButton {
            iconName: 'search'
            onClicked: getServerInfo(mcwshost.text)
        }

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
    }

    ListView {
        model: BaseListModel { id: info }
        Layout.preferredHeight: parent.height * .3
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
        }
    }

    RowLayout {
        Button {
            iconName: 'server-database'
            text: 'Add Host'
            visible: info.count > 1
            onClicked: hosts.addItem(reader.currentHost)
        }
        Button {
            id: mprisButton
            visible: false
            iconName: 'mediacontrol'
            text: 'Reset MPRIS2'
            onClicked: {
                var ndx = info.findIndex(function(item) { return item.key === 'accesskey' })
                if (ndx === -1)
                    return

                // first, get configs for other hosts, if any
                var host = reader.currentHost
                var cfgArr = []
                if (plasmoid.configuration.mprisConfig !== '') {
                    cfgArr = JSON.parse(plasmoid.configuration.mprisConfig).filter(function(cfg) {
                        return cfg.host !== host })
                }
                // add a cfg for this host
                cfgArr.push({ host: host, accessKey: info.get(ndx).value, zones: '*', enabled: false })
                // save cfg
                plasmoid.configuration.mprisConfig = JSON.stringify(cfgArr)
            }
        }
    }

    RowLayout {
        Layout.topMargin: 10
        PlasmaExtras.Heading {
            text: 'Current MCWS Hosts'
            level: 4
        }
        Rectangle {
            color: theme.highlightColor
            Layout.fillWidth: true
            height: 1
        }
    }

    ConfigList {
        id: hosts
        configKey: 'hostList'
        placeHolder: "Host:Port"
        showInputField: false
        Layout.maximumHeight: parent.height * .4

        onItemClicked: {
            mcwshost.text = item
            getServerInfo(item)
        }
        onConfigChanged: cfg_configChange = !cfg_configChange
    }

    Version {
        anchors {
            bottom: parent.bottom
            right: parent.right
        }
    }

}
