import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.4
import org.kde.kirigami 2.4 as Kirigami

ColumnLayout {

    property bool includeZones: true
    property bool allowMove: true
    property alias hostConfig: lm.outputStr

    ConfigListModel {
        id: lm
        configKey: 'hostConfig'
        objectDef: ['host', 'accesskey', 'friendlyname', 'zones', 'enabled']
    }

    property var _alive: ({})

    function getServerInfo(host) {
        reader.currentHost = host.indexOf(':') === -1
                ? host + ':' + plasmoid.configuration.defaultPort
                : host
        info.clear()
        info.append({ key: reader.currentHost, value: '--not found--'})
        reader.loadObject('Alive', function(obj)
        {
            if (obj) {
                _alive = obj
                info.get(0).value = 'connected!'
                for (var p in _alive) {
                    info.append({key: p, value: _alive[p].toString()})
                }
            }
        })
    }

    Reader { id: reader }

    // Lookup and Alive display
    RowLayout {
        Label {
            text: i18n('Host Lookup:')
            Layout.alignment: Qt.AlignRight
        }
        TextEx {
            id: mcwshost
            placeholderText: 'host:port'
            onTextChanged: {
                if (text === '')
                    info.clear()
            }
        }
        ToolButton {
            icon.name: 'search'
            onClicked: getServerInfo(mcwshost.text)
        }
        ToolButton {
            visible: info.count > 1
            icon.name: 'list-add'
            onClicked: {
                lm.items.append({ host: reader.currentHost
                                , friendlyname: _alive.friendlyname
                                , accesskey: _alive.accesskey
                                , zones: '*'
                                , enabled: false })
            }
        }

    }
    ListView {
        model: ListModel { id: info }
        Layout.minimumHeight: parent.height * .35
        Layout.fillWidth: true
        spacing: 0
        clip: true
        delegate: RowLayout {
            Label {
                text: key
                Layout.minimumWidth: 100 * units.devicePixelRatio
            }
            Label {
                text: value
                color: info.count === 1 ? theme.negativeTextColor : theme.positiveTextColor
                Layout.fillWidth: true
            }
        }
    }

    Rectangle {
        color: theme.highlightColor
        Layout.fillWidth: true
        height: 1
    }

    // Config setup
    RowLayout {

        TextEx {
            id: newField
            placeholderText: 'host: "host:port", accessKey: "accesskey", friendlyname: "friendlyname"'
                             + (includeZones
                                ? ', zones: "0,1,.." or "*"'
                                : '')
            Layout.fillWidth: true
        }

        ToolButton {
            enabled: newField.text !== ''
            icon.name: 'list-add'
            onClicked: {
                var obj = {}
                try {
                    obj = JSON.parse(newField.text)
                }
                catch (err) {
                    var l = newField.text.replace(/ /g, '').split(',')
                    obj.host = l[0]; obj.accesskey = l[1]; obj.friendlyname = l[2]
                    if (l.length > 3)
                        obj.zones = l[3]

                }
                finally {
                    // check for port
                    if (!obj.host.includes(':'))
                        obj.host = obj.host + ':' + plasmoid.configuration.defaultPort
                    // if it's not in the list, add it
                    if (!lm.items.contains(function(i) {
                        return i.host === obj.host && i.accesskey === obj.accesskey
                    }))
                        lm.items.append(obj)
                }

            }
        }
    }
    ListView {
        model: lm.items
        Layout.fillHeight: true
        Layout.fillWidth: true
        spacing: 0
        clip: true

        delegate: RowLayout {
            width: parent.width

            CheckBox {
                checked: model.enabled
                onClicked: lm.setEnabled(index, checked)
            }

            Kirigami.BasicListItem {
                icon: 'server-database'
                text: includeZones
                        ? '%1, %2, %3, Zones: [%4]'.arg(host).arg(accesskey).arg(friendlyname).arg(zones)
                        : '%1, %2, %3'.arg(host).arg(accesskey).arg(friendlyname)
                Layout.fillWidth: true
                separatorVisible: false
                onClicked: {
                    var o = lm.items.get(index)
                    var n = {host: o.host, accesskey: o.accesskey, friendlyname: o.friendlyname}
                    if (includeZones)
                        n.zones = o.zones
                    newField.text = '%1, %2, %3'.arg(host).arg(accesskey).arg(friendlyname)
                            + (includeZones ? ', %1'.arg(zones) : '')
                    getServerInfo(host)
                }
                ToolButton {
                    icon.name: "arrow-up"
                    visible: allowMove && index !== 0
                    implicitHeight: units.iconSizes.medium
                    implicitWidth: units.iconSizes.medium
                    onClicked: lm.items.move(index, index-1, 1)
                }
                ToolButton {
                    icon.name: "arrow-down"
                    visible: allowMove && index < lm.items.count-1
                    implicitHeight: units.iconSizes.medium
                    implicitWidth: units.iconSizes.medium
                    onClicked: lm.items.move(index, index+1, 1)
                }
                ToolButton {
                    icon.name: 'delete'
                    implicitHeight: units.iconSizes.medium
                    implicitWidth: units.iconSizes.medium
                    onClicked: lm.items.remove(index)
                }
            }

        }
    }

}
