import QtQuick 2.15
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.15
import org.kde.kirigami 2.12 as Kirigami

ColumnLayout {

    // arr of { host, friendlyname, accesskey, zones, enabled }
    component McwsHostModel: BaseListModel {

        property bool autoLoad: true
        property bool loadEnabledOnly: true

        // Configured mcws host string
        property string configString: ''
        onConfigStringChanged: if (autoLoad) load()

        signal loadStart()
        signal loadFinish(int count)
        signal loadError(string msg)

        function load() {
            loadStart()
            clear()

            try {
                var arr = JSON.parse(configString)
                arr.forEach(item => {
                    if (!loadEnabledOnly | item.enabled) {
                        // Because friendlyname is used as displayText,
                        // make sure it's present, default to host name
                        item.friendlyname = item.friendlyname ?? item.host.split(':')[0]
                        append(item)
                    }
                })
            }
            catch (err) {
                var s = err.message + '\n' + configString
                console.warn(s)
                loadError('Host config parse error: ' + s)
            }

            loadFinish(count)
        }
    }

    property bool includeZones: true
    property bool allowMove: true
    property alias hostConfig: lm.outputStr

    property var _alive: ({})

    ConfigListModel {
        id: lm
        configKey: 'hostConfig'
        objectDef: ['host', 'accesskey', 'friendlyname', 'zones', 'enabled']
    }

    Reader {
        id: reader
        onCommandError: hostInfo.text = 'not found'
        onConnectionError: hostInfo.text = 'not found'
    }

    function getServerInfo(host) {
        if (host.length === 0) return

        reader.currentHost = host.indexOf(':') === -1
                ? host + ':' + plasmoid.configuration.defaultPort
                : host
        zoneList.clear()
        hostInfo.text = 'searching...'
        reader.loadObject('Alive', obj => {
            _alive = obj
            hostInfo.text = '%1(%2): %3, v%4'
                              .arg(obj.friendlyname)
                              .arg(obj.accesskey)
                              .arg(obj.platform)
                              .arg(obj.programversion)
            reader.loadObject('Playback/Zones', zones => {
                for (var i=0, len=zones.numberzones; i<len; ++i) {
                      zoneList.append({key: zones['zoneid' + i].toString()
                                      , value: zones['zonename'+i]
                                      , include: false})
                    }
                })
        })
    }

    // Lookup and Alive display
    RowLayout {
        Kirigami.SearchField {
            id: mcwshost
            placeholderText: 'host:port'
            autoAccept: false
            onAccepted: searchBtn.clicked()
            onTextChanged: {
                if (text.length === 0) {
                    zoneList.clear()
                    hostInfo.text = ''
                }
            }
        }
        ToolButton {
            id: searchBtn
            icon.name: 'search'
            onClicked: getServerInfo(mcwshost.text)
        }
        Label {
            id: hostInfo
        }
    }

    GroupSeparator {
        text: includeZones ? 'Select zones to include' : 'Playback Zones'
        opacity: zoneList.count > 0
        ToolButton {
            icon.name: 'checkbox'
            ToolTip {
                text: 'Update Config for ' + reader.currentHost
            }
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

    ListView {
        id: zoneView
        model: BaseListModel { id: zoneList }
        Layout.minimumHeight: parent.height * .35
        Layout.fillWidth: true
        clip: true
        delegate: RowLayout {
            width: Math.round(zoneView.width*.5)
            Kirigami.BasicListItem {
                icon: 'media-default-album'
                checkable: includeZones
                checked: include
                text: '%1 (id: %2)'.arg(value).arg(key)
                separatorVisible: false
                onClicked: model.include = checked
            }
        }
    }

    // Config setup and update
    GroupSeparator { text: 'MCWS Host Config' }

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
                ToolTip {
                    text: 'Include/Exclude the host'
                }
            }

            Kirigami.BasicListItem {
                implicitWidth: lvHosts.width - Kirigami.Units.largeSpacing*2
                icon: 'server-database'
                text: host + (includeZones ? ', Zones: [%1]'.arg(zones) : '')
                subtitle: '%1, accesskey: %2'.arg(friendlyname).arg(accesskey)
                separatorVisible: false

                onClicked: {
                    mcwshost.text = host
                    getServerInfo(host)
                }

                ToolButton {
                    icon.name: "arrow-up"
                    visible: allowMove && index > 0
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
