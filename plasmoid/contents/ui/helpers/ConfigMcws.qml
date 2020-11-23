import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.4
import org.kde.kirigami 2.8 as Kirigami

ColumnLayout {

    property bool includeZones: true
    property bool allowMove: true
    property alias hostConfig: lm.outputStr

    property var _alive: ({})

    ConfigListModel {
        id: lm
        configKey: 'hostConfig'
        objectDef: ['host', 'accesskey', 'friendlyname', 'zones', 'enabled']
    }

    Reader { id: reader }

    function getServerInfo(host) {
        reader.currentHost = host.indexOf(':') === -1
                ? host + ':' + plasmoid.configuration.defaultPort
                : host
        zoneList.clear()
        hostInfo.text = 'searching...'
        reader.loadObject('Alive', (obj) =>
        {
            if (obj) {
                _alive = obj
                hostInfo.text = '%1(%2): %3, v%4'.arg(obj.friendlyname)
                                  .arg(obj.accesskey).arg(obj.platform).arg(obj.programversion)
                reader.loadObject('Playback/Zones', (zones) =>
                                  {
                                      for (var i=0, len=zones.numberzones; i<len; ++i) {

                                          zoneList.append({key: zones['zoneid' + i].toString()
                                                          , value: zones['zonename'+i]
                                                          , include: true})
                                      }
                                  })
            }
        })
    }

    // Lookup and Alive display
    RowLayout {
        Kirigami.SearchField {
            id: mcwshost
            placeholderText: 'Enter host:port'
            onTextChanged: {
                if (text === '') {
                    zoneList.clear()
                    hostInfo.text = ''
                }
            }
        }
        ToolButton {
            icon.name: 'search'
            onClicked: getServerInfo(mcwshost.text)
        }
        Label {
            id: hostInfo
        }
    }

    RowLayout {
        GroupSeparator {
            text: includeZones ? 'Select zones to include' : 'Playback Zones'
            opacity: zoneList.count > 0

            Button {
                text: 'Update ' + reader.currentHost
                onClicked: {
                    var zonestr = ''
                    if (includeZones) {
                        var cnt = 0
                        zoneList.forEach((item, ndx) => {
                                         if (item.include) {
                                             zonestr += ',%1'.arg(ndx)
                                             ++cnt
                                         }
                                     })
                        if (zonestr === '')
                            return

                        if (cnt === zoneList.count)
                            zonestr = '*'
                        else
                            zonestr = zonestr.slice(1)
                    }

                    var ndx = lm.items.findIndex((item) => {
                                                     return item.host === reader.currentHost
                                                 })
                    if (ndx === -1)
                        lm.items.append({ host: reader.currentHost
                                        , friendlyname: _alive.friendlyname
                                        , accesskey: _alive.accesskey
                                        , zones: zonestr
                                        , enabled: true })
                    else
                        lm.items.set(ndx, {friendlyname: _alive.friendlyname
                                         , accesskey: _alive.accesskey
                                         , zones: zonestr})

                    lm.items.save()
                }
            }
        }
    }

    ListView {
        model: BaseListModel { id: zoneList }
        Layout.minimumHeight: parent.height * .35
        Layout.fillWidth: true
        clip: true
        delegate: RowLayout {
            CheckBox {
                checked: include
                visible: includeZones
                onCheckedChanged: zoneList.get(index).include = checked
            }
            Kirigami.BasicListItem {
                icon: 'media-default-album'
                text: '%1 (%2)'.arg(value).arg(key)
                separatorVisible: false
            }
        }
    }

    // Config setup and update
    GroupSeparator {
        text: 'MCWS Host Config'
    }

    ListView {
        id: lvHosts
        model: lm.items
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.minimumHeight: parent.height * .35
        clip: true

        delegate: RowLayout {

            CheckBox {
                checked: model.enabled
                onClicked: lm.setEnabled(index, checked)
            }

            Kirigami.BasicListItem {
                implicitWidth: lvHosts.width - Kirigami.Units.largeSpacing*2
                icon: 'server-database'
                text: ('%1, %2, %3'.arg(host).arg(accesskey).arg(friendlyname))
                        + (includeZones ? ', Zones: [%1]'.arg(zones) : '')
                separatorVisible: false

                onClicked: {
                    mcwshost.text = host
                    getServerInfo(host)
                }

                ToolButton {
                    icon.name: "arrow-up"
                    visible: allowMove && index !== 0
                    onClicked: lm.items.move(index, index-1, 1)
                }
                ToolButton {
                    icon.name: "arrow-down"
                    visible: allowMove && index < lm.items.count-1
                    onClicked: lm.items.move(index, index+1, 1)
                }
                ToolButton {
                    icon.name: 'delete'
                    onClicked: lm.items.remove(index)
                }
            }
        }
    }
}
